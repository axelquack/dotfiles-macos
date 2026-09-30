# moon — secondary host notes

**Role:** secondary Mac · Intel (`x86_64`) · Homebrew `/usr/local`  
**Audience:** public (no accounts, vault IDs, LAN IPs, or personal paths)  
**Last updated:** 2026-09-30  

## Doc map (avoid duplication)

| Topic | Canonical doc |
|-------|----------------|
| App / brew / MAS parity with haumea | [home-machines-apps.md](./home-machines-apps.md) |
| Primary host quirks | [haumea.md](./haumea.md) |
| AeroSpace (if used on moon) | [aerospace/](./aerospace/) |
| Idempotent apply | [../ansible/README.md](../ansible/README.md) (`--limit moon`) |
| Himalaya + Mail.app extra IMAP | [himalaya.md](./himalaya.md) (same as primary; GUI `pass-cli` for IMAP check) |
| Moon-only packages | [../brewfile.moon.extra](../brewfile.moon.extra) |
| **Private** reinstall brief | `machine-moon.md` (gitignored; on haumea and/or moon) — [../machine.md.example](../machine.md.example) |

This file only covers **moon-specific** behaviour. Do not repeat full app tables here.
**Parallels on Intel:** manual install only (not brew) — [home-machines-apps.md §2](./home-machines-apps.md).
**Stream Deck:** shared cask + scripts; run `./scripts/streamdeck-apply.sh` on this Mac when the USB deck is here — [stream-deck.md](./stream-deck.md).
**Bartender 6:** same shared cask as primary; register the license on this Mac — [bartender.md](./bartender.md).

---

## Policies unique to secondary

| Item | Policy |
|------|--------|
| **Syncthing** | **Allowed / expected** here only. Install via `brewfile.moon.extra` (Ansible when `--limit moon`). Never “fix” primary for missing Syncthing. |
| **Docker** | **OrbStack only** (same as primary). Colima removed — see [home-machines-apps.md §3](./home-machines-apps.md) |
| **Homebrew prefix** | `/usr/local` (Intel). Scripts and Ansible detect arch automatically. |
| **Parallels** | Prefer **vendor installer** on Intel (brew cask historically flaky) — [home-machines-apps.md §2](./home-machines-apps.md) |
| **Apple Silicon–only apps** | Not required (Protect iOS-on-Mac, etc.) — inventory lists these as primary-only |
| **Intel bottles** | Homebrew **stopped shipping x86_64 bottles** (Tier 3, announced 2025-08, in effect 2026-09). `brew upgrade` / topgrade will **compile from source** unless formulae are pinned. |
| **Xcode CLT** | Sequoia 15.7 Software Update only offers **Command Line Tools 16.4** (already installed). `brew doctor` asking for **CLT 26.3** is Homebrew’s macOS 15 mapping; 26.3 is a developer.apple.com download (Apple ID), and CLT 26.5+ requires **macOS 26.2+**. Updating CLT does **not** restore bottles. |

### Intel Homebrew: no bottles (topgrade compiles)

As of Homebrew 7 / September 2026, core formulae report `bottle: false` on Intel. `brew upgrade` then builds from source (llvm, gtk, rust, node, …). That is not a broken Command Line Tools install.

**Default — pin** (what [`scripts/topgrade-precheck.sh`](../scripts/topgrade-precheck.sh) does on `x86_64` before topgrade):

```bash
brew outdated --formula
brew pin ansible atuin czkawka deno git gtk4 libssh2 llmfit node uv   # example set
brew list --pinned
# brew unpin NAME && brew upgrade --build-from-source NAME   # only if you want a compile
```

**Optional — build from source** (Tier 3 — don’t file Homebrew issues):

```bash
brew unpin NAME
brew upgrade --build-from-source NAME
```

Do **not** remove these from `brewfile.home.machines` just because Intel has no bottles — haumea (arm64) should still track them. `mistral-vibe` stays arm-gated.

### Command Line Tools on Sequoia (Intel)

| What | Reality on this host class |
|------|----------------------------|
| Installed | CLT **16.4** at `/Library/Developer/CommandLineTools` (clang 17.0.0, SDK 15.5) |
| `softwareupdate` (with the on-demand flag file) | **16.2** and **16.4** only |
| `brew doctor` | Wants **CLT 26.3** (`Library/Homebrew/os/mac/xcode.rb` maps macOS 15 → 26.3) |
| CLT 26.3 | Xcode 26.3 supports Sequoia 15.6+; Apple does not offer it via Software Update on 15.7. Download from [developer.apple.com/download/all](https://developer.apple.com/download/all/) (signed-in Apple ID), then install the dmg. Needs GUI admin. Silences `brew doctor`; does **not** stop source builds. |
| CLT 26.5 / 26.6 / 27 | `allowed-os-versions` min **26.2** / **26.6** — Tahoe or newer. Do not force-install on Sequoia. |

Do **not** `sudo rm -rf /Library/Developer/CommandLineTools` on a working 16.4 install. Reinstalling via `xcode-select --install` will put 16.4 back.

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
# On moon (GUI Terminal — after reboot or cold agent)
pass-cli login                          # only if pass-cli vault list fails
./scripts/ensure-ssh-agent.sh           # pass-cli ssh-agent load when empty (idempotent)
# Manual equivalent:
#   pass-cli ssh-agent load --vault-name Personal
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
