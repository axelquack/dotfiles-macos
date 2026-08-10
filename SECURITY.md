# Security — public repository

**This repo is public on GitHub.** Assume every commit is world-readable forever.

## Never commit

| Class | Examples |
|-------|----------|
| SSH private keys | any `BEGIN OPENSSH PRIVATE KEY`, key files under `.ssh/` |
| Full SSH public key lines | `ssh-ed25519 AAAA…` |
| API keys / tokens / passwords | OpenRouter, Anthropic, RA, etc. |
| Proton Pass vault/share/**item IDs** | `~/.config/chezmoi/chezmoi.toml` |
| Generated secret files | `~/.zshrc.local`, filled inject templates |
| Private host inventory | LAN IPs, MACs, full SSH host lists, serials |
| Private agent briefs | `machine-*.md` (gitignored) |
| Real Pass title inventory with IPs | use gitignored `pass-*-map.local` only |

## Allowed in public docs

| Class | Notes |
|-------|--------|
| Tool names and install steps | brew, chezmoi, pass-cli |
| Placeholder config | `YOUR_VAULT_ID`, example map lines without real hosts |
| Host **role** names | primary/secondary, “haumea”/“moon” as role labels already in public docs |
| Patterns | “SSH Host Config” as a **suggested** Pass note title |

## Source of truth

| Piece | Where |
|-------|--------|
| Secrets | Proton Pass via **pass-cli** |
| Dotfile materialization | **chezmoi** + bootstrap scripts |
| Per-machine private facts | gitignored `machine-*.md` |

Guide: [`docs/secrets-pass.md`](docs/secrets-pass.md).

## Pre-push checks

```bash
./scripts/check-secrets.sh
./scripts/check-secrets.sh --history   # after any secret incident
# optional: gitleaks detect --source . --config .gitleaks.toml
```

`scripts/audit-security.sh` covers shellcheck + npm OSV (also run before script commits).  
Install scanner: `brew install gitleaks` (listed in `brewfile.home.machines`).

## History

If a secret or LAN inventory was ever committed:

1. **Do not push** that commit.  
2. Soft-reset / squash / filter-repo before publishing.  
3. Rotate any exposed credentials.

Unpushed history can be rewritten; **pushed** history needs rotation + purge.

## Operator checklist

- [ ] No `pass-*-map.local` staged  
- [ ] No `machine-*.md` staged  
- [ ] No vault IDs or key material in diff  
- [ ] `./scripts/check-secrets.sh` PASS  
