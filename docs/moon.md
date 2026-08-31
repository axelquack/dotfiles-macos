# moon — secondary host notes

**Role:** secondary Mac · Intel (`x86_64`) · Homebrew `/usr/local`  
**Audience:** public (no accounts, vault IDs, LAN IPs, or personal paths)  
**Last updated:** 2026-08-31  

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
| **Intel bottle lag** | Some Homebrew formulae ship **arm64 bottles only** for a while (Tier 3 on Intel). Choose **pin** (stay on last bottle/source install) or **`brew install --build-from-source`** (compile current stable). |

### Intel Homebrew: no bottle for current stable

`topgrade` / `brew upgrade` errors with `no bottle available!` on Intel when stable has empty `bottle.stable.files`. Check with `brew info --json=v2 <formula>`.

**Option A — pin** (skip upgrades until an Intel bottle exists):

```bash
brew pin atuin uv llmfit node
brew list --pinned
# brew unpin … && brew upgrade …   # when bottles appear
```

**Option B — build from source** (run current stable on Intel; Tier 3 — don’t file Homebrew issues):

```bash
brew unpin atuin uv llmfit node chezmoi   # if previously pinned
brew install --build-from-source atuin uv llmfit chezmoi
brew upgrade node                 # or --build-from-source if upgrade refuses
```

Next bump without bottles will fail again unless you re-pin or rebuild from source.

Do **not** remove these from `brewfile.home.machines` just because Intel lags — haumea (arm64) should still track them. `mistral-vibe` stays arm-gated (never had a usable Intel bottle).

---

## Catch-up (2026-08-30 → 2026-08-31)

Public summary of the secondary-host parity pass. Host names, vault IDs, and LAN details stay in private `machine-moon.md`.

| Area | What changed |
|------|----------------|
| **Topgrade precheck** | Soft-fail Pass Keychain `-25308` over SSH; attach GUI launchd SSH agent when `SSH_AUTH_SOCK` is empty; `ignore_failures = ["chezmoi"]` so brew/MAS finish over SSH |
| **Shell** | `dot_zprofile` / `dot_zshrc` reuse the GUI SSH agent socket on Darwin SSH logins |
| **Intel Homebrew** | Prefer pin **or** `--build-from-source` when bottles are missing; moon ran source builds for `atuin` / `uv` / `llmfit` / `node` / `chezmoi` |
| **Goose** | Align with primary: SuperGrok **`xai_oauth`** via `./scripts/sync-goose-from-opencode.sh` (GUI); CLI wrapper prefers Goose.app |
| **Chezmoi apply** | Pass-backed templates: run in a **GUI Terminal** on moon (`pass-cli login` if needed). SSH cannot unlock Keychain |
| **Projects** | Clone GitHub SoT stacks onto moon as needed; rsync **gitignored** locals (`.env`, small library/config) from primary when running the same OrbStack stacks — never commit those files |
| **Hygiene** | Prefer `~/Developer/Projects` only; archive broken non-git trees and untracked local-only files under `_restore-backups/` before deleting |

**Still optional / host-local:** turn off iCloud Desktop & Documents when Desktop is cleared; archive leftover non-git cruft dirs; start OrbStack services only when you need them on the secondary; publish local-only repos (no `origin`) before cloning them to moon.

---

## Shell / remote ops

- SSH from primary for admin: use the moon host entry and key (names live in **local** SSH config / Pass — not published here).
- **pass-cli / Keychain over SSH:** often cannot unlock (`-25308`). [`scripts/topgrade-precheck.sh`](../scripts/topgrade-precheck.sh) **warns and continues** on that Keychain failure (still hard-fails if Pass is truly logged out). Chezmoi template steps that need Pass may still fail later — prefer GUI Terminal on moon for a full Pass-backed apply.
- **topgrade + chezmoi:** `ignore_failures = ["chezmoi"]` in [`dot_config/topgrade.toml`](../dot_config/topgrade.toml) so SSH topgrade continues after Pass-blocked `chezmoi update`. Source repo must track `origin/master` (`git branch --set-upstream-to=origin/master master`).
- **SSH agent over SSH:** login shells may lack `SSH_AUTH_SOCK`; `~/.zprofile` / `~/.zshrc` (and the precheck) attach to the GUI launchd agent socket when it already has identities.
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
