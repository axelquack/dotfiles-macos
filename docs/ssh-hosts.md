# SSH host aliases (public policy)

This repository is **public**. This file describes **how** hosts are configured — not your LAN inventory.

**Source of truth for the live host list:** Proton Pass secure note **"SSH Host Config"**  
**Rendered to:** `~/.ssh/config.local` via chezmoi (`private_dot_ssh/config.local.tmpl`)  
**Private IP inventory (this machine only):** gitignored `machine-ssh-hosts.md` (see [machine-ssh-hosts.md.example](../machine-ssh-hosts.md.example))

Related: [secrets-pass.md](./secrets-pass.md)

---

## Rule (all fleet hosts)

Every SSH host entry should provide:

1. **Short alias** — e.g. `moon`, `mars`  
2. **mDNS-style alias** — e.g. `moon.local` (and site suffixes such as `mars.cosmic.local` when used)  
3. **`HostName`** — **reserved LAN IPv4** (DHCP reservation / static), not only a `.local` name  
4. **`User`**, **`IdentityFile`**, **`IdentitiesOnly yes`**

```sshconfig
# Pattern (placeholders only — real values live in Pass)
Host <shortname> <shortname>.local
    HostName <RESERVED_LAN_IPV4>
    User <user>
    IdentityFile ~/.ssh/id_ed25519_<label>
    IdentitiesOnly yes
```

Proxmox-style multi-suffix example:

```sshconfig
Host <node> <node>.local <node>.cosmic.local
    HostName <RESERVED_LAN_IPV4>
    User root
    IdentityFile ~/.ssh/id_ed25519_proxmox
    IdentitiesOnly yes
```

---

## Why not mDNS-only?

| Situation | mDNS (`*.local`) | `HostName` + reserved IP |
|-----------|------------------|---------------------------|
| Both machines on same home LAN | Often works | Works |
| Admin Mac on **travel router** (other subnet), target on home LAN | **Usually fails** (no L2 discovery) | Works if unicast route to home exists |
| DNS split-horizon / UniFi | Optional | Reservation is authoritative |

Unicast to the home gateway can work while `ping host.local` still fails. SSH config must not depend on mDNS alone.

---

## Edit workflow

1. Edit Pass note **"SSH Host Config"** (not long-term hand-edits to `config.local`).  
2. `pass-cli login` (GUI Terminal if needed).  
3. `chezmoi apply`  
4. Verify:

```bash
ssh -G <shortname> | egrep '^(hostname|user|identityfile) '
ssh -G <shortname>.local | egrep '^(hostname|user|identityfile) '
# both hostname lines should show the same reserved IPv4
```

5. Connectivity smoke (adjust list privately):

```bash
ssh -o ConnectTimeout=6 -o BatchMode=yes <shortname> 'hostname || cat /etc/hostname'
```

---

## Where private data lives

| Data | Public git | Private |
|------|------------|---------|
| Dual-alias **policy** | This file + secrets-pass | — |
| Real IPs, keys paths inventory, test matrix | **Forbidden** | Pass note + `machine-ssh-hosts.md` (gitignored) |
| Per-host reinstall notes | `docs/moon.md` etc. (no IPs) | `machine-<host>.md` |

---

## Related

- [secrets-pass.md](./secrets-pass.md) — Pass / chezmoi architecture  
- [moon.md](./moon.md) / [haumea.md](./haumea.md) — host habits (no LAN inventory)  
- `~/.ssh/config` (chezmoi) includes `config.local`  
