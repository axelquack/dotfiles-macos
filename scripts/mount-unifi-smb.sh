#!/usr/bin/env bash
# Mount UniFi NAS SMB shares by reserved LAN IP (no mDNS).
# Inventory is gitignored: copy scripts/smb-hosts.example → scripts/smb-hosts.local
#
# Uses `open smb://…` so macOS can use Keychain / the password UI.
# No passwords and no default IPs in this public script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAP_FILE="${SMB_HOSTS_MAP:-$SCRIPT_DIR/smb-hosts.local}"
EXAMPLE="$SCRIPT_DIR/smb-hosts.example"

if [[ ! -f "$MAP_FILE" ]]; then
  echo "ERROR: missing $MAP_FILE" >&2
  echo "Copy $EXAMPLE to smb-hosts.local and fill reserved IPv4s (gitignored)." >&2
  exit 1
fi

ROWS=()
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "${line// }" || "$line" == \#* ]] && continue
  IFS='|' read -r share host user <<<"$line"
  share="${share// /}"
  host="${host// /}"
  user="${user// /}"
  if [[ -z "$share" || -z "$host" || -z "$user" ]]; then
    echo "ERROR: bad map line in $MAP_FILE" >&2
    exit 1
  fi
  ROWS+=("${share}|${host}|${user}")
done < "$MAP_FILE"

if [[ ${#ROWS[@]} -eq 0 ]]; then
  echo "ERROR: empty map $MAP_FILE" >&2
  exit 1
fi

mount_one() {
  local share="$1" host="$2" user="$3"
  local vol="/Volumes/${share}"
  if mount | grep -q "on ${vol} "; then
    echo "already mounted: ${vol}"
    return 0
  fi
  echo "mounting smb://${user}@${host}/${share}"
  open "smb://${user}@${host}/${share}"
}

cmd="${1:-mount}"
case "$cmd" in
  mount|up)
    for entry in "${ROWS[@]}"; do
      IFS='|' read -r share host user <<<"$entry"
      mount_one "$share" "$host" "$user"
    done
    sleep 2
    mount | grep smbfs || true
    ;;
  umount|unmount|down)
    for entry in "${ROWS[@]}"; do
      IFS='|' read -r share _host _user <<<"$entry"
      vol="/Volumes/${share}"
      if mount | grep -q "on ${vol} "; then
        diskutil unmount "$vol" || umount "$vol" || true
      fi
      if mount | grep -q "on ${vol}-1 "; then
        diskutil unmount "${vol}-1" || true
      fi
    done
    ;;
  status)
    mount | grep smbfs || echo "no smbfs mounts"
    ls -la /Volumes
    ;;
  *)
    echo "Usage: $0 {mount|umount|status}" >&2
    exit 2
    ;;
esac
