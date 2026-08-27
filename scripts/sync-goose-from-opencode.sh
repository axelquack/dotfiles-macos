#!/usr/bin/env bash
# Import OpenCode credentials into Goose (local only — never prints secrets).
#
# SuperGrok: copies xAI OAuth tokens from OpenCode auth.json into
#   ~/.config/goose/xai_oauth/tokens.json
#   Same OAuth client_id as OpenCode / Grok CLI — subscription, not XAI_API_KEY.
#
# Zen / Go / Cohere: copies API keys from OpenCode auth.json into Goose's
#   keyring JSON blob (service=goose, account=secrets) and secrets.yaml fallback.
#
# Usage:
#   ./scripts/sync-goose-from-opencode.sh
#
# Requires an existing OpenCode login (opencode /connect for zen, go, cohere, xai).
set -euo pipefail

OPENCODE_AUTH="${OPENCODE_AUTH:-$HOME/.local/share/opencode/auth.json}"
GOOSE_DIR="${GOOSE_DIR:-$HOME/.config/goose}"
GOOSE_TOKENS="$GOOSE_DIR/xai_oauth/tokens.json"
GOOSE_SECRETS="$GOOSE_DIR/secrets.yaml"

if [[ ! -f "$OPENCODE_AUTH" ]]; then
  echo "ERROR: OpenCode auth not found: $OPENCODE_AUTH" >&2
  echo "Log in with OpenCode first (/connect xai, opencode, opencode-go, cohere)." >&2
  exit 1
fi

mkdir -p "$GOOSE_DIR/xai_oauth"

python3 - "$OPENCODE_AUTH" "$GOOSE_TOKENS" "$GOOSE_SECRETS" <<'PY'
import json, os, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

oc_path, tokens_path, secrets_path = map(Path, sys.argv[1:4])
oc = json.loads(oc_path.read_text())

def api_key(name: str) -> str | None:
    block = oc.get(name)
    if isinstance(block, dict) and block.get("type") == "api":
        key = str(block.get("key") or "").strip()
        return key or None
    return None

# --- SuperGrok OAuth ---
xai = oc.get("xai")
imported_oauth = False
if isinstance(xai, dict) and xai.get("type") == "oauth":
    access = str(xai.get("access") or "").strip()
    refresh = str(xai.get("refresh") or "").strip()
    if access and refresh:
        expires_raw = xai.get("expires")
        if isinstance(expires_raw, (int, float)):
            # OpenCode stores milliseconds since epoch.
            ts = expires_raw / 1000.0 if expires_raw > 1e12 else float(expires_raw)
            expires_at = datetime.fromtimestamp(ts, tz=timezone.utc)
        else:
            expires_at = datetime.now(timezone.utc)
        payload = {
            "access_token": access,
            "refresh_token": refresh,
            "id_token": None,
            "expires_at": expires_at.isoformat().replace("+00:00", "Z"),
        }
        tokens_path.parent.mkdir(parents=True, exist_ok=True)
        tmp = tokens_path.with_suffix(".json.tmp")
        tmp.write_text(json.dumps(payload, indent=2) + "\n")
        os.replace(tmp, tokens_path)
        os.chmod(tokens_path, 0o600)
        imported_oauth = True
        print("Imported SuperGrok OAuth into Goose xai_oauth/tokens.json")

        # Refresh so a revoked token is obvious before the first Goose turn.
        # Persist rotated tokens back to OpenCode + Goose (same client_id).
        try:
            import urllib.parse
            import urllib.request
            from datetime import timedelta

            body = urllib.parse.urlencode({
                "grant_type": "refresh_token",
                "refresh_token": refresh,
                "client_id": "b1a00492-073a-47ea-816f-4c329264a828",
            }).encode()
            req = urllib.request.Request(
                "https://auth.x.ai/oauth2/token",
                data=body,
                method="POST",
                headers={
                    "Content-Type": "application/x-www-form-urlencoded",
                    "Accept": "application/json",
                },
            )
            with urllib.request.urlopen(req, timeout=20) as r:
                fresh = json.loads(r.read().decode())
            new_access = str(fresh.get("access_token") or "").strip()
            if not new_access:
                raise RuntimeError("refresh response missing access_token")
            new_refresh = str(fresh.get("refresh_token") or refresh).strip()
            exp = int(fresh.get("expires_in") or 3600)
            expires_at = datetime.now(timezone.utc) + timedelta(seconds=exp)
            payload["access_token"] = new_access
            payload["refresh_token"] = new_refresh
            payload["expires_at"] = expires_at.isoformat().replace("+00:00", "Z")
            tmp.write_text(json.dumps(payload, indent=2) + "\n")
            os.replace(tmp, tokens_path)
            os.chmod(tokens_path, 0o600)

            xai["access"] = new_access
            xai["refresh"] = new_refresh
            xai["expires"] = int(expires_at.timestamp() * 1000)
            oc["xai"] = xai
            oc_tmp = oc_path.with_suffix(".json.tmp")
            oc_tmp.write_text(json.dumps(oc, indent=2) + "\n")
            os.replace(oc_tmp, oc_path)
            os.chmod(oc_path, 0o600)
            print("Refreshed SuperGrok access token (OpenCode + Goose)")
        except Exception as exc:
            print(
                "WARN: SuperGrok refresh failed — in OpenCode run /connect xai, "
                "then re-run this script. Goose default stays xai_oauth "
                f"(subscription, not XAI_API_KEY). ({type(exc).__name__})",
                file=sys.stderr,
            )
    else:
        print("WARN: OpenCode xai oauth is missing access/refresh — skipped", file=sys.stderr)
else:
    print("WARN: OpenCode has no xai oauth credential — SuperGrok not imported", file=sys.stderr)

# --- API keys ---
secrets = {
    "OPENCODE_ZEN_API_KEY": api_key("opencode"),
    "OPENCODE_GO_API_KEY": api_key("opencode-go"),
    "OPENCODE_API_KEY": api_key("opencode-go"),  # bundled Goose opencode_go provider
    "COHERE_API_KEY": api_key("cohere"),
}
secrets = {k: v for k, v in secrets.items() if v}

def load_keyring_blob() -> dict:
    try:
        out = subprocess.check_output(
            ["security", "find-generic-password", "-s", "goose", "-a", "secrets", "-w"],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
        if not out:
            return {}
        data = json.loads(out)
        return data if isinstance(data, dict) else {}
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        return {}

if secrets:
    blob = load_keyring_blob()
    blob.update(secrets)
    payload = json.dumps(blob, separators=(",", ":"))
    # Replace the generic-password item in-place.
    subprocess.run(
        ["security", "delete-generic-password", "-s", "goose", "-a", "secrets"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    subprocess.run(
        [
            "security",
            "add-generic-password",
            "-s",
            "goose",
            "-a",
            "secrets",
            "-l",
            "goose secrets",
            "-w",
            payload,
            "-U",
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        text=True,
    )
    print(f"Stored {len(secrets)} API key(s) in Goose keyring (service=goose)")

    # File fallback (used if GOOSE_DISABLE_KEYRING is set or keyring fails).
    existing: dict = {}
    if secrets_path.exists():
        try:
            import yaml  # type: ignore

            loaded = yaml.safe_load(secrets_path.read_text()) or {}
            if isinstance(loaded, dict):
                existing = loaded
        except Exception:
            # Minimal YAML-ish parse: KEY: value
            for line in secrets_path.read_text().splitlines():
                if ":" in line and not line.strip().startswith("#"):
                    k, _, v = line.partition(":")
                    existing[k.strip()] = v.strip().strip("'\"")
    existing.update(secrets)
    lines = [f"{k}: {json.dumps(v)}" for k, v in sorted(existing.items())]
    tmp = secrets_path.with_suffix(".yaml.tmp")
    tmp.write_text("\n".join(lines) + "\n")
    os.replace(tmp, secrets_path)
    os.chmod(secrets_path, 0o600)
    print("Wrote Goose secrets.yaml fallback (mode 600)")
else:
    print("WARN: no OpenCode API keys (opencode / opencode-go / cohere) to import", file=sys.stderr)

if not imported_oauth and not secrets:
    sys.exit(1)
PY
