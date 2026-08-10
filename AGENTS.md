# dotfiles-macos — agent instructions (public)

**This repository is public.** Do not put LAN IPs, MACs, vault IDs, private keys, emails, or personal host inventories in commits or in this file.

## What this is

Personal **macOS** dotfiles and setup: Zsh, Starship, AeroSpace, Homebrew, chezmoi, Ansible for primary/secondary Macs. Secrets live in **Proton Pass** (`pass-cli`); chezmoi and scripts materialize them locally.

## Read order

1. This file (**do not use CLAUDE.md** — obsolete; AGENTS.md is the only agent instruction file)  
2. [`SECURITY.md`](SECURITY.md)  
3. [`README.md`](README.md)  
4. [`docs/secrets-pass.md`](docs/secrets-pass.md)  
5. Host habits (public, no inventory): [`docs/haumea.md`](docs/haumea.md), [`docs/moon.md`](docs/moon.md)  
6. Private reinstall facts: local `machine-*.md` only (gitignored; template [`machine.md.example`](machine.md.example))

## Paths

| | |
|--|--|
| Recommended projects tree | `~/Developer/Projects` (not iCloud Desktop & Documents) |
| This repo | clone path of your choice; often `~/Developer/Projects/dotfiles-macos` |
| chezmoi source | often this clone, or `~/.local/share/chezmoi` |

Avoid hard-coding absolute home paths in **committed** files.

## Secrets (critical)

| Do | Don't |
|----|--------|
| Use **pass-cli** + Pass items | Commit keys, tokens, `chezmoi.toml` vault IDs |
| Keep maps in **gitignored** `scripts/pass-*-map.local` | Embed host inventories or LAN IPs in scripts |
| Run `./scripts/check-secrets.sh` before push | Commit `~/.zshrc.local` or filled inject templates |

Bootstrap: `./scripts/bootstrap-secrets-from-pass.sh` (requires local maps + Pass login).

## Safety for agents

- Prefer **read** of public docs; write private notes only under gitignored `machine-*.md` or outside the repo.  
- Do not dump `pass-cli item list` output or key material into files that will be committed.  
- Ansible inventory may use **hostnames** (`moon.local`) — do not expand public docs with private LAN maps.  
- Grok: keep global permission mode **auto**; use session always-approve only when needed for local tool noise, not to bypass secret policy.

## Deploy

```bash
# Packages / chezmoi (after Pass + local chezmoi.toml)
cd ansible && ansible-playbook setup-macos.yml --limit haumea --tags brew,chezmoi
# secondary: --limit moon
```

## Related private projects

Sibling machine configs (orion, uranus, …) are **separate private repos**. Do not copy their inventory into this public tree. Patterns only: Pass SoT, `AGENTS.md`/`SECURITY.md`, secret scanners.

## Open / hygiene

- Before every push: `./scripts/check-secrets.sh` (and `--history` if rewriting history)  
- Keep `pass-ssh-key-map.local` / `pass-env-map.local` out of git  
