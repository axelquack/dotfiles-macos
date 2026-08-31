# Secrets: Proton Pass + chezmoi (public-repo guide)

This repository is **public**. It documents **patterns and scripts**, not your private inventory.

**Goal:** Proton Pass is the only vault. Chezmoi and scripts **materialize** secrets onto disk.  
CLI name: **`pass-cli`** (not `proton-cli`).

---

## Architecture

```text
Proton Pass (your vault — never committed)
  ├── SSH Host Config (note)     ──chezmoi──►  ~/.ssh/config.local
  ├── Git Identity (login)       ──chezmoi──►  ~/.gitconfig name/email
  ├── SSH key items (ssh_key)    ──bootstrap──► ~/.ssh/id_*
  └── API logins                 ──script──►   ~/.zshrc.local

Local only (never git)
  ├── pass-cli login session
  ├── ~/.config/chezmoi/chezmoi.toml   (vault + item IDs)
  ├── scripts/pass-ssh-key-map.local   (basename → Pass title)
  └── scripts/pass-env-map.local       (Pass title → ENV var)
```

Disk files after bootstrap are a **cache**. Re-run scripts after reinstall.

---

## What this public repo must not contain

| Forbidden in git | Where it belongs |
|------------------|------------------|
| Private keys, full public key lines | Pass + `~/.ssh/` |
| Vault / share / item **IDs** | `~/.config/chezmoi/chezmoi.toml` |
| LAN IPs, MACs, full host inventories | Private notes / `machine-*.md` / `machine-ssh-hosts.md` (gitignored) |
| Your Pass item title inventory with IPs | `pass-ssh-key-map.local` (gitignored) |
| Generated `~/.zshrc.local` | Home directory only |
| Grok LAN MCP URLs | Local `chezmoi.toml` data (`grok_homeassistant_mcp_url`, `grok_agentzero_mcp_url`) — optional; omit on hosts without those services |
| UniFi NAS SMB IPs | gitignored `scripts/smb-hosts.local` (example committed) |

Committed **examples** use placeholders only (`pass-ssh-key-map.example`, `pass-env-map.example`).

---

## Pass item conventions (patterns, not your list)

Suggested naming (customize privately):

| Pattern | Type | Purpose |
|---------|------|---------|
| **SSH Host Config** | note | chezmoi → `config.local` |
| **Git Identity** | login | git name/email fields |
| **SSH Key — \<label\>** | ssh_key | import via `pass-cli item create ssh-key import` |
| API service logins | login | fields → env via `pass-env-map.local` |

Prefer **labels without LAN IPs** in Pass titles when possible (e.g. `SSH Key — github`, not `SSH Key — host (192.168…)`). Existing IP-suffixed titles still work if listed only in your local map.

### SSH Host Config body (dual alias + IP)

Every fleet host in the Pass note should use **short name + `.local`** (and site FQDNs if any) **and** a reserved **`HostName` IPv4**. Do not rely on mDNS alone — travel-router / cross-subnet admin breaks `*.local` while unicast still works.

Public pattern and test recipe: **[ssh-hosts.md](./ssh-hosts.md)**.  
Private filled inventory (this Mac only): **`machine-ssh-hosts.md`** (gitignored; start from `machine-ssh-hosts.md.example`).

---

## One-time setup on a primary Mac

```bash
pass-cli login
cp scripts/pass-ssh-key-map.example scripts/pass-ssh-key-map.local
# Edit pass-ssh-key-map.local: map each ~/.ssh/id_* basename to a Pass title

./scripts/pass-import-ssh-keys.sh --dry-run
./scripts/pass-import-ssh-keys.sh
```

Import uses:

```bash
pass-cli item create ssh-key import \
  --vault-name Personal \
  --title "SSH Key — github" \
  --from-private-key ~/.ssh/id_ed25519_github
```

If a key file is passphrase-encrypted, re-import with `--password` if pass-cli warns the key was stored locked.

---

## New machine / reinstall

```bash
brew install pass-cli chezmoi
pass-cli login

# README Step 4: create ~/.config/chezmoi/chezmoi.toml (IDs from pass-cli list)
cp scripts/pass-ssh-key-map.example scripts/pass-ssh-key-map.local
# edit map to match your Pass titles

./scripts/bootstrap-secrets-from-pass.sh --agent-load --with-zshrc-local
```

**Keys only:**

```bash
./scripts/bootstrap-secrets-from-pass.sh --keys-only
```

**Shell API keys only:**

```bash
cp scripts/pass-env-map.example scripts/pass-env-map.local
# edit titles/fields
./scripts/pass-write-zshrc-local.sh
```

---

## Day-to-day

| Task | Command |
|------|---------|
| Edit SSH hosts | Edit Pass **SSH Host Config** → `chezmoi apply` → refresh private `machine-ssh-hosts.md` if needed |
| Ensure SSH agent (preferred) | `./scripts/ensure-ssh-agent.sh` — idempotent; uses `pass-cli ssh-agent load` when empty |
| Agent load keys (manual) | `pass-cli ssh-agent load --vault-name Personal` |
| Before topgrade / cold session | `pass-cli login` in a **GUI** Terminal if needed, then ensure-ssh-agent |
| SSH alias policy | [ssh-hosts.md](./ssh-hosts.md) (public) · `machine-ssh-hosts.md` (private IPs) |

**Session lifetime:** `pass-cli login` and agent load are **not** permanent. Same login session usually keeps working; after reboot / logout / empty `ssh-add -l`, re-login (if needed) and run `ensure-ssh-agent.sh`. Do not install a LaunchAgent that auto-unlocks Pass (keeps intentional GUI unlock). See [AGENTS.md](../AGENTS.md) § Pass session + SSH agent.

**Do not** hand-edit `~/.ssh/config.local` long-term — chezmoi overwrites it.

### Grok TUI (`~/.grok/config.toml`)

Policy file is chezmoi-managed (`dot_grok/config.toml.tmpl`). MCP **tokens** stay in local `~/.grok/.env` (never git). Optional LAN MCP base URLs belong in **local** `~/.config/chezmoi/chezmoi.toml` `[data]`:

```toml
grok_homeassistant_mcp_url = "http://HOMEASSISTANT_HOST/api/mcp"
grok_agentzero_mcp_url     = "http://AGENTZERO_HOST/mcp/t-${AGENTZERO_MCP_TOKEN}/http/"
```

Omit both keys on a machine that does not run those servers. Auth for Grok itself is `grok login` (OAuth), not `XAI_API_KEY`.

### Optional `pass-cli inject`

```text
{{ pass://VaultName/ItemTitle/field }}
```

URL-encode awkward titles. Prefer `pass-write-zshrc-local.sh` + local map over committing personal inject templates.

---

## Scripts

| Script | Purpose |
|--------|---------|
| `pass-import-ssh-keys.sh` | Local `~/.ssh` → Pass (map file required) |
| `bootstrap-secrets-from-pass.sh` | Pass → disk keys + chezmoi |
| `pass-write-zshrc-local.sh` | Pass → `~/.zshrc.local` (env map required) |
| `pass-cli-chezmoi.sh` | chezmoi wrapper when PAT share IDs differ |
| `ensure-ssh-agent.sh` | Idempotent `pass-cli ssh-agent load` when agent empty |
| `check-secrets.sh` | Pre-push scan for this public repo |
| `mount-unifi-smb.sh` | SMB mounts; IPs from gitignored `smb-hosts.local` |

---

## Related

- [AGENTS.md](../AGENTS.md) — public agent instructions  
- [SECURITY.md](../SECURITY.md) — what never to commit  
- [machine.md.example](../machine.md.example) — private per-host brief (gitignored when filled)  
