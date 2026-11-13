# Changelog

This file is published with a public repository.

It must never contain IP addresses, hostnames, MAC addresses, internal paths, usernames, email addresses, vault IDs, credentials, or pane IDs.

Detailed private notes may go into `CHANGELOG.private.md`. That file is gitignored in a public repository. Do not commit it.

Newest first. Dates are Europe/Berlin, `YYYY-MM-DD`.

Use one heading per change: `## YYYY-MM-DD — title`. Under it, keep only the subsections that have items. End with a Why line.

## 2026-11-13 — Host names moved into the private overlays

### Changed

- `private_dot_ssh/config.tmpl` no longer names a host. The extra VM host block is rendered verbatim from the local chezmoi data key `ssh_private_hosts` in the untracked `chezmoi.toml`. The rendered `~/.ssh/config` on the primary Mac is byte-for-byte unchanged (checked with `chezmoi cat`).
- `ansible/ansible.cfg` reads the gitignored `ansible/inventory.local.ini`. The tracked `ansible/inventory.ini` is now a template with placeholder aliases. `ansible-inventory --list` resolves the same hosts and groups as before.
- `ansible/README.md` uses the group names `primary` and `secondary` in its commands and explains the private inventory.
- `docs/ssh-hosts.md` and `machine-ssh-hosts.md.example` use generic placeholders (`host1`, `node1.<site>.local`, `id_ed25519_<label>`) instead of real host names. `docs/ssh-hosts.md` documents the `ssh_private_hosts` key.

### Security

- `.gitignore` covers `inventory.local.ini`.
- Older commits still contain the previous host names. History was not rewritten.

**Why:** This repository is public. Real host names and the private inventory belong in the gitignored overlays, not in tracked files. Approved by Axel on 2026-11-13.

## 2026-11-12 — Public repo standard

### Added

- The repo-standard file set: `AGENTS.md` skeleton, `CLAUDE.md` symlink, this changelog, `ROADMAP.md`, `TODO.md`, `BUGFIXES.md`, `SECURITY.md`, `justfile`, `just/dotfiles.just`, `.githooks/pre-commit`, `scripts/check-secrets.sh`, `scripts/lint.sh`, `scripts/docs-index.sh`, `scripts/repo-audit.sh`, `.gitleaks.toml`, `.github/workflows/gitleaks.yml`, `.env.example` (names only), and `docs/README.md`.
- Public gitignore rules so `HANDOFF.md` and `CHANGELOG.private.md` stay untracked.

### Changed

- `LICENSE` is PolyForm Noncommercial 1.0.0. Versions published before this commit remain available under Apache-2.0. The previous Apache text was `LICENSE.md`.
- `README.md` follows the repo-standard status block and no longer repeats machine names.
- `AGENTS.md` follows the skeleton. The Herdr agent line is Ines (Dotfiles) · macOS dotfiles and setup.
- `CLAUDE.md` is a committed symlink to `AGENTS.md`. It is no longer a gitignored local stub.
- The dated update log moved from `docs/UPDATES.md` to `docs/archive/UPDATES.md`.
- This changelog starts here. Older private notes stay in gitignored `CHANGELOG.private.md` and are not copied into this file.

### Security

- `pre-commit` runs `scripts/check-secrets.sh --staged` after `just setup`.
- GitHub Actions runs gitleaks on push and pull_request.
- Branch protection on master (set by Shepherd on GitHub): pull request required (0 approvals, administrators included), force-push and deletion blocked. From now on changes reach the default branch through a pull request.

**Why:** This public repository needs one license, a secret check, and a file map before further edits. A private changelog must not be published.
