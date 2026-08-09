# Ansible — macOS home machines

Same idea as **orion** / **uranus**: inventory + one idempotent playbook.

| Host | Role | Connection |
|------|------|------------|
| **haumea** | Primary (Apple Silicon) | `local` |
| **moon** | Secondary (Intel) | SSH `moon.local` |

## Prerequisites

- Homebrew installed on the target
- This repo checked out (chezmoi `sourceDir` or clone path = playbook parent)
- For **moon**: `ssh moon.local` works (`ssh-add` moon key if needed)
- For **chezmoi** templates: `pass-cli login` in a GUI Terminal first

## Run

```bash
cd "$(git rev-parse --show-toplevel)/ansible"   # or: cd ~/Documents/Projects/dotfiles-macos/ansible

# Primary — packages + dotfiles
ansible-playbook setup-macos.yml --limit haumea --tags brew,chezmoi

# Primary — also npm pins + audit
ansible-playbook setup-macos.yml --limit haumea --tags brew,chezmoi,npm

# Primary — system defaults (admin password)
ansible-playbook setup-macos.yml --limit haumea --tags macos_defaults --ask-become-pass

# Secondary — shared brewfile + moon extras (Syncthing)
ansible-playbook setup-macos.yml --limit moon --tags brew,chezmoi
```

Defaults (`group_vars/all.yml`):

- `run_brew: true`
- `run_chezmoi: true`
- `run_macos_defaults: false`
- `run_npm: false`

## What it does

1. **brew** — `brew bundle` with `brewfile.home.machines`; on moon also `brewfile.moon.extra` (Syncthing). Warns if Syncthing is present on haumea.
2. **chezmoi** — `chezmoi apply --source=<repo_root> --force`
3. **macos_defaults** — `macOS.sh` with become
4. **npm** — pinned install scripts + optional security audit

## Not automated (on purpose)

- First-time Homebrew install (see main README)
- Proton Pass vault IDs in `~/.config/chezmoi/chezmoi.toml` (local secrets)
- GUI login for `pass-cli` / Keychain
- Manual apps (ATEM, Backdrop, Protect, …)
