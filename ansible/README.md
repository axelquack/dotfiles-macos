# Ansible — macOS home machines

Same idea as **orion** / **uranus**: inventory + one idempotent playbook.

| Host | Role | Connection |
|------|------|------------|
| **haumea** | Primary (Apple Silicon) | `local` |
| **moon** | Secondary (Intel) | SSH host alias **`moon`** (see below) |

## Prerequisites

- Homebrew installed on the target
- This repo checked out under **`~/Developer/Projects/dotfiles-macos`** (or set chezmoi `sourceDir` to that clone)
- For **moon**: `ssh moon` works (OpenSSH config from Pass **SSH Host Config** — dual alias `moon` / `moon.local` + reserved IP `HostName`; not mDNS alone). Load key if needed: `ssh-add --apple-use-keychain ~/.ssh/id_ed25519_moon`
- For **chezmoi** templates: `pass-cli login` in a GUI Terminal first

SSH alias policy (public, no IPs): [docs/ssh-hosts.md](../docs/ssh-hosts.md).
## Run

```bash
cd "$(git rev-parse --show-toplevel)/ansible"   # or: cd ~/Developer/Projects/dotfiles-macos/ansible

# Primary — packages + dotfiles
ansible-playbook setup-macos.yml --limit haumea --tags brew,chezmoi

# Primary — also npm pins + audit
ansible-playbook setup-macos.yml --limit haumea --tags brew,chezmoi,npm

# Primary — system defaults (admin password)
ansible-playbook setup-macos.yml --limit haumea --tags macos_defaults --ask-become-pass

# Secondary — shared brewfile + moon extras (Syncthing)
ansible-playbook setup-macos.yml --limit moon --tags brew,chezmoi

# Himalaya CLI is in the brewfile; TUI + config.toml (gitignored account map)
ansible-playbook setup-macos.yml --limit haumea --tags himalaya

# Mail.app extra IMAP profile (GUI pass-cli; unsigned; never committed)
ansible-playbook setup-macos.yml --limit haumea --tags mailapp
```

Defaults (`group_vars/all.yml`):

- `run_brew: true`
- `run_chezmoi: true`
- `run_macos_defaults: false`
- `run_npm: false`
- `run_himalaya: true`
- `run_mailapp: false`

## What it does

1. **brew** — `brew bundle` with `brewfile.home.machines` (includes `himalaya` CLI); on moon also `brewfile.moon.extra` (Syncthing). Warns if Syncthing is present on haumea.
2. **chezmoi** — `chezmoi apply --source=<repo_root> --force`
3. **macos_defaults** — `macOS.sh` with become
4. **npm** — pinned install scripts + optional security audit
5. **himalaya** — cargo-install `himalaya-tui` if missing; write `~/.config/himalaya/config.toml` from gitignored `scripts/himalaya-accounts.local` (Pass **titles** only). Skips config if the map is absent.
6. **mailapp** — generate an unsigned Mail.app IMAP profile (passwords from `pass-cli` at apply time). Off by default. Install via System Settings → General → Device Management, then `rm -P` the file.

Guide: [docs/himalaya.md](../docs/himalaya.md).

## Not automated (on purpose)

- First-time Homebrew install (see main README)
- Proton Pass vault IDs in `~/.config/chezmoi/chezmoi.toml` (local secrets)
- GUI login for `pass-cli` / Keychain
- Filling `scripts/himalaya-accounts.local` (copy the example; never commit)
- Clicking **Install** on a Mail.app profile (`profiles` has no install verb)
- Manual apps (ATEM, Backdrop, Protect, …)

## Host notes

- Primary: [docs/haumea.md](../docs/haumea.md)
- Secondary: [docs/moon.md](../docs/moon.md)
- Shared inventory: [docs/home-machines-apps.md](../docs/home-machines-apps.md)
- Home layout: [docs/home-layout.md](../docs/home-layout.md)
- Main setup narrative: [README.md](../README.md)

Agents must keep this file and `inventory.ini` in sync with README when connection or tags change.
