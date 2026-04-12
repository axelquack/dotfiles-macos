# My macOS Dotfiles

Personal dotfiles and setup scripts for macOS, available at [github.com/axelquack/dotfiles-macos](https://github.com/axelquack/dotfiles-macos). Covers Zsh, Starship, AeroSpace, development tools, and system preferences — aimed at a productive, reproducible command-line environment.

## Overview

| Tool | Purpose | Config |
|------|---------|--------|
| Zsh | Shell | `dot_zshrc`, `dot_zshenv` |
| [Starship](https://starship.rs) | Prompt | `dot_config/starship.toml` |
| [AeroSpace](https://github.com/nikitabobko/AeroSpace) | Tiling window manager | `dot_config/aerospace/aerospace.toml` |
| [Atuin](https://github.com/atuinsh/atuin) | Shell history | `dot_zshrc` |
| [Homebrew](https://brew.sh) | Package manager | `brewfile.home.machines` |
| [Topgrade](https://github.com/topgrade-rs/topgrade) | Update everything | `dot_config/topgrade.toml` |
| [chezmoi](https://chezmoi.io) | Dotfile manager | `chezmoi apply` |
| pyenv + uv | Python version management | `dot_zshrc` |
| rbenv + ruby-build | Ruby version management | `dot_zshrc` |
| fnm | Node.js version management | `dot_zshrc` |
| OrbStack | Docker / VM runtime | — |

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

### Step 2 — Install chezmoi and apply dotfiles

```bash
brew install chezmoi
chezmoi init --apply axelquack/dotfiles-macos
```

This clones the repo via HTTPS to `~/.local/share/chezmoi` and applies all managed dotfiles to your home directory. No SSH keys or GitHub account required — the repo is public. Git is available at this point because the Homebrew installer triggers the Xcode CLT installation.

### Step 3 — Install all packages

```bash
brew bundle --file=~/.local/share/chezmoi/brewfile.home.machines
```

Sign into the Mac App Store first — required for MAS apps. You may be prompted for your password during installation.

### Step 4 — Apply macOS system settings

```bash
~/.local/share/chezmoi/macOS.sh
```

Requires `sudo`. Some changes (e.g. Dock, Finder) take effect after logout/restart.

### Step 5 — Install npm tools

```bash
# ACP agent servers for Obsidian Agent Client
~/.local/share/chezmoi/scripts/install-npm-acp-agents.sh

# Standalone AI CLI tools
~/.local/share/chezmoi/scripts/install-npm-cli-tools.sh
```

### Step 6 — Restart terminal

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

## Repository Contents

### Dotfiles (managed by chezmoi)

Files prefixed with `dot_` map to dotfiles in `~/`. Files in `dot_config/` map to `~/.config/`.

| File in repo | Deploys to | Purpose |
|---|---|---|
| `dot_zshrc` | `~/.zshrc` | Interactive Zsh config: PATH, version managers, aliases |
| `dot_zshenv` | `~/.zshenv` | All-session env vars: `$EDITOR`, `$PAGER`, Cargo |
| `dot_gemrc` | `~/.gemrc` | RubyGems config (disables doc install) |
| `dot_wgetrc` | `~/.wgetrc` | wget defaults |
| `dot_config/starship.toml` | `~/.config/starship.toml` | Starship prompt config |
| `dot_config/topgrade.toml` | `~/.config/topgrade.toml` | Topgrade updater config |
| `dot_config/aerospace/aerospace.toml` | `~/.config/aerospace/aerospace.toml` | AeroSpace window manager config |

### Setup scripts

| Script | Purpose |
|--------|---------|
| `macOS.sh` | Applies macOS system preferences via `defaults write` |
| `scripts/install-npm-acp-agents.sh` | ACP agent servers for [Obsidian Agent Client](https://rait-09.github.io/obsidian-agent-client/agent-setup/) |
| `scripts/install-npm-cli-tools.sh` | Standalone AI CLI tools (`claude-code`, `gemini-cli`) |
| `brewfile.home.machines` | All Homebrew casks, formulae, and MAS apps |

---

## Updating

Run `topgrade` regularly — it updates Homebrew packages, MAS apps, macOS system updates, and more, using the config in `dot_config/topgrade.toml`.

Language runtimes managed by version managers are updated manually:

```bash
pyenv install 3.x.y
rbenv install 3.x.x
fnm install --lts
```

---

## Manual Installs

The following require manual download/installation outside of Homebrew or the App Store:

- **ATEM Software Control** — Blackmagic Design website
- **Backdrop** — cindori.com/backdrop
- **Pocket Sync** — pocket-sync.com
- **ZimaSpace Client** — find.zimaspace.com

---

## License

Licensed under the **Apache License 2.0**. See [LICENSE](LICENSE.md) for details.

## Feedback

Open an issue on the [GitHub repository](https://github.com/axelquack/dotfiles-macos) or contact the repository owner.
