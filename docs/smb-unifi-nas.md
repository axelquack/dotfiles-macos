# SMB mounts — UniFi NAS (public policy)

This repository is **public**. This file describes **how** macOS mounts NAS shares — not your LAN inventory.

**Live share list:** gitignored `scripts/smb-hosts.local` (start from [`scripts/smb-hosts.example`](../scripts/smb-hosts.example))  
**Private IP inventory (this machine only):** gitignored `machine-haumea.md` / `machine-ssh-hosts.md`

Related: [ssh-hosts.md](./ssh-hosts.md) (same “reserved IPv4, not mDNS-only” rule)

---

## Rule

1. Mount by **reserved LAN IPv4**, not `*.local`.
2. Keep the IP list in **`scripts/smb-hosts.local`** (gitignored). Never commit filled IPs or usernames.
3. Let macOS store the password in **Keychain** (`open smb://…` prompts once).

```text
# scripts/smb-hosts.local  (gitignored)
# share_name|reserved_lan_ipv4|smb_user
projects|YOUR_NAS_IPV4|YOUR_SMB_USER
backups|YOUR_NAS_IPV4|YOUR_SMB_USER
romm|YOUR_ROMM_NAS_IPV4|YOUR_SMB_USER
```

Typical share *names* on this setup: `projects` and `backups` on the projects NAS, `romm` on the ROMM NAS. Add more rows locally as needed (media, TV, …).

---

## Helper script

```bash
./scripts/mount-unifi-smb.sh mount
./scripts/mount-unifi-smb.sh status
./scripts/mount-unifi-smb.sh umount
```

Override the map path with `SMB_HOSTS_MAP` if you keep inventory elsewhere.

---

## AutoMounter.app

Store servers as **IPv4** (not `*.local`) and disable Bonjour for those entries (`mountBonjour=false`). Fill hosts from the private inventory, not from this file.

---

## One-shot Finder

```bash
open "smb://YOUR_SMB_USER@YOUR_NAS_IPV4/projects"
```

---

## Stale `/Volumes/<share>` directory

If a failed mount leaves an empty `d--x--x--x /Volumes/<share>`, the real mount may appear as `/Volumes/<share>-1`. Fix:

```bash
# only if `mount` does NOT list /Volumes/<share>
sudo rmdir /Volumes/<share>
./scripts/mount-unifi-smb.sh mount
```

---

## List shares on a NAS

```bash
smbutil view //YOUR_SMB_USER@YOUR_NAS_IPV4
```

---

## NFS note

Linux/cluster VMs often use **NFS** to the same NAS; macOS day-to-day is **SMB** (this doc).
