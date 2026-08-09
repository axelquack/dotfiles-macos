# Primary host notes

**Last updated:** 2026-08-09  
**Audience:** public / generic — no personal accounts or absolute home paths  

Host-level ops notes for the **primary** Apple Silicon Mac (daily driver).  
App parity with a secondary Mac: [docs/home-machines-apps.md](docs/home-machines-apps.md).

### Explicit non-goals (do not propose)

| Item | Policy |
|------|--------|
| **Syncthing** | **Secondary host only** (`brewfile.moon.extra` / Ansible `--limit moon`). Never install on the primary. |

---

## AeroSpace (summary)

Full write-up: **[docs/aerospace/](docs/aerospace/)**.

- Prefer **config-version 2** and **persistent named workspaces** when on a recent AeroSpace beta.
- Rebuild float/workspace rules from a full install audit (`mdls` bundle IDs — never guess).
- Markdown preview apps often **float**; native fullscreen editors may need a small helper to force tiling.
- Cheatsheet: [docs/aerospace/SHORTCUTS.md](docs/aerospace/SHORTCUTS.md).

Live config path after `chezmoi apply`: `~/.config/aerospace/aerospace.toml`.

---

## Shell / chezmoi

### OpenCode PATH in `~/.zshrc`

- Installers sometimes append a **duplicate absolute** `PATH` line.
- Prefer a portable, **idempotent** check on `$HOME/.opencode/bin` in the managed `dot_zshrc`.
- Machine secrets stay in **`~/.zshrc.local`** (not chezmoi-managed, never commit).

### Topgrade pre-check

Wire a pre-command from `dot_config/topgrade.toml` if you use one (optional script under `scripts/`).

| Check | Sensible behaviour |
|-------|---------------------|
| `pass-cli` missing | Fail if chezmoi templates need Proton Pass |
| `pass-cli` session | Warn and continue on secondary hosts if keyring is locked over SSH |
| Optional PAT file | Local only, mode `600` — never commit |
| GitHub SSH key | Load into agent before `chezmoi update` / `git` over SSH |

**pass-cli 2.2.4+:** use `pass-cli info` (the old `pass-cli test` subcommand is gone). First-time or keychain-locked login needs an **interactive GUI Terminal**:

```bash
pass-cli login   # interactive Terminal, not SSH-only
# optional: pass-cli login --pat "$(tr -d '\n' <"$HOME/.config/pass-cli/pat")"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519   # your GitHub key path
topgrade
```

**PAT + chezmoi:** if PAT vault share IDs differ from interactive `pass://` IDs (HTTP 422), use [`scripts/pass-cli-chezmoi.sh`](scripts/pass-cli-chezmoi.sh) as the `[protonPass] command` (falls back to `--vault-name` + `--item-id`). IDs live only in **local** `chezmoi.toml` / data — not in this repo.

---

## OpenCode desktop

- Avoid stale project paths that no longer exist (desktop apps may keep reloading them).
- Prefer opening a real folder, e.g. `~/Documents/Projects` or a specific repo.
- Obsidian Agent Client / cloud models generally **do not** require the OpenCode GUI to be open.

---

## Marked 2 (optional)

- Useful for Markdown **preview + print**.
- Float in AeroSpace if it is a utility window.
- Example:  
  `open -a "Marked 2" "$(chezmoi source-path)/docs/aerospace/SHORTCUTS.md"`

---

## Terminal + AeroSpace

- **Tabs** inside one Terminal window = **one** AeroSpace tile.
- **New windows** each get their own tile on the term workspace.
- Uneven columns: `aerospace balance-sizes` on the focused workspace.

---

## Related local stacks

Not part of this public repo. Keep separate project docs (and secrets) out of git or in **private** repositories.

---

## Quick health checks

```bash
aerospace --version
aerospace list-windows --all --format '%{app-name}|%{workspace}|%{window-layout}'

# if you maintain a precheck script:
# "$(chezmoi source-path)/scripts/topgrade-precheck.sh"

command -v opencode && opencode --version
```
