# haumea — primary host notes

**Role:** daily-driver Mac · Apple Silicon · Homebrew `/opt/homebrew`  
**Audience:** public (no accounts, vault IDs, or absolute home paths)  
**Last updated:** 2026-10-20  

## Doc map (avoid duplication)

| Topic | Canonical doc |
|-------|----------------|
| App / brew / MAS parity with moon | [home-machines-apps.md](./home-machines-apps.md) |
| Secondary host quirks | [moon.md](./moon.md) |
| AeroSpace shortcuts & workspaces | [aerospace/](./aerospace/) |
| Idempotent apply (brew, chezmoi, himalaya, …) | [../ansible/README.md](../ansible/README.md) |
| Himalaya + Mail.app extra IMAP | [himalaya.md](./himalaya.md) |
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
| **NAS SMB** | Mount by reserved IPv4, not `*.local` — [smb-unifi-nas.md](./smb-unifi-nas.md). IPs in gitignored `scripts/smb-hosts.local` |

---

## Shell / chezmoi (primary)

- Prefer managed `dot_zshrc` with an **idempotent** `$HOME/.opencode/bin` PATH check (installers sometimes append a hard-coded absolute path).
- Machine secrets and API keys: regenerate **`~/.zshrc.local`** from Pass (`scripts/pass-write-zshrc-local.sh`), do not hand-maintain long-term.
- Before `topgrade` or `chezmoi apply` that needs Pass templates:

```bash
pass-cli login   # GUI Terminal (Keychain)
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_github
# or let topgrade's precheck load it:
#   ./scripts/topgrade-precheck.sh
```

- **pass-cli session mode:** pass-cli 2.5.0 errors when `~/Library/Application Support/proton-pass-cli/.session` is not mode `700` ("Session directory is accessible by group or others"). The topgrade precheck then says pass-cli is not logged in. On 2026-10-20 the directory was `755` (umask `022`). `chmod 700` that directory and `600` the secret files inside it (`pass-cli.db`, `passphrases.enc`, `session.json`). The precheck does not chmod this itself. Login still needs a GUI Terminal.
- **topgrade skips `hermes_agent` and `colima`.** Docker is OrbStack. `~/Developer/bin/hermes` execs into the hermes-stack container, so `hermes update` exits 1 (not a git checkout). Upgrade that image in `~/Developer/Projects/hermes-stack` with `just hermes-upgrade`. Model and auth notes stay in gitignored `machine-haumea.md` and in the hermes-stack repo.

- PAT / `pass://` share-id mismatch (HTTP 422): use [../scripts/pass-cli-chezmoi.sh](../scripts/pass-cli-chezmoi.sh) as chezmoi `[protonPass] command`. Full policy table: [home-machines-apps.md §15](./home-machines-apps.md) (high level) — **no vault IDs in git**.

---

## Desktop / WM notes (primary)

- **AeroSpace:** live file `~/.config/aerospace/aerospace.toml` (from `dot_config/aerospace/aerospace.toml.tmpl`). Cheatsheet: [aerospace/SHORTCUTS.md](./aerospace/SHORTCUTS.md).
- **Stream Deck:** cask + `~/.config/streamdeck/bin` via chezmoi; write live profiles with `./scripts/streamdeck-apply.sh` on the Mac the deck is plugged into — [stream-deck.md](./stream-deck.md).
- **Bartender 6:** shared cask `bartender`; register the license on this Mac (not git) — [bartender.md](./bartender.md).
- **Terminal:** tabs in one window = one tile; new windows get separate tiles.
- **Marked 2** (optional): good for Markdown print; float in AeroSpace.
- **OpenCode desktop:** avoid ghost project paths that no longer exist; open a real folder under `~/Developer/Projects` (prefer local disk, not iCloud Desktop & Documents).
- **Grok Build TUI:** `~/.grok/config.toml` is chezmoi-managed (`dot_grok/config.toml.tmpl`). OAuth via `grok login`; MCP tokens in unmanaged `~/.grok/.env`. Do not export `XAI_API_KEY` into interactive shells.
- **Grok Bot + Cursor (iPhone):** Grok Bot desktop **Execution on this computer** = **Always allow**; egress off. Cursor Remote Control **Connected** as **haumea**; keep-awake on; **iPhone paired** with this computer. SoT: `~/Developer/Projects/grok-bot-stack/docs/grok-bot-cursor.md` (not moon-omarchy). Do not Disconnect that iPhone, Unregister All, dump pairing codes, or `curl | bash` vendor installers.
- **Cursor Agents local repos:** each child of `~/Developer/Projects` is its own **Repositories** sidebar row (not one parent “Projects” folder). Click the repo, then New Chat — composer + Files follow that folder. Do not File → Open Folder on the parent. Do not grant Cursor GitHub **All**. SoT: `~/Developer/Projects/grok-bot-stack/docs/cursor-projects.md`.
- **MCP split:** Cursor on this Mac uses `~/.cursor/mcp.json` generated from Grok Build (`grok-bot-stack/scripts/sync-cursor-mcp.sh`). Grok Bot does **not** read that file — Connect apps / Plugins, cloud computer only. **Context7** (plugin `406`) and **Raindrop** (`npx mcp-remote` + secret `RAINDROP_TOKEN`) are connected there. SoT: `~/Developer/Projects/grok-bot-stack/docs/mcp.md`. Do not tunnel localhost MCP or enable Grok Bot desktop egress.
- **Goose Desktop:** default is SuperGrok **`xai_oauth`**. If the app shows *Configuration Error* / “configure an API provider”, re-import from OpenCode (`./scripts/sync-goose-from-opencode.sh`) then relaunch Goose — see [home-machines-apps.md §12b](./home-machines-apps.md).
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
command -v himalaya && himalaya --version
command -v himalaya-tui && himalaya-tui --version
# syncthing must NOT be installed:
brew list --formula syncthing 2>/dev/null && echo "UNEXPECTED on primary" || echo "syncthing absent (ok)"
```

---

## See also

- [moon.md](./moon.md) — secondary host  
- [home-machines-apps.md](./home-machines-apps.md) — shared inventory & drift  
- [../README.md](../README.md) — setup from scratch  
