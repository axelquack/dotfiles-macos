# Changelog

This file is published with a public repository.

It must never contain IP addresses, hostnames, MAC addresses, internal paths, usernames, email addresses, vault IDs, credentials, or pane IDs.

Detailed private notes may go into `CHANGELOG.private.md`. That file is gitignored in a public repository. Do not commit it.

Newest first. Dates are Europe/Berlin, `YYYY-MM-DD`.

Use one heading per change: `## YYYY-MM-DD — title`. Under it, keep only the subsections that have items. End with a Why line.

## 2026-11-13 — Chezmoi follow-up after the host-name passes

### Changed

- `.chezmoiignore` skips the repo-standard files (`LICENSE`, `BUGFIXES.md`, `ROADMAP.md`, `TODO.md`, `HANDOFF.md`, `CHANGELOG.private.md`, `justfile`, `just/`). Before this, `chezmoi apply` would have copied them into the home directory.
- README Step 4e lists the local private data keys (`ssh_private_hosts` and the twelve `private_*` keys) by name. `docs/secondary.md` says the secondary Mac needs the same keys before any `chezmoi apply`.

### Removed

- On the primary Mac, the unused local chezmoi data key `vm_flatcar_ip` (no template reads it since the private overlay change) and the temporary local backup of the old `chezmoi.toml`. Neither was ever tracked.

### Notes

- On the primary Mac, `chezmoi diff` was the same before and after merging the two host-name passes, so the templates render with the local keys. The remaining diff is local drift in the AeroSpace, Grok, and zsh files that predates these changes. Nothing was applied; that is left for Axel.
- The secondary Mac was skipped because its macOS is not in use.

**Why:** Follow-up to the host-name passes, approved by Axel on 2026-11-13 (dotfiles-macos#4).

## 2026-11-13 — Remaining host names moved out of tracked files

### Changed

- The Mac notes are `docs/primary.md` and `docs/secondary.md`. The secondary bundle is `brewfile.secondary.extra`; the Ansible variable is `brewfile_secondary_extra`.
- Per-Mac Ansible vars moved from `host_vars/<alias>.yml` to `group_vars/primary.yml` and `group_vars/secondary.yml`. The real aliases stay in the gitignored `inventory.local.ini`, in the `primary` and `secondary` groups. `ansible-inventory --list` gives the same groups and host vars as before; only the renamed bundle variable differs.
- Docs, comments, `machine.md.example`, `.chezmoiignore`, the archived update log, and the scripts say "primary" and "secondary" (or `machine-<host>.md`) instead of real host names. The local model host is called the GPU host.
- Host labels in the Grok, AeroSpace, and Stream Deck templates come from local chezmoi data keys named `private_*`. Without them, generic labels are rendered. The Stream Deck action is now a template (`executable_ansible-brew.command.tmpl`) for that reason.
- On the primary Mac, every rendered file is byte-for-byte unchanged (`chezmoi archive` compared before and after; `chezmoi diff` output unchanged). Nothing was applied.

### Security

- Older commits still contain the previous names. History was not rewritten.

**Why:** This repository is public. Approved by Axel on 2026-11-13 as a second pass after the private overlay change.

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

## 2026-11-13 — Work tracking rule

### Changed

- AGENTS.md has a Work tracking section: open work goes on the owner's GitHub Project board, not into new TODO.md items.

**Why:** one board for all open work (Axel, 2026-11-13).

## 2026-11-13 — Pin GitHub Actions and add Dependabot

### Added

- `.github/dependabot.yml` for the `github-actions` ecosystem on a weekly schedule, so action SHA pins can be updated through Dependabot pull requests.

### Changed

- The gitleaks workflow pins `actions/checkout` to commit `d23441a48e516b6c34aea4fa41551a30e30af803` (v6.1.0) and `gitleaks/gitleaks-action` to commit `e0c47f4f8be36e29cdc102c57e68cb5cbf0e8d1e` (v3.0.0). Both SHAs were taken from the upstream tags. Top-level `permissions` stay `contents: read` and `pull-requests: write`.

### Security

- Workflows no longer follow floating action tags. Dependabot opens weekly pull requests when those pins need a bump.

**Why:** Pinning actions to a commit SHA, and keeping those pins current, reduces the risk of a tagged action changing under this public workflow.

## 2026-11-13 — Terraform from the HashiCorp tap

### Added

- `brewfile.home.machines` taps `hashicorp/tap` and installs `hashicorp/tap/terraform` for both Macs.
- A note in `docs/home-machines-apps.md`, the README brewfile row, and the Ansible brew step.

**Why:** homebrew-core no longer ships current Terraform after the Business Source License change. The official HashiCorp tap does. The inwx repository's `just validate` needs that binary. The primary Mac already has Terraform v1.17.2 from this tap.

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
