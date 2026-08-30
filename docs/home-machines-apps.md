# Home machines — apps & Homebrew (haumea vs moon)

Canonical **inventory and parity** notes for primary (**haumea**) and secondary (**moon**).

> **Public repo:** no real email addresses, vault names, or absolute home paths. Personal inventory belongs in a private notes vault.

| Host | Role | Chip | Homebrew prefix | Host-only notes |
|------|------|------|-----------------|-----------------|
| **haumea** | Primary | Apple Silicon (`arm64`) | `/opt/homebrew` | [haumea.md](./haumea.md) |
| **moon** | Secondary | Intel (`x86_64`) | `/usr/local` | [moon.md](./moon.md) |

**Doc map (do not duplicate)**

| Topic | Where |
|-------|--------|
| Primary-only ops (shell, topgrade habits) | [haumea.md](./haumea.md) |
| Secondary-only ops (Syncthing, Intel, SSH) | [moon.md](./moon.md) |
| App / cask / formula **tables** (this file) | sections below |
| AeroSpace keybindings | [aerospace/](./aerospace/) |
| Automation | [../ansible/README.md](../ansible/README.md) |

**Shared SoT**

| What | File / path |
|------|-------------|
| Shared packages | [`brewfile.home.machines`](../brewfile.home.machines) |
| Moon-only packages | [`brewfile.moon.extra`](../brewfile.moon.extra) (Syncthing) |
| Apply (Ansible) | `cd ansible && ansible-playbook setup-macos.yml --limit haumea` (or `moon`) |
| Apply packages (manual) | `brew bundle --file="$(chezmoi source-path)/brewfile.home.machines"` |
| Topgrade | [`dot_config/topgrade.toml`](../dot_config/topgrade.toml) |
| AeroSpace | [`dot_config/aerospace/aerospace.toml.tmpl`](../dot_config/aerospace/aerospace.toml.tmpl) |
| pass-cli wrapper | [`scripts/pass-cli-chezmoi.sh`](../scripts/pass-cli-chezmoi.sh) · workflow: [haumea.md](./haumea.md) / [moon.md](./moon.md) |

Inventory date for tables below: **2026-08-27** (haumea live vs brewfile; re-check with the commands at the end when things drift).

---

## 1. Expected parity

Both machines should share:

1. Everything listed in **`brewfile.home.machines`** (casks + formulae + `mas`).
2. Manual apps that exist for **both architectures** (SYSTM with the correct DMG, Blackmagic ATEM, Backdrop, etc.).
3. Docker via **OrbStack only** (not Colima).

They will **not** share:

- Apple Silicon–only iOS-on-Mac apps (Protect, iOS WiFiman, Romm).
- Install **method** for Parallels (brew on Silicon, vendor installer on Intel).
- Optional primary-only extras — prefer documenting in local `machine-haumea.md` / `machine-moon.md`.
- **Syncthing — moon only** (see §10). Do **not** install, start, or propose on **haumea**.

---

## 2. Parallels Desktop (different install paths)

Same product on both Macs; **different package managers**.

| | **haumea** (arm64) | **moon** (x86_64) |
|--|--------------------|-------------------|
| App path | `/Applications/Parallels Desktop.app` | same |
| Bundle ID | `com.parallels.desktop.console` | same |
| App Store | No | No |
| **Install method** | **Optional Homebrew cask** `parallels` | **Manual only** from [parallels.com](https://www.parallels.com/products/desktop/) |
| Shared brewfile | **Does not** list `parallels` (would break Intel `brew bundle`) | same |
| Caskroom | often under `/opt/homebrew/Caskroom/parallels/` if brew-installed | **none** (vendor install) |
| CLI | via cask / app | vendor paths under `/usr/local/bin` (e.g. `prlctl`) |
| AeroSpace | workspace `vm` (`com.parallels.desktop.console`) | same |
| Per-host versions | record in local **`machine-haumea.md` / `machine-moon.md`** (gitignored) | same |

### Why the shared brewfile does not enable Parallels

The Homebrew cask runs Parallels’ `inittool` during install. On **Intel** that fails with an **inittool preinitialization error**. On **Apple Silicon** the cask usually works, but putting it in the **shared** brewfile would still make moon’s `brew bundle` fail.

```text
# brewfile.home.machines (comment only)
# arm64:  brew install --cask parallels   # optional on primary
# Intel:  manual from parallels.com/download only
```

| Host | Practical rule |
|------|----------------|
| **haumea** | `brew install --cask parallels` / `brew upgrade --cask parallels` is fine; may show in `brew list --cask` |
| **moon** | Install/upgrade **only** via Parallels installer or in-app update — **not** `brew install --cask parallels` |

Inventory will often show **`parallels` cask only on haumea** while the **app exists on both**. That is expected, not a missing install on moon.

### Upgrades

- **haumea:** Homebrew and/or Parallels auto-update.
- **moon:** Parallels auto-update / re-download; version may lag haumea slightly.

---

## 3. Docker runtime: OrbStack only (no Colima)

| Component | SoT | haumea | moon |
|-----------|-----|--------|------|
| Engine / UI | `cask "orbstack"` | Yes | Yes |
| CLI | `brew "docker"`, `brew "docker-compose"` | Yes | Yes |
| **Colima** | **Do not use** | Absent | **Removed 2026-08-04** (was leftover, not running) |
| **Lima** | Only ever as Colima dep | Absent | **Autoremoved** with Colima |

Topgrade:

```toml
# dot_config/topgrade.toml
disable = [..., "colima"]  # OrbStack is the runtime; colima update fails when not running
```

After removing Colima on moon, optional leftover config:

```bash
rm -rf ~/.colima   # only if you do not need old Colima VM data
```

Do **not** add `colima` to the brewfile.

---

## 4. WiFiman: two different apps

| | **WiFiman** (iOS-on-Mac) | **WiFiman Desktop** (optional) |
|--|-------------------------|--------------------------------|
| Display name | WiFiman | WiFiman Desktop |
| Bundle ID | `com.ubnt.wifiman` | `ui.wifiman.desktop` |
| Install | MAS / iOS-on-Mac (`1385561119`) | `brew install --cask wifiman` |
| Arch | **Silicon only** | Intel **and** Silicon |
| Typical host | **haumea** (installed) | **moon** if you want a native Intel client; **not** in the shared brewfile |
| AeroSpace float | `com.ubnt.wifiman` | `ui.wifiman.desktop` |

**Policy (2026-08-27):** haumea uses the **iOS-on-Mac** app. Desktop is optional for Intel; do not treat a missing `wifiman` cask on haumea as drift. Never treat MAS `1385561119` as a moon requirement.

---

## 5. UniFi Protect

| | |
|--|--|
| haumea | `/Applications/Protect.app` — `com.ubnt.protect` (iOS-on-Mac, arm64) |
| moon | **No native app** — use web UI (console / [unifi.ui.com](https://unifi.ui.com)) |
| AeroSpace | Float `com.ubnt.protect` (haumea) |

No reliable Intel desktop package from Ubiquiti for Protect.

---

## 6. Riverside Studio (Apple Silicon only)

| | |
|--|--|
| **App** | Riverside Studio (`RVS-Riverside.fm-Mac`) |
| **Binary** | **arm64 only** — no Intel build in the official DMG |
| **haumea** | OK — `cask "riverside-studio" if Hardware::CPU.arm?` in the shared brewfile |
| **moon** | **No desktop app** — arm64 vendor binary; use the web app |
| **Intel alternative** | **Web app** in Chrome/Edge: [riverside.fm](https://riverside.fm) / [riverside.com](https://riverside.com) |
| **brewfile** | Guarded with `Hardware::CPU.arm?` so Intel `brew bundle` does not try to install it |

There is **no** separate Riverside desktop build for Intel Macs. Mobile: App Store “Riverside Podcast Video Studio”.

AeroSpace still maps `RVS-Riverside.fm-Mac` → workspace `media` (haumea only).

---

## 7. SYSTM (Wahoo)

| | |
|--|--|
| Install | **Manual** vendor DMG (not MAS, no brew cask) |
| Intel | https://systm-download.wahoofitness.com/download/osx |
| Apple Silicon | https://systm-download.wahoofitness.com/download/osx_arm64 |
| Bundle ID | `com.WahooFitness.SYSTM.desktop` |
| Status | Installed on **both** (versions may differ; update from Wahoo) |

---

## 8. Other apps (source + host)

| App | Source | haumea | moon | Notes |
|-----|--------|--------|------|--------|
| **DevPod** | `cask "devpod"` | Yes | Yes | Bundle `sh.loft.devpod`; float in AeroSpace |
| **Marked 2** | `mas "Marked 2", id: 890031187` | Yes | Yes | Float `com.brettterpstra.marked2` |
| **Romm** | TestFlight / iOS wrapper | Yes | No | arm64 only |
| **Pocket Sync** | GitHub [neil-morrison44/pocket-sync](https://github.com/neil-morrison44/pocket-sync) | Yes | Optional | Universal `.dmg` |
| **8BitDo Firmware Updater** | Manual (support.8bitdo.com) | Yes | Optional | Not a brew cask; float `com.8bitdo.firmwareupdater` |
| **Cursor** | `cask "cursor"` | Yes | Optional | Workspace `code` (`com.todesktop.230313mzl4w4u92`) |
| **Grok Bot** | Vendor download | Yes | Optional | Workspace `code` (`com.anysphere.sand`); not a brew cask |
| **Riverside Studio** | brew cask (Silicon only) | Yes | **No** — use web | arm64 binary only; see §6 |
| **ATEM / Blackmagic** | Blackmagic site | Both | Both | Manual |
| **Backdrop** | cindori.com | Both | Both | Manual |
| **Proton Drive / Pass / VPN** | brewfile casks | Both | Both | |
| **Proton Mail Bridge** | — | — | **Removed** | Not in brewfile; do not reinstall for SoT |

---

## 9. Snapshot: remaining host diffs (apps)

### Mainly / only haumea

- UniFi Protect (iOS-on-Mac)
- WiFiman iOS-on-Mac
- **Riverside Studio** (arm64 desktop; moon uses browser)
- Romm, Pocket Sync, 8BitDo updater
- Parallels **via brew cask** (app still on moon via vendor)
- Cursor / Grok Bot (installed here; optional on moon)

### Mainly / only moon

- WiFiman **Desktop** if you want a native Intel client (not required on haumea)
- Parallels **vendor-only** install path
- **Syncthing** — intentional moon-only service (not a haumea gap; see §10)

### Explicitly not on moon

- **Riverside Studio** — uninstalled; Silicon-only (use web on Intel)
- **Proton Mail Bridge** — uninstalled; not in brewfile

### Should match (brewfile + mas + manual SYSTM)

DevPod, Marked 2, OrbStack, Claude, Proton Drive/Pass/VPN, Office, iWork, SYSTM, etc.

---

## 10. Homebrew: formulae, casks, services

### Policy

| Align | How |
|-------|-----|
| Shared packages | `brewfile.home.machines` + `brew bundle` |
| Docker | OrbStack + docker/docker-compose formulae |
| Machine-local tools | Allowed; document extras below |

### Formulae snapshot (2026-08-27, haumea)

| | haumea |
|--|-------:|
| All formulae | 147 |
| Leaves | 41 |
| Casks | 49 (incl. `cursor`, `parallels`, `ledger-live`) |

`deno` and `ripgrep` are in the brewfile **and** installed (also pulled in as deps of `yt-dlp` / `opencode`).

#### Extra formulae on haumea (not in brewfile)

| Formula | Role |
|---------|------|
| `fclones` | Fast dup finder |
| `jdupes` | Dup finder |
| `go` | Go toolchain |
| `lego` | ACME / Let's Encrypt client |
| `libopenmpt` | Module playback (demoscene sidecar) |
| `node` | Extra leaf (`fnm` is the version-manager SoT) |
| `sshpass` | Non-interactive SSH passwords |

#### Syncthing — **moon only** (intentional)

| Host | Policy |
|------|--------|
| **moon** | Install + `brew services start syncthing` as desired |
| **haumea** | **Do not install. Do not start. Do not propose.** |

Absence of Syncthing on haumea is **by design**, not drift. Shared `brewfile.home.machines` does **not** include `syncthing`. Install on moon only via `brewfile.moon.extra` (Ansible does this when `--limit moon`).

#### In brewfile (were listed as extras in older snapshots)

`butane`, `just`, `p7zip`, `wakeonlan`, `czkawka` — already in `brewfile.home.machines`.

### Casks vs brewfile (haumea 2026-08-27)

| Situation | Packages |
|-----------|----------|
| Live, not in shared brewfile | `parallels` (optional Silicon; see §2), `ledger-live` (app is Ledger Live; brewfile token is `ledger-wallet`) |
| Added to brewfile this pass | `cursor` |
| Manual (not brew) | 8BitDo Firmware Updater, Grok Bot, Pocket Sync, Protect, SYSTM, ATEM, Backdrop, DisplayLink Manager |
| Removed from SoT | Perplexity (MAS), **Adobe Acrobat** (uninstalled) |
| Silicon-only in brewfile | `riverside-studio` (`Hardware::CPU.arm?`) |

Do **not** `brew install --cask wifiman` or `8bitdo-firmware-updater` as a haumea catch-up.

### brew services (typical)

| Service | haumea | moon |
|---------|--------|------|
| `atuin` | started | started |
| `syncthing` | **never** (moon-only) | **started** |
| `colima` | — | **removed** |

---

## 11. Mail (personal account — keep details private)

### How it is set up on haumea

| | |
|--|--|
| **Client** | Apple **Mail** (Internet Accounts) |
| **Account type** | **Microsoft Exchange / Microsoft 365** (not legacy-registrar IMAP) |
| **Email** | `you@example.com` |
| **Display name** | Your Name |
| **EWS** | `https://outlook.office365.com/EWS/Exchange.asmx` |
| **Auth** | Microsoft OAuth (`login.microsoftonline.com`) |
| **Aliases seen on haumea** | includes example-mail-provider / example.capital / example.ventures addresses on the same identity |

Pass item title: use a private vault item (password + TOTP). Do not publish item titles.

Related Pass items (different products — do not confuse):

- `Google (you@example.com)` — Google account for that address if used elsewhere  
- `hosteurope.de` — KIS login (domain panel), not the Mail Exchange config  

haumea also has an MDM/profile identifier mentioning Proton for this address; **Proton Mail Bridge is not** the active path for this mailbox on haumea (Bridge app not installed).

### moon (2026-08-04)

| Before | After goal |
|--------|------------|
| Address only under `mdmclient` (no Mail account) | Same **Exchange** account as haumea in Mail |

**Cannot be fully automated** (Microsoft OAuth needs interactive sign-in). On moon:

1. **System Settings → Internet Accounts** → **Microsoft Exchange** (or **Mail → Add Account… → Microsoft Exchange**).
2. Name: `Your Name` · Email: `you@example.com`
3. Sign in with Microsoft when prompted (Pass: legacy-registrar-titled item for password/TOTP if needed).
4. Enable **Mail** (+ Contacts/Calendars if desired).

Verify: Mail sidebar shows the account and can send/receive.

---

## 12. OpenCode (CLI + desktop)

**Install (SoT):** brew formula `opencode` + cask `opencode-desktop` in `brewfile.home.machines`.

| Piece | Typical location | In this git repo? |
|-------|------------------|-------------------|
| CLI / desktop | Homebrew prefix | package names only |
| App config / themes | under `~/.config/opencode/` | **no** |
| Auth / OAuth / API keys | under `~/.local/share/opencode/` and env files | **no** — mode `600`, never commit |
| PATH helper | managed `~/.zshrc` (optional `$HOME/.opencode/bin`) | yes |

**Do not publish:** provider lists, default model IDs, env file contents, or auth JSON. Prefer app UI login on each machine.

**Syncing machines:** copy non-secret preferences only if needed; re-authenticate OAuth providers on the second machine (tokens are often device-bound). Do not commit or paste secrets into git or public docs. Avoid copying large session DBs unless you intentionally migrate chat history.

**Ghost project paths:** do not open missing folders in the desktop app; use a real project directory (e.g. under `~/Developer/Projects`). Host-specific habits: [haumea.md](./haumea.md).

---

## 12b. Goose (CLI + desktop)

**Install (SoT):** brew cask `block-goose` in `brewfile.home.machines`.

| Piece | Typical location | In this git repo? |
|-------|------------------|-------------------|
| CLI / desktop | Homebrew cask + `~/.local/bin/goose` | package name only |
| App config / extensions | `~/.config/goose/config.yaml` | **no** (app-managed) |
| Custom providers (no keys) | `~/.config/goose/custom_providers/` | yes — `dot_config/goose/custom_providers/` |
| SuperGrok OAuth tokens | `~/.config/goose/xai_oauth/tokens.json` | **no** — mode `600` |
| API keys | Goose keyring (`service=goose`) / `secrets.yaml` | **no** |

**Auth rule:** default provider is Goose’s built-in **`xai_oauth`** (SuperGrok / X Premium+ subscription). Do **not** set Goose to the built-in `xai` provider (`XAI_API_KEY` — console API billing).

After OpenCode re-login (`/connect xai`), re-import:

```bash
./scripts/sync-goose-from-opencode.sh
```

#### Desktop “Configuration Error” / missing provider

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Goose Desktop: *“Configuration Error — please configure an API provider”* | Missing or stale `~/.config/goose/xai_oauth/tokens.json` while `config.yaml` still says `GOOSE_PROVIDER=xai_oauth` | Ensure OpenCode `xai` OAuth works, then `./scripts/sync-goose-from-opencode.sh`; relaunch Goose.app |
| CLI works after sync, Desktop still errors | App launched before tokens existed | Quit + reopen Goose.app |
| Sync prints refresh / `invalid_grant` | SuperGrok refresh revoked | OpenCode `/connect xai` (or `opencode auth login`), then re-run sync |

Smoke (CLI):

```bash
goose run -t "reply with only the word: pong"
# expect session line: xai_oauth + default model, then pong
```

**Do not publish:** model IDs, env file contents, or token JSON. Host-specific catalog: local `machine-*.md`.

---

## 13. Obsidian + Agent Client (ACP)

### Vault layout (2026-08-04) — one vault, Obsidian Sync only

**Problem:** multiple local trees (`Documents/YourVault`, `Documents/YourVault-Moon`, `~/...`) plus iCloud Desktop & Documents made dual-sync risk with **Obsidian Sync**.

**Policy:**

| | |
|--|--|
| **Working path (both Macs)** | **`~/Obsidian/YourVault`** |
| **Multi-machine sync** | **Obsidian Sync only** (one remote vault) |
| **Avoid** | Editing iCloud-backed *and* Sync-backed copies of the same tree; opening old `Documents/YourVault*` paths for daily work |
| **Why `~/Obsidian/`** | Outside the confusing multi-folder Documents layout; one clear path per Mac |

**Backups (zip, before move):**

| Host | Location |
|------|----------|
| haumea | `~/Documents/Backups/obsidian-20260804-204426/` |
| moon | `~/Documents/Backups/obsidian-20260804-204427/` |

**Archived paths:** old folders left in place with `ZZZ-READ-ME-DO-NOT-EDIT-archived.txt` (safe leftovers; do not open as primary).

**Your job once per Mac after setup:**

1. Quit Obsidian (⌘Q) and reopen.  
2. Open **`~/Obsidian/YourVault`**.  
3. **Settings → Sync** → same Obsidian account + same remote Sync vault as the other machine.  
4. Wait until Sync is idle before heavy edits on the second Mac.

README on each Mac: `~/Obsidian/README.md`.

### Required npm / brew tools (Obsidian Agent Client)

Install via:

```bash
eval "$(fnm env)"
fnm install 24 && fnm default 24
"$(chezmoi source-path)/scripts/install-npm-acp-agents.sh"
"$(chezmoi source-path)/scripts/install-npm-cli-tools.sh"   # optional leftover CLIs; not used by Agent Client
brew install opencode   # OpenCode ACP: opencode acp
brew install --cask antigravity-cli   # agy TUI — not ACP / not Obsidian
```

| Tool | Package | Role |
|------|---------|------|
| **OpenCode** (default agent) | brew `opencode` | `opencode acp` — uses local OpenCode config + auth (never commit) |
| **Claude Code ACP** | `@agentclientprotocol/claude-agent-acp@0.68.0` | Agent Client “Claude Code” |
| **Codex ACP** | `@agentclientprotocol/codex-acp@1.3.0` | Agent Client “Codex” |
| **Antigravity CLI** | brew cask `antigravity-cli` → `/opt/homebrew/bin/agy` | Gemini successor. **Not in Agent Client** (no ACP). Use Terminal or Antigravity 2.0. |
| **Mistral Vibe** | brew `mistral-vibe` → `vibe-acp` | Agent Client via `~/.config/mistral-vibe/launch-acp-with-env.sh` |
| **Kiro CLI** | brew cask `kiro-cli` → `kiro-cli acp` | Agent Client via `~/.config/kiro/launch-acp-with-env.sh` |

**Critical:** Agent Client must **not** store ephemeral `fnm_multishells/...` paths. Use stable:

`~/.local/share/fnm/node-versions/v24.x.x/installation/bin/{node,claude-agent-acp,codex-acp}`

and `/usr/local/bin/opencode` (Intel) or `/opt/homebrew/bin/opencode` (Silicon).

### Agent Client plugin settings (haumea)

Vault: `~/Obsidian/YourVault` · plugin `agent-client` · file  
`…/plugins/agent-client/data.json`

| Setting | Value |
|---------|--------|
| **Default agent** | OpenCode |
| **OpenCode command** | `~/.config/opencode/launch-acp-with-env.sh` |
| **OpenCode args** | `["acp"]` (plugin default; wrapper is **idempotent** — will not run `acp` twice) |
| **Codex command** | `~/.config/codex/launch-acp-with-env.sh` |
| **Gemini CLI** | **off** (`enabled: false`) |
| **Mistral Vibe** | `~/.config/mistral-vibe/launch-acp-with-env.sh` (`vibe-acp`; `MISTRAL_API_KEY` from Keychain) |
| **Kiro** | `~/.config/kiro/launch-acp-with-env.sh` (`kiro-cli acp`; one-time `kiro-cli login`) |
| **Grok Build** | `~/.config/grok/launch-acp-with-env.sh` (`grok agent stdio`; SuperGrok OAuth via `grok login`) |
| **nodePath** | stable fnm Node `…/installation/bin/node` |

TUI policy (`~/.grok/config.toml`) is chezmoi-managed — see [`dot_grok/config.toml.tmpl`](../dot_grok/config.toml.tmpl) and [secrets-pass.md](./secrets-pass.md). Do not export `XAI_API_KEY` into interactive shells.

**Pitfall (2026-08-06):** Old wrapper always ran `opencode acp "$@"`. Agent Client also passes `acp` (and **re-injects** it if `args` is empty) → `opencode acp acp` → *ACP connection closed*, or stuck **Connecting…** after partial fix.  
Wrapper now: if `$1 == acp` then `exec opencode "$@"` else `exec opencode acp "$@"`.  
Same for **Kiro**: `kiro-cli acp acp` exits immediately (`unexpected argument 'acp'`). Wrapper is idempotent; plugin `args` is `["acp"]`.  
Details: `hermes-stack/docs/guides/hermes-opencode-acp-editors.md`.

### Agent Client plugin settings (moon, after fix)

- **Default agent:** OpenCode  
- **OpenCode command:** `~/.config/opencode/launch-acp-with-env.sh`  
- **OpenCode args:** `["acp"]` (wrapper is **idempotent**, same as haumea — 2026-08-06)  
- **nodePath:** stable fnm Node `…/installation/bin/node` (e.g. v24.19.0 on moon)  
- **Binary:** brew `/usr/local/bin/opencode` (Intel) on PATH inside the wrapper  
- Hermes agent dropped if `~/bin/hermes` is missing  

**2026-08-06:** same double-`acp` fix as haumea applied on moon (wrapper + `agent-client` data.json).

### Plugin list (enabled community plugins on YourVault)

`dataview`, `obsidian-tasks-plugin`, `templater-obsidian`, `day-planner-og`, `obsidian-kanban`, `obsidian-local-rest-api`, `obsidian42-brat`, `ai-tagger-universe`, `terminal`, `obsidian-excalidraw-plugin`, `show-whitespace-cm6`, **`agent-client`**

Also present on disk (not all always enabled): `opencode-obsidian`, raindrop, textgenerator, etc.

### After changes

1. Fully quit Obsidian on moon (⌘Q) and reopen.  
2. Open vault **YourVault** under `~/Documents/YourVault`.  
3. Enable **Agent Client** if needed (Community plugins).  
4. New chat → agent **OpenCode** → pick a model you have configured locally (do not publish model IDs).

---

## 14. MacWhisper (haumea + moon) — full setup

**Last full audit:** 2026-08-05. Bundle ID: `com.goodsnooze.MacWhisper`. AeroSpace workspace: **media**.

MacWhisper is **not** an agent like OpenCode or Obsidian Agent Client. It does:

1. **Speech-to-text** (local engines and/or cloud STT)  
2. Optional **LLM on the transcript** (summary, Q&A, cleanup)

| Concern | OpenCode / Obsidian Agent | MacWhisper |
|---------|---------------------------|------------|
| Role | coding / vault agent | STT + enhance **transcripts** |
| Auth | App OAuth / login | API keys in macOS Keychain (app-managed) |
| Default LLM | Whatever you configure in each app | Keep keys out of git |
| Audio / STT models | **Not** in OpenCode model picker | Local engines + **cloud STT** (cloud STT, OpenRouter Whisper, …) |

Do **not** add Grok STT / Cohere Transcribe to `opencode.jsonc` — wire them only in MacWhisper (or separate CLIs).

### Inventory (2026-08-05)

| | **haumea** | **moon** |
|--|------------|----------|
| CPU | Apple Silicon (arm64) | Intel (x86_64) |
| macOS (audit) | **26.6** | **15.7** |
| MacWhisper app | **14.6** | **14.6** |
| Pro license (Gumroad) | yes | yes |
| Argmax / WhisperKit Pro tokens | yes | not required for cloud; Pro engines Silicon-only |

Prefs domain: `com.goodsnooze.MacWhisper`  
Support dir: `~/Library/Application Support/MacWhisper/`  
CLI: `/Applications/MacWhisper.app/Contents/MacOS/mw`  
- `mw models list` — downloaded models  
- `mw models select <engine:id>` — select only (**download is in-app**)  
- `mw transcribe …` — file transcription  

### Architecture limits (critical)

| Feature | haumea (Silicon) | moon (Intel) |
|---------|------------------|--------------|
| **WhisperKit** (Large v3 Turbo, etc.) | Yes | **No** — [docs: WhisperKit is M‑series only](https://docs.macwhisper.com/article/29-switching-to-a-whisperkit-model) |
| **Parakeet Pro** | Yes | **No** (Silicon / GPU-class stack) |
| **Whisper C++** (classic ggml) | Available | **Yes — primary local path** |
| **Apple Speech** language packs | Yes if **macOS 26+** | **No** on 15.x — “native speech requires macOS 26+” |
| **Apple Foundation Model** (LLM) | macOS 26+ | Not on 15.x |
| **Cloud STT** (xAI, OpenRouter, ElevenLabs, OpenAI, …) | Yes | **Yes — preferred for quality** |
| **Transcript LLM** (cloud provider) | Yes | Yes (API key in keychain) |

**Pro license ≠ Pro Silicon engines.** Gumroad Pro unlocks features; WhisperKit/Parakeet still need Apple Silicon.

### Local models — recommendations

#### haumea (Apple Silicon) — verified `mw models list`

| ID | UI name | Use |
|----|---------|-----|
| `whisperkit:openai_whisper-large-v3-v20240930` ▸ | **Large v3 Turbo** | **Default** files + dictation |
| `parakeet-pro:nvidia_parakeet-v3` | Parakeet v3 | **Live** captions / meetings |
| `whisperkit:openai_whisper-small` | Small | Drafts only |
| `apple:de-DE` | Deutsch (Deutschland) | Apple Speech pack (macOS 26+) |

Prefs:

- `selectedRunnerConfig` / `dictationRunnerConfig` → WhisperKit large-v3, language **`en`**
- `liveTranscriptionRunnerConfig` → Parakeet v3, language **`en`**

Do **not** prefer **Large v2** over Large v3 Turbo on Silicon — v2 is older.

Apple Speech packs: **Einstellungen → Lokale Modelle → Empfohlene Modelle → Apple Speech** (only on macOS 26+). Only downloaded packs appear under “Heruntergeladen”.

#### moon (Intel) — Whisper C++

WhisperKit UI names (**Large v3 Turbo** under WhisperKit) **do not apply**. Local catalog is **Whisper C++**, e.g.:

| ID (example) | UI name | Recommendation |
|--------------|---------|----------------|
| `whisper-cpp:ggml-model-whisper-turbo` | **Turbo** (~1.6 GB) | **Prefer** — faster, newer turbo line |
| `whisper-cpp:ggml-model-whisper-large` | **Large (V2)** (~3 GB) | Avoid as default — older large-v2, slower |

**On Intel prefer Turbo over Large V2.** For best quality, use **cloud STT** (cloud STT / OpenRouter Whisper) instead of local.

Never copy `~/Library/Application Support/MacWhisper/models` from arm64 → x86.

### Cloud speech-to-text (both machines)

Prefs: `configuredCloudTranscriptionProviders` includes  
`custom` · `openAI` · `elevenlabs` · `openRouter` · **`xAI`**

| Provider | In-app | Keychain account | Notes |
|----------|--------|------------------|--------|
| **Cloud STT** | Cloud models → vendor | `(app keychain account — local only)` | STT model IDs are local; API key often separate from chat subscription OAuth. |
| **OpenRouter** Whisper Large V3 | OpenRouter row | `openRouterAPIKeyForCloudTranscription_Key` | OpenAI-compatible Whisper via OpenRouter |
| **ElevenLabs** Scribe | ElevenLabs | `elevenLabsAPIKeyForCloudTranscription_Key` | |
| **OpenAI** Whisper | OpenAI | `chatGPTAPIKey_Key` | Region pref: **`eu`** (`openAICloudTranscriptionRegion`) |
| **Custom OpenAI Whisper** | Custom form | custom key slots | Base URL + **`/v1/audio/transcriptions` only** — chat LLM bases (Grok chat, Cohere OAI) **will not work** |
| **Cohere Transcribe** | — | — | **Not native.** API is `POST /v2/audio/transcriptions` (`cohere-transcribe-03-2026`) |

**Custom form** is for self-hosted Whisper / true OpenAI-compatible STT hosts — not OpenCode’s chat providers.

UI: **Einstellungen → Transkription → Cloud-Modelle → xAI / OpenRouter → Konfigurieren**.

### LLM / AI assistant (post-transcript)

Prefs: `configuredAIServices_15july2025`, `selectedAIServiceID`, `selectedAISummarizationProviderID`

| Service | Model | Selected |
|---------|--------|----------|
| Apple Foundation Model | system | no (needs macOS 26+) |
| **Cloud LLM A** | model id local | yes (chat + summarization) — UUID local |
| **OpenRouter** (optional) | model id local | alternate — UUID local |
| Ollama | empty @ `http://localhost:11434` | optional local |

**Summary behaviour (both):**

| Pref | Value |
|------|--------|
| `customSummaryPrompt` | `more in-depth, with names mentioned` |
| Bullet points | on |
| Key points / action items | off |
| Speakers in AI prompt | on |
| Timestamps in AI prompt | off |
| Auto-export AI summary | off |

If a model errors: Settings → AI services → try another model id the app accepts.

### Export, dictation, meetings, Obsidian

| Setting | Value |
|---------|--------|
| Default batch export | **Segments .md** — speakers **on**, timestamps **on**, multi-line, max 140 chars |
| Watch-folder MD template | leaner segments (speakers off) when a watch folder is enabled |
| Translation | **Apple**, side-by-side **on** |
| Dictation | **on**; recordings saved to history |
| Meetings observed | Zoom (`us.zoom.xos`), Teams (`com.microsoft.teams2`) |
| Global show shortcut | **⌥⌘K** (US; carbon keyCode 40 + option+cmd) |
| Mic priority (template) | Continuity iPhone first, then built-in |
| Obsidian folder | `/Transcripts` |
| Watch folder | haumea: `/Volumes/media/podcasts/Example Podcast/` (when mounted); **moon: none** (volume not mounted) |

### Keychain inventory (names only — never commit secrets)

Service: `com.goodsnooze.MacWhisper` unless noted.

| Account | Purpose |
|---------|---------|
| `gumroadLicenseKey_Key` | App Pro license |
| `aiservice-…` (local keychain) | LLM provider entry |
| `aiservice-openrouter-A1B2C3D4-…` | LLM OpenRouter |
| `(app keychain account — local only)` | **Cloud STT** Grok STT |
| `openRouterAPIKeyForCloudTranscription_Key` | Cloud STT OpenRouter Whisper |
| `elevenLabsAPIKeyForCloudTranscription_Key` | Cloud STT ElevenLabs |
| `chatGPTAPIKey_Key` | OpenAI Whisper / legacy |
| `obsidianIPAddress_Key` / `obsidianPort_Key` / `obsidianAPIToken_Key` | Local Obsidian API |
| `com.goodsnooze.MacWhisper.Argmax.*` | Argmax / Pro model auth (haumea) |

**Key sources:**

| Secret | Source of truth |
|--------|-----------------|
| OpenRouter | `OPENROUTER_API_KEY` in `~/.zshrc.local` / Pass **OpenRouter** |
| Cloud STT/LLM API | Vendor API key in Keychain (often separate from chat subscription OAuth) |
| Extra LLM providers | OpenCode env/keychain only — **not** necessarily MacWhisper STT |

### Chat subscription vs API STT vs OpenCode

| Product | Exists? | Use where? |
|---------|---------|------------|
| cloud STT (`POST /v1/stt`, model stt-model-id) | Yes | **MacWhisper cloud xAI** |
| Provider chat (subscription OAuth) | Optional | Configure in OpenCode UI only |
| Cohere Transcribe | Yes (`/v2/audio/transcriptions`) | External / future; **not** MacWhisper native |
| Cohere North / Command | Yes | **OpenCode** chat only |

A chat subscription is not the same as unlimited API STT. STT is usually API-billed when using console API keys.

### How to use day-to-day

**haumea (local-first):**

1. Transcribe with **Large v3 Turbo** (WhisperKit).  
2. Live / meetings → **Parakeet v3**.  
3. Open transcript → **AI → xAI** → summary / custom prompt.  
4. Optional: cloud STT for messy audio (cloud STT / OpenRouter / ElevenLabs).

**moon (Intel — cloud-first for quality):**

1. Local fallback: Whisper C++ **Turbo** (not Large V2).  
2. Prefer **Cloud-Modelle → xAI (Grok STT)** or OpenRouter Whisper Large V3.  
3. Same AI service you configured for chat summaries.  
4. No Apple Speech packs until macOS 26+; no WhisperKit/Parakeet.

### Parity / ops notes

Functional prefs + Keychain were mirrored **haumea → moon** (2026-08-05).

| Topic | Rule |
|-------|------|
| Keychain over SSH | moon fails with `-25308` (“User interaction is not allowed”) — use **GUI Terminal** or `open -a Terminal /path/to/install-script.sh` |
| Model files | Download in-app per machine; never copy arm64 CoreML to Intel |
| Prefs write | `defaults export/import` + `plistlib` for complex arrays; provider list elements look like `'"xAI"'` (quoted strings) |
| Watch folder | Only enable when `/Volumes/media/podcasts/...` is mounted |

### Verify

```bash
# Models
/Applications/MacWhisper.app/Contents/MacOS/mw models list

# Selected engines / AI / cloud list
defaults read com.goodsnooze.MacWhisper selectedRunnerConfig
defaults read com.goodsnooze.MacWhisper liveTranscriptionRunnerConfig
defaults read com.goodsnooze.MacWhisper selectedAIServiceID
defaults read com.goodsnooze.MacWhisper configuredCloudTranscriptionProviders

# Key presence (no secret printed)
for a in \
  xAIAPIKeyForCloudTranscription_Key \
  openRouterAPIKeyForCloudTranscription_Key \
  elevenLabsAPIKeyForCloudTranscription_Key \
  aiservice-PROVIDER-UUID \
  aiservice-openrouter-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
do
  security find-generic-password -s com.goodsnooze.MacWhisper -a "$a" >/dev/null 2>&1 \
    && echo "OK $a" || echo "MISS $a"
done
```

### External docs

- [Switching to WhisperKit](https://docs.macwhisper.com/article/29-switching-to-a-whisperkit-model) (Silicon only)  
- [ChatGPT / AI in MacWhisper](https://docs.macwhisper.com/article/7-how-to-use-chatgpt-in-macwhisper)  
- [MDM AI services](https://docs.macwhisper.com/article/27-deploying-macwhisper-with-mdm)  
- [xAI Voice / STT API](https://docs.x.ai/developers/rest-api-reference/inference/voice) (`POST /v1/stt`)  
- [Cohere Transcribe API](https://docs.cohere.com/reference/create-audio-transcription) (not wired here)

---

## 15. pass-cli / chezmoi (multi-machine)

Not app inventory, but required for `chezmoi apply` / topgrade templates on both hosts:

| Topic | Rule |
|-------|------|
| Session probe | `pass-cli info` (pass-cli 2.2.4+ removed `test`) |
| GUI vs SSH | Keyring unlock needs **GUI Terminal**; SSH hits `-25308` |
| PAT | Optional optional local PAT file under `~/.config/pass-cli/` (mode 600, never commit) (mode 600); grant vault **viewer** for PAT |
| PAT + `pass://` vault id | PAT share id ≠ user vault id → **422**; use [`scripts/pass-cli-chezmoi.sh`](../scripts/pass-cli-chezmoi.sh) as `[protonPass] command` |
| Precheck | `scripts/topgrade-precheck.sh` (pass-cli session + SSH agent; wired as topgrade `[pre_commands]`) |

Details: [haumea.md](./haumea.md) (primary) · [moon.md](./moon.md) (secondary, soft Pass over SSH).

---

## 16. Zed editor (haumea + moon)

**Last sync:** 2026-08-05. Bundle ID: `dev.zed.Zed`. AeroSpace workspace: **code** (+ force-tile script for macOS native fullscreen — see [aerospace/README.md](./aerospace/README.md)).

Brew SoT: `cask "zed"` in `brewfile.home.machines`.

### Inventory

| | haumea | moon |
|--|--------|------|
| App | Zed **1.13.1** (arm64) | Zed **1.13.2** (x86_64) |
| Config | `~/.config/zed/settings.json` | same path, **md5-matched** after sync |
| Font | Hack Nerd Font (`Hack NF`) | installed via `font-hack-nerd-font` cask |
| Extensions | dockerfile, html, solarized, toml, xml | **same** (synced from haumea `extensions/installed`) |
| CLI agent | brew `opencode` → `opencode acp` | same (`/usr/local/bin/opencode` on Intel) |
| ACP helpers | claude-agent-acp, codex-acp | same npm pins as Obsidian Agent Client |

### settings.json (shared behaviour)

Do **not** commit this file (contains LiteLLM / Olares tokens). Copy haumea → moon only over SSH.

| Area | Value |
|------|--------|
| Theme | **Solarized Dark** (needs **solarized** extension) |
| Font | **Hack NF** 16 / UI 16 |
| Keymap | VSCode |
| Panels | project / outline / collab / git → **right**; agent → **left** |
| Default agent model | configure providers in the UI / keychain; do not commit model IDs or keys |
| Agent servers | `claude-acp`, `gemini`, `codex-acp` (registry); **`opencode`** custom → `opencode acp` |
| Language models | Ollama + OpenAI-compatible LiteLLM (Olares host URLs) |
| Context server | `litellm-mcp` (Olares MCP URL + bearer) |
| **Edit predictions** | **Codestral** (`edit_predictions.codestral` → `https://codestral.mistral.ai`, model `codestral-latest`) |
| Telemetry | diagnostics **off**, metrics **off** |
| Session | `trust_all_worktrees: true` |

### LLM providers in `settings.json` (required structure)

Zed does **not** store API keys in `settings.json` (keychain + env vars only). But providers must be listed under `language_models` with correct `api_url`s. **Do not** point built-in `"openai"` at LiteLLM — that hijacks the OpenAI provider. Use `openai_compatible` instead:

| Provider key | `api_url` | Env var (GUI) |
|--------------|-----------|----------------|
| `anthropic` | `https://api.anthropic.com` | `ANTHROPIC_API_KEY` |
| `openai` | `https://api.openai.com/v1` | `OPENAI_API_KEY` |
| `x_ai` | `https://api.x.ai/v1` | `XAI_API_KEY` |
| `deepseek` | `https://api.deepseek.com/v1` | `DEEPSEEK_API_KEY` |
| `mistral` | `https://api.mistral.ai/v1` | `MISTRAL_API_KEY` |
| `open_router` | `https://openrouter.ai/api/v1` | `OPENROUTER_API_KEY` |
| `openai_compatible.LiteLLM` | Olares LiteLLM `/v1` | (key in URL headers / proxy) |
| `ollama` | Olares ollama host | — |

**Keys (stable Zed does not auto-load a config `.env` for LLM providers):**

| File / tool | Role |
|-------------|------|
| `~/.config/zed/api-keys.env` | mode **600**; `export ANTHROPIC_API_KEY=…` etc. (local only, never commit) |
| `~/.config/zed/launch-zed-with-keys.sh` → `~/.local/bin/zed-with-keys` | sources `api-keys.env` (+ Keychain fallback) then runs `/Applications/Zed.app/Contents/MacOS/zed` |
| Keychain | Internet password `server=<api_url>`, `account=Bearer` (what the Settings UI writes) |

Dock/`open -a Zed` does **not** load `api-keys.env`. Prefer:

```bash
zed-with-keys
```

Or paste keys once in **Settings → AI → LLM Providers** so Keychain is owned by Zed.

**Agent model IDs must exist in this Zed build** — use IDs the current Zed release accepts (mismatch → “provider not configured or does not support the configured model”).

### Dependencies on moon (after install)

```bash
# already done 2026-08-05 if brew/fnm present
brew install --cask zed font-hack-nerd-font
# ACP agents (same as scripts/install-npm-acp-agents.sh)
eval "$(fnm env)"; fnm default 24
npm install -g @agentclientprotocol/claude-agent-acp@0.68.0 \
  @agentclientprotocol/codex-acp@1.3.0
```

OpenCode on the secondary host: see **§12**. Re-authenticate providers in each app after setup; do not copy auth files into git.

### Re-sync from haumea

```bash
# settings
scp ~/.config/zed/settings.json secondary.local:~/.config/zed/settings.json

# extensions (tar; rsync path-with-spaces is flaky on some moons)
tar -C "$HOME/Library/Application Support/Zed/extensions" -cf - installed index.json \
  | ssh secondary.local 'tar -C "$HOME/Library/Application Support/Zed/extensions" -xf -'
```

### First launch on moon

1. Quit Zed fully if open (⌘Q).  
2. Open Zed — confirm **Solarized Dark** + **Hack NF**.  
3. Agent panel: preferred local agents available after sign-in.  
4. If theme missing: Extensions → install **Solarized**.  
5. Prefer quit **windowed** so AeroSpace force-tile is less needed next open.

### Verify

```bash
ssh secondary.local 'python3 - <<"PY"
import json
from pathlib import Path
d=json.loads(Path.home().joinpath(".config/zed/settings.json").read_text())
assert d["theme"]=="Solarized Dark"
assert d["buffer_font_family"]=="Hack NF"
assert d["agent"]["default_model"]["provider"]=="x_ai"
print("OK", list(Path.home().joinpath("Library/Application Support/Zed/extensions/installed").iterdir()))
PY'
```

---

## 17. How to re-compare

```bash
# Applications
ls -1 /Applications | sed 's/\.app$//' | sort -f

# Homebrew
brew list --cask | sort
brew list --formula | sort
brew leaves | sort
brew services list

# Mac App Store
mas list

# Parallels specifically
brew list --cask parallels 2>/dev/null || echo "parallels cask: not installed"
ls -ld "/Applications/Parallels Desktop.app"
prlctl --version 2>/dev/null || true
mdls -name kMDItemVersion -name kMDItemCFBundleIdentifier "/Applications/Parallels Desktop.app"
```

Normalize when diffing names: `JDownloader2` ≡ `JDownloader 2`, `Protect` ≡ UniFi Protect.

Install missing SoT packages:

```bash
brew bundle --file="$(chezmoi source-path)/brewfile.home.machines"
```

Optional cleanups / catch-up:

```bash
# moon — Syncthing (moon only; never on haumea)
brew install syncthing && brew services start syncthing

# moon — drop old Colima data if unused
rm -rf ~/.colima
```

---

## Related docs

- [haumea.md](./haumea.md) — primary host notes
- [moon.md](./moon.md) — secondary host notes
- [aerospace/WORKSPACES.md](./aerospace/WORKSPACES.md) — workspace / float map
- [../brewfile.home.machines](../brewfile.home.machines) — package SoT
- [../dot_config/topgrade.toml](../dot_config/topgrade.toml) — disabled steps (Colima, containers, …)
- [../README.md](../README.md) — setup overview
