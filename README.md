# My macOS Dotfiles

Personal dotfiles and setup scripts for macOS, available at [github.com/axelquack/dotfiles-macos](https://github.com/axelquack/dotfiles-macos). Covers Zsh, Starship, AeroSpace, development tools, and system preferences — aimed at a productive, reproducible command-line environment.

## Overview

| Tool | Purpose | Config |
|------|---------|--------|
| Zsh | Shell | `dot_zshrc`, `dot_zshenv` |
| [Starship](https://starship.rs) | Prompt | `dot_config/starship.toml` |
| [AeroSpace](https://github.com/nikitabobko/AeroSpace) | Tiling window manager | `dot_config/aerospace/aerospace.toml.tmpl` · [shortcuts](docs/aerospace/SHORTCUTS.md) · [workspaces](docs/aerospace/WORKSPACES.md) |
| [Ansible](https://docs.ansible.com/) | Idempotent host setup | [`ansible/`](ansible/) (haumea local · moon over SSH) |
| [Atuin](https://github.com/atuinsh/atuin) | Shell history | `dot_zshrc` |
| [Homebrew](https://brew.sh) | Package manager | `brewfile.home.machines` |
| [Topgrade](https://github.com/topgrade-rs/topgrade) | Update everything | `dot_config/topgrade.toml` |
| [chezmoi](https://chezmoi.io) | Dotfile manager | `chezmoi apply` |
| [pyenv](https://github.com/pyenv/pyenv) + [uv](https://github.com/astral-sh/uv) | Python version management | `dot_zshrc` |
| [rbenv](https://github.com/rbenv/rbenv) + [ruby-build](https://github.com/rbenv/ruby-build) | Ruby version management | `dot_zshrc` |
| [fnm](https://github.com/Schniz/fnm) | Node.js version management | `dot_zshrc` |
| [rustup](https://rustup.rs) | Rust toolchain management | `dot_zshrc`, `dot_zshenv` |
| [OrbStack](https://orbstack.dev) | Docker / VM runtime | — |
| [pass-cli](https://protonpass.github.io/pass-cli/) | Proton Pass CLI — secrets for chezmoi | `chezmoi.toml` |
| [Deno](https://deno.com) | JavaScript / TypeScript runtime | — |
| [OpenCode](https://opencode.ai) | AI coding agent CLI | — |

*(Neovim/Vim config is managed in a separate repository.)*

---

## Fresh Machine Setup

### Step 1 — Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Add Homebrew to your PATH for the current session (detects architecture automatically):

```bash
eval "$($([ "$(uname -m)" = "arm64" ] && echo /opt/homebrew || echo /usr/local)/bin/brew shellenv)"
```

### Step 2 — Install chezmoi and clone dotfiles

```bash
brew install chezmoi
chezmoi init axelquack/dotfiles-macos
```

This clones the repo to `~/.local/share/chezmoi` without applying yet. No SSH keys or GitHub account required — the repo is public.

### Step 3 — Install all packages

Sign into the Mac App Store first — required for MAS apps.

**Option A — Ansible (preferred, same pattern as orion/uranus):**

```bash
brew install ansible
cd /path/to/dotfiles-macos/ansible
ansible-playbook setup-macos.yml --limit haumea --tags brew
# moon (secondary): also installs brewfile.moon.extra (Syncthing)
# ansible-playbook setup-macos.yml --limit moon --tags brew
```

**Option B — manual brew bundle:**

```bash
brew bundle --file=~/.local/share/chezmoi/brewfile.home.machines
# secondary Mac only:
# brew bundle --file=~/.local/share/chezmoi/brewfile.moon.extra
```

This also installs `pass-cli` (Proton Pass CLI), needed in the next step.

### Step 4 — Configure Proton Pass for chezmoi

Git identity (name, email) is fetched from Proton Pass at apply time. This file is **never committed** — it stays on your machine only.

**4a — Log in to Proton Pass:**
```bash
pass-cli login
```

**4b — Create a "Git Identity" login item in your Personal vault** with:
- Username: your full name
- Email: your git email

**4c — Get the vault and item IDs:**
```bash
pass-cli vault list          # copy your Personal vault ID
pass-cli item list Personal  # find your Git Identity item ID
```

**4d — Create the local chezmoi config:**
```bash
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml << 'EOF'
sourceDir = "~/.local/share/chezmoi"

[protonPass]
    command = "pass-cli"

[data]
    proton_vault_id         = "YOUR_VAULT_ID"
    proton_git_item_id      = "YOUR_ITEM_ID"
    proton_ssh_host_item_id = "YOUR_SSH_HOST_ITEM_ID"
EOF
```

Get `proton_ssh_host_item_id` by looking up the **"SSH Host Config"** note in your Personal vault:
```bash
pass-cli item list Personal | grep "SSH Host Config"
```

### Step 5 — Apply dotfiles

```bash
# manual
chezmoi apply

# or Ansible (from this repo)
cd ansible && ansible-playbook setup-macos.yml --limit haumea --tags chezmoi
```

This applies all managed dotfiles (including `~/.gitconfig` and `~/.ssh/config.local` rendered with data from Proton Pass) to your home directory.

### Step 6 — Apply macOS system settings

```bash
# manual
sudo ./macOS.sh

# or Ansible
cd ansible && ansible-playbook setup-macos.yml --limit haumea --tags macos_defaults --ask-become-pass
```

Some changes (e.g. Dock, Finder) take effect after logout/restart.

### Step 7 — Install npm tools

```bash
./scripts/install-npm-acp-agents.sh
./scripts/install-npm-cli-tools.sh

# or: ansible-playbook setup-macos.yml --limit haumea --tags npm
```

### Step 8 — Restart terminal

Open a new terminal window for all PATH changes and tool initializations to take effect.

---

## Existing Machine

### Sync dotfiles after pulling changes

```bash
chezmoi diff        # Preview what would change
chezmoi apply       # Apply source → home directory
```

### Update packages after brewfile changes

```bash
brew bundle --file=$(chezmoi source-path)/brewfile.home.machines
```

### Re-apply macOS settings after changes

```bash
$(chezmoi source-path)/macOS.sh
```

### Day-to-day chezmoi commands

| Task | Command |
|------|---------|
| Preview changes | `chezmoi diff` |
| Apply source to live | `chezmoi apply` |
| Pull a live edit back to source | `chezmoi re-add ~/.zshrc` |
| Open the source directory | `chezmoi cd` |
| List managed files | `chezmoi managed` |

---

## Documentation

| File | Description |
|------|-------------|
| [Ansible setup](ansible/README.md) | Idempotent brew + chezmoi + optional macOS defaults / npm |
| [Home machines apps](docs/home-machines-apps.md) | Primary vs secondary app policy (public, privacy-neutral) |
| [Primary host notes](haumea.md) | Shell / topgrade / OpenCode notes |
| [AeroSpace Shortcuts](docs/aerospace/SHORTCUTS.md) | All keybindings for focus, move, layout, resize and workspaces |
| [AeroSpace Workspaces](docs/aerospace/WORKSPACES.md) | App-to-workspace assignments and float rules |

---

## Repository Contents

### Dotfiles (managed by chezmoi)

Files prefixed with `dot_` map to dotfiles in `~/`. Files in `dot_config/` map to `~/.config/`.

| File in repo | Deploys to | Purpose |
|---|---|---|
| `dot_zshrc` | `~/.zshrc` | Interactive Zsh config: PATH, version managers, aliases; sources `~/.zshrc.local` if present |
| *(not managed)* | `~/.zshrc.local` | Machine-local secrets and overrides (API keys, Grok env) — create per machine, never commit |
| `dot_zshenv` | `~/.zshenv` | All-session env vars: `$EDITOR`, `$PAGER`, Cargo |
| `dot_gitconfig.tmpl` | `~/.gitconfig` | Git identity and global settings (chezmoi template) |
| `dot_gitignore_global` | `~/.gitignore_global` | Global gitignore for all repos |
| `dot_gemrc` | `~/.gemrc` | RubyGems config (disables doc install) |
| `dot_wgetrc` | `~/.wgetrc` | wget defaults |
| `dot_config/starship.toml` | `~/.config/starship.toml` | Starship prompt config |
| `dot_config/topgrade.toml` | `~/.config/topgrade.toml` | Topgrade updater config |
| `dot_config/aerospace/aerospace.toml.tmpl` | `~/.config/aerospace/aerospace.toml` | AeroSpace WM (chezmoi template; homeDir for helper scripts) |
| `private_dot_ssh/config` | `~/.ssh/config` | SSH base config: OrbStack include, GitHub host entry |
| `private_dot_ssh/config.local.tmpl` | `~/.ssh/config.local` | Machine-specific SSH host entries — populated from Proton Pass at apply time, never committed |

### Setup scripts & packages

| Path | Purpose |
|------|---------|
| `ansible/setup-macos.yml` | Idempotent setup (brew, chezmoi, optional defaults/npm) |
| `macOS.sh` | Applies macOS system preferences via `defaults write` |
| `scripts/install-npm-acp-agents.sh` | ACP agent servers for [Obsidian Agent Client](https://rait-09.github.io/obsidian-agent-client/agent-setup/) |
| `scripts/install-npm-cli-tools.sh` | Standalone AI CLI tools (`gemini-cli` and ACP agents — pinned versions) |
| `scripts/audit-security.sh` | Security audit: `shellcheck` + OSV.dev for pinned npm packages |
| `scripts/pass-cli-chezmoi.sh` | Proton Pass wrapper for chezmoi when PAT share IDs differ |
| `brewfile.home.machines` | Shared Homebrew casks, formulae, and MAS apps |
| `brewfile.moon.extra` | Secondary host only (Syncthing) |

---

## Updating

Run `topgrade` regularly — it updates Homebrew formulae and casks, MAS apps, macOS system updates, rustup toolchain, Claude Code, and GitHub CLI extensions. A security audit runs automatically at the end via `scripts/audit-security.sh`.

The following are intentionally excluded from topgrade (see `dot_config/topgrade.toml`):

| Excluded | Reason | How to update manually |
|----------|--------|------------------------|
| `node` (npm global) | Prevents silent unpinning of versioned packages | Edit version in install scripts → run `scripts/audit-security.sh` → re-run install script |
| `yarn` / `pnpm` | No global packages; globals use npm + pinned install scripts (same policy as `node`) | N/A — install project deps with yarn/pnpm in the project; do not use global yarn/pnpm |
| `containers` | Dockerfile-based stacks need rebuild; pulling images without restarting containers gives false confidence | `docker-compose build --pull && docker-compose up -d` (hermes-stack) · `docker-compose pull && docker-compose up -d` (mcp-stack) |
| `uv` | Managed by Homebrew; `uv self update` fails for brew-managed installs | Updated automatically via Homebrew step |

**Before `topgrade`:** run `pass-cli login` in an interactive terminal (chezmoi templates need Proton Pass), and ensure your GitHub SSH key is loaded (`ssh-add --apple-use-keychain ~/.ssh/id_ed25519  # your GitHub key`) so `chezmoi update` does not hang on a passphrase prompt and hit a broken pipe.

**Avoid chezmoi “has changed since last wrote” prompts:**
- Put secrets and host-only shell config in `~/.zshrc.local` (sourced by `~/.zshrc`), not in the managed `~/.zshrc`.
- Keep machine SSH hosts in the Proton Pass **"SSH Host Config"** note (source of truth for `~/.ssh/config.local`). Edit the note, then `chezmoi apply` — do not hand-edit `config.local` long-term.

Language runtimes managed by version managers are updated manually:

```bash
pyenv install 3.x.y
rbenv install 3.x.x
fnm install --lts
```

---

## Manual Installs

The following require manual download/installation outside of Homebrew or the App Store:

- **AutoMounter Helper** — install from AutoMounter app preferences after installing the MAS app
- **Parallels Desktop** — parallels.com/download (brew cask fails on Intel due to inittool preinitialization error)
- **ATEM Software Control** — Blackmagic Design website
- **Backdrop** — cindori.com/backdrop
- **8BitDo Firmware Updater** — support.8bitdo.com
- **Pocket Sync** — pocket-sync.com
- **Protect** (Ubiquiti) — ui.com/download/protect
- **Romm** — TestFlight (self-hosted ROM manager)
- **SYSTM** (Wahoo) — systmapp.com
- **DisplayLink Manager** — for docks (vendor installer)

Retired from this setup (not installed by brewfile/Ansible):

- **ZimaSpace Client** — Zima OS hardware uses separate repos (e.g. `dotfiles-zimaos`), not this Mac brewfile

---

## License

Licensed under the **Apache License 2.0**. See [LICENSE](LICENSE.md) for details.

## Feedback

Open an issue on the [GitHub repository](https://github.com/axelquack/dotfiles-macos) or contact the repository owner.
