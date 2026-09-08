# Stream Deck (Elgato MK.2)

15-key Stream Deck MK.2 plus Stream Deck 7.5 **MCP Deck** (virtual **8×4** XL grid), laid out for this repo’s daily loop: AeroSpace workspaces, chezmoi / Pass / git, and the Elgato camera/lights already on the desk.

**Public repo:** no device serials, LAN IPs, or secrets. Profiles are generated locally.

## What you get

| Piece | Where |
|-------|--------|
| Homebrew cask | `elgato-stream-deck` in [`brewfile.home.machines`](../brewfile.home.machines) |
| Action scripts | chezmoi `dot_config/streamdeck/bin/` → `~/.config/streamdeck/bin/*.command` |
| Profile writer | [`scripts/streamdeck_profile.py`](../scripts/streamdeck_profile.py) |
| Key icons | [`scripts/streamdeck_icon.swift`](../scripts/streamdeck_icon.swift) (Tokyo Night tiles + Elgato pack / SF Symbols / app icons) |
| Apply | [`scripts/streamdeck-apply.sh`](../scripts/streamdeck-apply.sh) |
| Grok → keys | `[mcp_servers.elgato]` in `dot_grok/config.toml.tmpl` (`npx @elgato/mcp-server`) |
| AeroSpace | Stream Deck app **floats** on the current workspace and is **centered** on that display (`com.elgato.StreamDeck` + `center-floating-window.sh`) |

Hardware is a **Stream Deck MK.2** (5×3). The Elgato app must be running for keys and for the MCP bridge.

Keys share one icon set: dark Tokyo Night tiles, accent bar, SF Pro Rounded label. Glyphs come from the Elgato Key Creator white pack (workspaces, ops, brand marks), SF Symbols, or the real macOS app icon. `streamdeck-apply.sh` compiles `streamdeck-icon` with `swiftc`; `librsvg` rasterizes pack SVGs. If either is missing, the generator falls back to the old pixel-font tiles.

## Apply (the Mac the deck is plugged into)

The desktop app keeps profiles **in memory** and overwrites `ProfilesV3` on quit. Never edit those JSON files while the app is open.

```bash
# GUI session (Keychain / Pass if you will hit Ops keys later)
chezmoi apply
./scripts/streamdeck-apply.sh          # quits the app, writes profiles, relaunches
# preview only:
./scripts/streamdeck-apply.sh --dry-run
```

Re-run apply after pulling layout/script changes. It replaces the generated **dotfiles** and **MCP Actions** profiles; it does not commit anything.

## Hardware home (15 keys)

```
WEB    CODE   TERM   COMMS  DOCS     ← AeroSpace ⌥⌘1–5
MEDIA  FILES  GAMES  DSGN   VM       ← AeroSpace ⌥⌘6–0
APPS   OPS    STUDIO GIT    GROK     ← folders + Grok TUI in this clone
```

Swipe to **page 2** for the MCP keys that are not on home (ops row + daily apps). Previous Page stays bottom-left:

```
APPLY  DIFF   SECRETS BREW   TOPG
STATUS AERO   NAS     CURSOR ZED
PREV   OBS    BRAVE   CAM    LIGHT
```

Workspace keys run `aerospace workspace <name>` via tiny background applets (`~/.config/streamdeck/apps/`). They do **not** synthesize ⌥⌘N, so they work without macOS **Accessibility** for Stream Deck. **AeroSpace must be running** for those keys to do anything.

If the Stream Deck app still shows *kann keine Hotkeys auslösen* / *needs Accessibility*:

1. System Settings → Privacy & Security → Accessibility
2. Enable **Stream Deck** (or click the banner in the Elgato app)

We no longer put Hotkey actions on the generated profiles (screenshot/record open Screenshot.app instead). The banner is app-level until the toggle is on.

### Apps folder

Cursor, Zed, OpenCode, Claude, Brave, Obsidian, Mail, Proton Pass, OrbStack, Goose, MuffinTerm, Signal, Camera Hub, Control Center.

Missing apps (host differences) are still bound; Open is a no-op if the `.app` is absent.

### Ops folder

| Key | Runs |
|-----|------|
| APPLY | `chezmoi apply` |
| DIFF | `chezmoi diff` |
| SECRETS | `scripts/check-secrets.sh` |
| BREW | `ansible-playbook setup-macos.yml --limit "$(hostname -s)" --tags brew` |
| PASS | `pass-cli login` (GUI / Keychain) |
| SSH | `scripts/ensure-ssh-agent.sh` |
| REPO | open clone + Cursor/Zed |
| MAIL | `himalaya-tui` (else Himalaya CLI) |
| TOPG | `scripts/topgrade-precheck.sh` then `topgrade` |
| NAS | `scripts/mount-unifi-smb.sh` (needs gitignored `smb-hosts.local`) |
| STATUS | `chezmoi status` |
| AERO | `aerospace reload-config` |
| GH | this public GitHub repo |
| GROK | Grok TUI in the clone |

`.command` keys open **Terminal** so you can read output. **PUSH** (Git folder) asks `y/N` first.

### Studio folder

Camera Hub, Control Center, macOS screenshot (⌘⇧4) / record (⌘⇧5), mute / play / volume, Roon.

Bottom row is **Hue** for Keller (Fitness Schreibtisch): Tokio, Lesen, Malibu pink, Gedimmt, plus AUS. Keys run `scripts/hue_scene.py` via silent applets (no Terminal). `streamdeck-apply.sh` copies the We Love Lights login into `~/.config/streamdeck/hue.local` (not git). Optional gitignored `scripts/hue.local` overrides room (`hue.example` is the template).

### Git folder

`git status` / `pull --rebase` / `push` (confirm) / `log` / `diff` in the **dotfiles clone**, plus secrets scan and repo open. Not a generic “whatever repo is focused” deck.

## MCP Deck (Grok)

The MCP Deck is an **8×4** virtual XL (not 15 keys). Stream Deck 7.5 **Preferences → General → Enable MCP Deck** is already on after first launch. Apply fills all 32 keys: ops, git, all ten AeroSpace workspaces, Cursor/Zed/Obsidian/Brave, Camera Hub, lights.

Grok talks to that profile via official Elgato MCP (`npx @elgato/mcp-server@latest`). Needs:

1. Stream Deck app running, MCP Deck enabled
2. `node` / `npx` on PATH (fnm is fine from a Terminal-launched Grok)
3. `chezmoi apply` so `~/.grok/config.toml` has `[mcp_servers.elgato]`

Then `/mcps` should list `elgato`. Hardware keys stay private; only MCP Actions is exposed to the model.

Optional: in the Stream Deck UI, select an MCP key → AI button → add the phrases you would actually say (“apply dotfiles”, “load ssh agent”).

## Not in git

Live profiles live under `~/Library/Application Support/com.elgato.StreamDeck/` (app-owned, device UUID, generated PNGs). Do not commit that tree. Action scripts and the generator are the source of truth.

## Moon vs haumea

The cask and scripts are **shared**. Run `streamdeck-apply.sh` on whichever Mac currently has the USB deck. Intel (`moon`) and Apple Silicon (`haumea`) both work; Open targets that exist only on one host simply do nothing.
