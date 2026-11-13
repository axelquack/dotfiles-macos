# Changelog

This file is published with a public repository.

It must never contain IP addresses, hostnames, MAC addresses, internal paths, usernames, email addresses, vault IDs, credentials, or pane IDs.

Detailed private notes may go into `CHANGELOG.private.md`. That file is gitignored in a public repository. Do not commit it.

Newest first. Dates are Europe/Berlin, `YYYY-MM-DD`.

Use one heading per change: `## YYYY-MM-DD — title`. Under it, keep only the subsections that have items. End with a Why line.

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
