# Home directory layout (macOS)

This repository is **public**. This doc maps **categories** of files under `$HOME` — not a private inventory of hosts, secrets, or app accounts.

## Three roots

| Root | Role | Managed by |
|------|------|------------|
| `$HOME` | Shell, SSH, tool homes, app data | OS + apps; **some** policy files via chezmoi |
| `~/.config` (XDG) | App config that supports XDG | Apps; optional chezmoi `dot_config/` |
| `~/Developer` | Projects, scripts, caches, archives | You — **not** iCloud Desktop & Documents |

Projects and long-lived lab work live under **`~/Developer/Projects`**. Do not keep git repos under iCloud-synced Documents.

## What chezmoi owns (policy layer)

Chezmoi source uses `dot_*` → `$HOME/.*` and `dot_config/` → `~/.config/…`.

Typical **policy** kinds (examples of categories, not a private file dump):

| Kind | Examples of paths | Notes |
|------|-------------------|--------|
| Shell | `~/.zshrc`, `~/.zshenv` | Interactive secrets stay in an **unmanaged** local file |
| Git | `~/.gitconfig`, global gitignore | Identity fields from Pass templates where used |
| SSH | `~/.ssh/config` + rendered `config.local` | Host list from Pass; keys from Pass bootstrap |
| Selected XDG | e.g. prompt, updater, window manager under `~/.config/` | Only non-secret files in the public source |

**Never in the public chezmoi source (or any public git path):**

- API keys, tokens, passwords  
- Pass vault / item / share **IDs**  
- Private keys or full `ssh-ed25519 AAAA…` public key lines  
- Filled LAN IP / MAC inventories  
- Filled `pass-*-map.local` / secret env maps  

Secrets materialize via **pass-cli** and local-only files — see [secrets-pass.md](./secrets-pass.md).

## What stays in `$HOME` but is not chezmoi “policy”

| Category | Role | Action |
|----------|------|--------|
| Toolchain homes | Language version managers, package-manager state | Leave (installer-owned) |
| App / agent data | Editors, CLIs, container runtimes, local agents | Leave |
| Caches | `~/.cache`, package caches | Leave; clear occasionally if huge |
| SSH directory | Keys + config | Leave; bootstrap keys from Pass |
| Vendor symlinks into Application Support | App conventions | Leave |

Chezmoi is the wrong tool for container VMs, game clients, or large app data trees.

## Developer tree (local disk)

| Path | Role |
|------|------|
| `~/Developer/Projects/` | Git clones |
| `~/Developer/bin/` | User scripts (on PATH via local shell config) |
| `~/Developer/cache/` | Tool caches moved out of `$HOME` when useful |
| `~/Developer/_archive/` | Old backups moved out of `$HOME` |
| `~/Developer/_backups/` | Intentional dumps |

A machine-local `~/Developer/README.md` may describe that tree in more detail; it is not required in this public repo.

## Declutter rules

**Safe to archive from `$HOME` (not via chezmoi):**

- Dated shell snapshots (`*.bak*`, tool-generated backup names)  
- One-off `*.bak-YYYYMMDD` data trees  
- Stale `*.backup` files next to live config  

**Do not archive blindly:**

- Live shell rc files still in use  
- `.ssh`, active `.config`  
- Toolchain and app data you still need  

**Never** commit secrets “as backup” to public git. Use Pass and offline archives with restrictive permissions.

## SSH host aliases

Dual short name + `.local` with reserved IP `HostName` (mDNS alone fails across subnets / travel routers):

- Public policy: [ssh-hosts.md](./ssh-hosts.md)  
- Private filled inventory: gitignored `machine-ssh-hosts.md` (from `machine-ssh-hosts.md.example`)

## Related

- [secrets-pass.md](./secrets-pass.md) — Pass + chezmoi secrets flow  
- [ssh-hosts.md](./ssh-hosts.md) — SSH alias pattern  
- [haumea.md](./haumea.md) / [moon.md](./moon.md) — host habits (no LAN inventory)  
- README — chezmoi source layout (`dot_` / `dot_config/`)  
