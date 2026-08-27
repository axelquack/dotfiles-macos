# haumea — primary host notes

**Role:** daily-driver Mac · Apple Silicon · Homebrew `/opt/homebrew`  
**Audience:** public (no accounts, vault IDs, or absolute home paths)  
**Last updated:** 2026-08-09  

## Doc map (avoid duplication)

| Topic | Canonical doc |
|-------|----------------|
| App / brew / MAS parity with moon | [home-machines-apps.md](./home-machines-apps.md) |
| Secondary host quirks | [moon.md](./moon.md) |
| AeroSpace shortcuts & workspaces | [aerospace/](./aerospace/) |
| Idempotent apply (brew, chezmoi, …) | [../ansible/README.md](../ansible/README.md) |
| Shared package list | [../brewfile.home.machines](../brewfile.home.machines) |
| **Private** reinstall brief (models, serial, IPs) | `machine-haumea.md` (gitignored) — start from [../machine.md.example](../machine.md.example) |

This file only covers **haumea-specific** behaviour and pointers. Do not copy inventory tables here.
Do **not** put API keys, model defaults, or serial numbers in this public file — use local `machine-haumea.md`.

---

## Policies unique to primary

| Item | Policy |
|------|--------|
| **Syncthing** | **Never** on haumea. Moon only — [moon.md](./moon.md) + [../brewfile.moon.extra](../brewfile.moon.extra) |
| **Docker** | **OrbStack only** (no Colima) — details in [home-machines-apps.md §3](./home-machines-apps.md) |
| **Secrets** | **Proton Pass** SoT; materialize with `scripts/bootstrap-secrets-from-pass.sh` — see [secrets-pass.md](./secrets-pass.md). Local: `chezmoi.toml` IDs + generated cache files only |

---

## Shell / chezmoi (primary)

- Prefer managed `dot_zshrc` with an **idempotent** `$HOME/.opencode/bin` PATH check (installers sometimes append a hard-coded absolute path).
- Machine secrets and API keys: regenerate **`~/.zshrc.local`** from Pass (`scripts/pass-write-zshrc-local.sh`), do not hand-maintain long-term.
- Before `topgrade` or `chezmoi apply` that needs Pass templates:

```bash
pass-cli login   # GUI Terminal (Keychain)
ssh-add --apple-use-keychain ~/.ssh/id_ed25519   # your GitHub key
```

- PAT / `pass://` share-id mismatch (HTTP 422): use [../scripts/pass-cli-chezmoi.sh](../scripts/pass-cli-chezmoi.sh) as chezmoi `[protonPass] command`. Full policy table: [home-machines-apps.md §15](./home-machines-apps.md) (high level) — **no vault IDs in git**.

---

## Desktop / WM notes (primary)

- **AeroSpace:** live file `~/.config/aerospace/aerospace.toml` (from `dot_config/aerospace/aerospace.toml.tmpl`). Cheatsheet: [aerospace/SHORTCUTS.md](./aerospace/SHORTCUTS.md).
- **Terminal:** tabs in one window = one tile; new windows get separate tiles.
- **Marked 2** (optional): good for Markdown print; float in AeroSpace.
- **OpenCode desktop:** avoid ghost project paths that no longer exist; open a real folder under `~/Developer/Projects` (prefer local disk, not iCloud Desktop & Documents).
- **Grok Build TUI:** `~/.grok/config.toml` is chezmoi-managed (`dot_grok/config.toml.tmpl`). OAuth via `grok login`; MCP tokens in unmanaged `~/.grok/.env`. Do not export `XAI_API_KEY` into interactive shells.
- Obsidian Agent Client / cloud models usually **do not** need the OpenCode GUI running.

---

## Apply / health (primary)

```bash
# Preferred
cd "$(git -C ~/Developer/Projects/dotfiles-macos rev-parse --show-toplevel 2>/dev/null || chezmoi source-path)/ansible"
ansible-playbook setup-macos.yml --limit haumea --tags brew,chezmoi

# Checks
aerospace --version
command -v opencode && opencode --version
# syncthing must NOT be installed:
brew list --formula syncthing 2>/dev/null && echo "UNEXPECTED on primary" || echo "syncthing absent (ok)"
```

---

## See also

- [moon.md](./moon.md) — secondary host  
- [home-machines-apps.md](./home-machines-apps.md) — shared inventory & drift  
- [../README.md](../README.md) — setup from scratch  
