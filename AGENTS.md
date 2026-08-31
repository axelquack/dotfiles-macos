# dotfiles-macos — agent instructions (public)

**This repository is public.** Do not put LAN IPs, MACs, vault IDs, private keys, emails, or personal host inventories in commits or in this file.

## What this is

Personal **macOS** dotfiles and setup: Zsh, Starship, AeroSpace, Homebrew, chezmoi, Ansible for primary/secondary Macs. Secrets live in **Proton Pass** (`pass-cli`); chezmoi and scripts materialize them locally.

## Read order

1. This file (**do not use CLAUDE.md** — obsolete; AGENTS.md is the only agent instruction file)  
2. [`SECURITY.md`](SECURITY.md)  
3. [`README.md`](README.md)  
4. [`docs/secrets-pass.md`](docs/secrets-pass.md)  
5. [`docs/home-layout.md`](docs/home-layout.md) · [`docs/ssh-hosts.md`](docs/ssh-hosts.md)  
6. Host habits (public, no inventory): [`docs/haumea.md`](docs/haumea.md), [`docs/moon.md`](docs/moon.md)  
7. Ansible: [`ansible/README.md`](ansible/README.md) · `ansible/inventory.ini` · `ansible/setup-macos.yml`  
8. Private reinstall facts: local `machine-*.md` only (gitignored; templates [`machine.md.example`](machine.md.example), [`machine-ssh-hosts.md.example`](machine-ssh-hosts.md.example))

## Keep docs accurate (mandatory for agents)

Whenever you change behaviour, paths, inventory aliases, brew policy, Pass/chezmoi flow, or host setup:

1. **Check** that [`README.md`](README.md) still matches reality (setup steps, doc table, scripts table, SSH/Pass wording).  
2. **Check** that **Ansible** stays aligned: [`ansible/README.md`](ansible/README.md), `inventory.ini` (e.g. moon via short SSH alias, not mDNS-only), `setup-macos.yml` tags/vars, host/group vars.  
3. **Update** those files in the **same change** (or immediately after) — do not leave “works on disk, docs lie”.  
4. **Public repo:** no LAN IPs, keys, or vault IDs in committed docs; use [ssh-hosts.md](docs/ssh-hosts.md) patterns + private `machine-ssh-hosts.md`.  
5. Before push: `./scripts/check-secrets.sh`.
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

## Pass session + SSH agent (do not abandon pass-cli)

**Proton Pass via `pass-cli` remains SoT.** Disk keys under `~/.ssh/` are a cache after bootstrap. Prefer loading the agent from Pass, not inventing a Keychain-only workflow.

### What is permanent vs not

| Piece | Persistence |
|-------|-------------|
| Keys / host config on disk (chezmoi + bootstrap) | Until reinstall or re-bootstrap |
| `pass-cli login` (Pass session + Keychain) | Until logout, reboot, or Keychain lock |
| `pass-cli ssh-agent load` (identities in `ssh-agent`) | Until agent empties (reboot / logout / agent restart) |

You do **not** need to re-run these for every `git` command in the same login session. You **do** need them again after reboot or when `ssh-add -l` shows no identities / `pass-cli vault list` fails.

### Least friction without lowering security

- **Do not** add a LaunchAgent that auto-unlocks Pass or silently loads keys at boot — that bypasses intentional GUI unlock.
- **Do** use the idempotent helper (no-op if the agent already has keys):

```bash
# GUI Terminal on the Mac (haumea / moon) after reboot or cold agent
pass-cli login                          # only if vault list fails
./scripts/ensure-ssh-agent.sh           # pass-cli ssh-agent load when empty
```

- Over **SSH**, macOS often returns Keychain `-25308`. Either load on that Mac’s **GUI Terminal** first (login shells then attach the GUI agent via `~/.zprofile` / `~/.zshrc`), or use `ssh -A` from a host that already has keys loaded.
- `scripts/topgrade-precheck.sh` soft-fails Pass Keychain over SSH and still tries to attach / load identities for brew updates.

Details: [`docs/secrets-pass.md`](docs/secrets-pass.md) · host notes [`docs/moon.md`](docs/moon.md).

## Safety for agents

- Prefer **read** of public docs; write private notes only under gitignored `machine-*.md` / `machine-ssh-hosts.md` or outside the repo.  
- Do not dump `pass-cli item list` output or key material into files that will be committed.  
- Ansible inventory uses **SSH host aliases** (e.g. `moon`) that resolve via Pass-rendered `config.local` — do not put private LAN maps in public docs.  
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
