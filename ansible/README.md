# Ansible — macOS home machines

Same idea as the sibling machine books: inventory + one idempotent playbook.

| Group | Role | Connection |
|-------|------|------------|
| **primary** | Primary Mac (Apple Silicon) | `local` |
| **secondary** | Secondary Mac (Intel) | Short SSH host alias (see below) |

## Inventory (private overlay)

The real host aliases are not in git. `ansible.cfg` reads `inventory.local.ini`, which is gitignored. The tracked `inventory.ini` is a template with placeholders:

```bash
cp ansible/inventory.ini ansible/inventory.local.ini   # then fill in the real aliases
ansible-inventory --list                               # from ansible/; check the primary and secondary groups
```

Per-machine vars live in `group_vars/primary.yml` and `group_vars/secondary.yml`, so put each alias in the matching group. The commands below use the group names `primary` and `secondary`, so they work with any alias.

## Prerequisites

- Homebrew installed on the target
- This repo checked out under **`~/Developer/Projects/dotfiles-macos`** (or set chezmoi `sourceDir` to that clone)
- For the **secondary** Mac: `ssh <alias>` works (OpenSSH config from Pass **SSH Host Config** — dual alias `<alias>` / `<alias>.local` + reserved IP `HostName`; not mDNS alone). Load key if needed: `ssh-add --apple-use-keychain ~/.ssh/id_ed25519_<label>`
- For **chezmoi** templates: `pass-cli login` in a GUI Terminal first

SSH alias policy (public, no IPs): [docs/ssh-hosts.md](../docs/ssh-hosts.md).
## Run

```bash
cd "$(git rev-parse --show-toplevel)/ansible"   # or: cd ~/Developer/Projects/dotfiles-macos/ansible

# Primary — packages + dotfiles
ansible-playbook setup-macos.yml --limit primary --tags brew,chezmoi

# Primary — also npm pins + audit
ansible-playbook setup-macos.yml --limit primary --tags brew,chezmoi,npm

# Primary — system defaults (admin password)
ansible-playbook setup-macos.yml --limit primary --tags macos_defaults --ask-become-pass

# Secondary — shared brewfile + secondary extras (Syncthing)
ansible-playbook setup-macos.yml --limit secondary --tags brew,chezmoi

# Himalaya CLI is in the brewfile; TUI + config.toml (gitignored account map)
ansible-playbook setup-macos.yml --limit primary --tags himalaya

# Mail.app extra IMAP profile (GUI pass-cli; unsigned; never committed)
ansible-playbook setup-macos.yml --limit primary --tags mailapp
```

Defaults (`group_vars/all.yml`):

- `run_brew: true`
- `run_chezmoi: true`
- `run_macos_defaults: false`
- `run_npm: false`
- `run_himalaya: true`
- `run_mailapp: false`

## What it does

1. **brew** — `brew bundle` with `brewfile.home.machines` (includes `himalaya` CLI); on the secondary Mac also its extra brewfile (Syncthing). Warns if Syncthing is present on the primary.
   Terraform in the shared brewfile is `hashicorp/tap/terraform`, not the homebrew-core formula.
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
- Stream Deck live profiles (`./scripts/streamdeck-apply.sh` after brew; quits the GUI app) — [stream-deck.md](../docs/stream-deck.md)

## Host notes

- Per-Mac notes: see the index in [docs/README.md](../docs/README.md)
- Shared inventory: [docs/home-machines-apps.md](../docs/home-machines-apps.md)
- Home layout: [docs/home-layout.md](../docs/home-layout.md)
- Main setup narrative: [README.md](../README.md)

Agents must keep this file and the `inventory.ini` template in sync with README when connection or tags change.
