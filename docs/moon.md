# moon — secondary host notes

**Role:** secondary Mac · Intel (`x86_64`) · Homebrew `/usr/local`  
**Audience:** public (no accounts, vault IDs, LAN IPs, or personal paths)  
**Last updated:** 2026-08-30  

## Doc map (avoid duplication)

| Topic | Canonical doc |
|-------|----------------|
| App / brew / MAS parity with haumea | [home-machines-apps.md](./home-machines-apps.md) |
| Primary host quirks | [haumea.md](./haumea.md) |
| AeroSpace (if used on moon) | [aerospace/](./aerospace/) |
| Idempotent apply | [../ansible/README.md](../ansible/README.md) (`--limit moon`) |
| Moon-only packages | [../brewfile.moon.extra](../brewfile.moon.extra) |
| **Private** reinstall brief | `machine-moon.md` (gitignored; on haumea and/or moon) — [../machine.md.example](../machine.md.example) |

This file only covers **moon-specific** behaviour. Do not repeat full app tables here.
**Parallels on Intel:** manual install only (not brew) — [home-machines-apps.md §2](./home-machines-apps.md).

---

## Policies unique to secondary

| Item | Policy |
|------|--------|
| **Syncthing** | **Allowed / expected** here only. Install via `brewfile.moon.extra` (Ansible when `--limit moon`). Never “fix” primary for missing Syncthing. |
| **Docker** | **OrbStack only** (same as primary). Colima removed — see [home-machines-apps.md §3](./home-machines-apps.md) |
| **Homebrew prefix** | `/usr/local` (Intel). Scripts and Ansible detect arch automatically. |
| **Parallels** | Prefer **vendor installer** on Intel (brew cask historically flaky) — [home-machines-apps.md §2](./home-machines-apps.md) |
| **Apple Silicon–only apps** | Not required (Protect iOS-on-Mac, etc.) — inventory lists these as primary-only |

---

## Shell / remote ops

- SSH from primary for admin: use the moon host entry and key (names live in **local** SSH config / Pass — not published here).
- **pass-cli / Keychain over SSH:** often cannot unlock (`-25308`). [`scripts/topgrade-precheck.sh`](../scripts/topgrade-precheck.sh) **warns and continues** on that Keychain failure (still hard-fails if Pass is truly logged out). Chezmoi template steps that need Pass may still fail later — prefer GUI Terminal on moon for a full Pass-backed apply.
- Secrets: `~/.zshrc.local` + local chezmoi data only.
- **Goose:** prefer the same SuperGrok **`xai_oauth`** path as primary (`./scripts/sync-goose-from-opencode.sh` after OpenCode xAI login **on moon**). A Dock/AionUI wrapper under `~/.local/bin/goose` may still exist for PATH/env; do not treat console `XAI_API_KEY` as the long-term default — see [home-machines-apps.md §12b](./home-machines-apps.md).

```bash
# On moon (interactive GUI when possible)
pass-cli login
ssh-add --apple-use-keychain ~/.ssh/id_ed25519   # GitHub or deploy key as configured locally
```

---

## Apply / health (secondary)

```bash
# From primary (or on moon with this repo checked out)
cd /path/to/dotfiles-macos/ansible
ansible-playbook setup-macos.yml --limit moon --tags brew,chezmoi
# brew tag applies brewfile.home.machines + brewfile.moon.extra

# On moon
brew list --formula syncthing   # expected present if you use sync
brew services list | grep -i syncthing || true
```

---

## What not to put in this file

- Real email addresses, Pass item titles, vault/share IDs  
- LAN IPs or SSH private key material  
- Full duplicate of [home-machines-apps.md](./home-machines-apps.md) tables  

Keep those in a **private** notes vault if needed.

---

## See also

- [haumea.md](./haumea.md) — primary host  
- [home-machines-apps.md](./home-machines-apps.md) — shared inventory & drift  
- [../ansible/README.md](../ansible/README.md) — automation  
