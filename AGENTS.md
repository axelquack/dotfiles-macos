Herdr agent: Ines (Dotfiles) · macOS dotfiles and setup

Lead bot: Ines / Visibility: public / Default branch: master / Push: PR only

`CLAUDE.md` is a symlink to `AGENTS.md` (`ln -sf AGENTS.md CLAUDE.md`). Edit `AGENTS.md` only. Do not keep a second copy.

## Role

### Project

Personal macOS dotfiles and setup for a primary Mac and a secondary Mac: Zsh, Starship, AeroSpace, Homebrew, chezmoi, and Ansible. This repository is public. Secrets are materialized locally from Proton Pass. They are not stored here.

### This agent owns

- The committed dotfiles, Ansible playbook, public docs, and the repo-standard files in the file map.
- Keeping those docs aligned with the setup when a behaviour change lands in this repository.

### Out of scope & handoff

- Secrets, vault IDs, mailbox addresses, LAN addresses, and host inventories. Those live in Proton Pass (`pass-cli`) and in gitignored local maps.
- Sibling machine books. They are separate private repositories. Do not copy their inventory into this tree.
- Applying dotfiles to a live home directory, and any command against a host, device, VM, or container. `just/dotfiles.just` is preview only. Do not run `chezmoi apply` unless Axel asks.
- Other repositories. Do not edit agent-platform from this tree. Its handoff folder is handled separately.
- A LaunchAgent that auto-unlocks Pass or silently loads keys at boot.

## Start here

Read in this order:

1. `AGENTS.md` (this file).
2. `README.md`.
3. `BUGFIXES.md` and `SECURITY.md`.
4. `HANDOFF.md`, the last three entries in `CHANGELOG.md`, and `git log -5`. In this public repo `HANDOFF.md` is gitignored.
5. The current ticket, or else `TODO.md` and `ROADMAP.md`.
6. `docs/README.md`, then `docs/secrets-pass.md`, `docs/home-layout.md`, `docs/ssh-hosts.md`, and `docs/himalaya.md`.
7. Ansible: `ansible/README.md`, `ansible/inventory.ini`, and `ansible/setup-macos.yml`.
8. Private reinstall facts stay in gitignored `machine-*.md`. The committed templates are `machine.md.example` and `machine-ssh-hosts.md.example`.

## File map

| File | What it is for | Who updates it |
| --- | --- | --- |
| `README.md` | What the repo is, the status line, and the setup steps | The person who changes the project |
| `AGENTS.md` | Rules for the herdr agent | The owning agent, when the role or the rules change |
| `CLAUDE.md` | Symlink to `AGENTS.md`. Same text. No second copy | Nobody. Recreate it with `ln -sf AGENTS.md CLAUDE.md` |
| `CHANGELOG.md` | Public changelog, newest first, with a why. Sanitized. Starts 2026-11-12 | Whoever makes the change |
| `CHANGELOG.private.md` | Private notes. Gitignored. Never commit | The agent, on the local machine only |
| `ROADMAP.md` | Now, next, later, ideas, and done recently | The owning agent, when the plan moves |
| `TODO.md` | Interim task list until the agent-ops board exists | The agent who holds the work |
| `BUGFIXES.md` | Durable bug writeups, `BF-NNN` | Whoever records the fix |
| `HANDOFF.md` | Done, next, and open questions. Tracked in a private repo. Gitignored in a public repo | The agent, before stopping |
| `SECURITY.md` | Threat model, where secrets live, and leak response | The owning agent, when the threat model changes |
| `LICENSE` | PolyForm Noncommercial 1.0.0. Older published versions stay under Apache-2.0 | Axel |
| `justfile` | Repeatable recipes, including the secret check. Imports one snippet from `just/` | Whoever adds a recipe |
| `just/dotfiles.just` | Preview recipe. Do not apply dotfiles from it | Whoever adds a recipe |
| `docs/` | Longer docs. The index is `docs/README.md` | Whoever writes the doc |
| `docs/README.md` | Index of every docs page | Whoever adds or removes a docs page |
| `docs/aerospace/SHORTCUTS.md` | AeroSpace keybindings | Whoever changes the keybindings |
| `docs/aerospace/WORKSPACES.md` | Which apps land in which workspace | Whoever changes workspace rules |
| `docs/archive/UPDATES.md` | Archived dated update log. Not the living changelog | Nobody, unless Axel asks to correct the archive |
| `docs/bartender.md` | Menu-bar manager. The license stays off git | Whoever changes that app's setup |
| `docs/himalaya.md` | Himalaya and Mail.app client install. No real addresses | Whoever changes the mail client setup |
| `docs/home-layout.md` | What chezmoi owns under the home directory | Whoever changes that policy |
| `docs/home-machines-apps.md` | Shared app and Homebrew parity between the two Macs | Whoever changes the shared inventory |
| `docs/secrets-pass.md` | How Pass and chezmoi materialize secrets. No inventory | Whoever changes the secret flow |
| `docs/smb-unifi-nas.md` | SMB mount policy. The filled map stays gitignored | Whoever changes the mount helper |
| `docs/ssh-hosts.md` | SSH alias pattern. No address inventory | Whoever changes the SSH policy |
| `docs/stream-deck.md` | Stream Deck layout and what is not in git | Whoever changes the deck profile |
| `docs/<role>.md` | Public habit notes for one Mac: `docs/primary.md` and `docs/secondary.md`. No host names or inventory | Whoever changes that Mac's setup |
| `.env.example` | Setting names only. No secret values | Whoever adds a setting |
| `.githooks` | Git hooks. `pre-commit` runs the secret check | Whoever changes the check |
| `.githooks/pre-commit` | Runs `scripts/check-secrets.sh --staged` | Whoever changes the check |
| `scripts/check-secrets.sh` | Fails on a secret-shaped name, a gitleaks finding, a tracked private map, or a LAN address | Whoever changes the check |
| `scripts/lint.sh` | Shellcheck the scripts and hooks, then reject whitespace errors | Whoever changes the check |
| `scripts/docs-index.sh` | Refresh the generated list in `docs/README.md` | Whoever changes the index |
| `scripts/repo-audit.sh` | Report standard files that are missing | Whoever changes the standard |
| `scripts/audit-security.sh` | Shellcheck plus the npm OSV check for pinned packages | Whoever changes that audit |
| `scripts/bootstrap-secrets-from-pass.sh` | Materialize keys from Pass and apply the secret plumbing | Whoever changes bootstrap |
| `scripts/ensure-ssh-agent.sh` | Load the SSH agent from Pass when it is empty | Whoever changes that helper |
| `scripts/himalaya-accounts.example` | Example mail map. No real addresses | Whoever changes the mail flow |
| `scripts/himalaya-apply.py` | Write the local himalaya config from the gitignored map | Whoever changes the mail flow |
| `scripts/himalaya-setup.sh` | Install the himalaya TUI and optional Mail.app profile | Whoever changes the mail flow |
| `scripts/hue.example` | Example Hue map. The filled file is gitignored | Whoever changes the Hue action |
| `scripts/hue_scene.py` | Run a Hue scene from the local map | Whoever changes the Hue action |
| `scripts/install-npm-acp-agents.sh` | Install pinned ACP agent packages | Whoever bumps a pin |
| `scripts/install-npm-cli-tools.sh` | Install pinned npm CLI tools | Whoever bumps a pin |
| `scripts/mount-unifi-smb.sh` | Mount NAS shares from the gitignored host map | Whoever changes the mount helper |
| `scripts/pass-cli-chezmoi.sh` | Pass wrapper chezmoi calls when share IDs differ | Whoever changes that wrapper |
| `scripts/pass-env-map.example` | Example env map. The filled file is gitignored | Whoever changes bootstrap |
| `scripts/pass-import-ssh-keys.sh` | One-time import of local SSH keys into Pass | Whoever changes bootstrap |
| `scripts/pass-map-lib.sh` | Shared helpers for the Pass map scripts | Whoever changes bootstrap |
| `scripts/pass-ssh-key-map.example` | Example key-title map. The filled file is gitignored | Whoever changes bootstrap |
| `scripts/pass-write-zshrc-local.sh` | Write the gitignored local zsh file from Pass | Whoever changes bootstrap |
| `scripts/smb-hosts.example` | Example SMB map. The filled file is gitignored | Whoever changes the mount helper |
| `scripts/streamdeck-apply.sh` | Rebuild and reload the Stream Deck profile | Whoever changes the deck profile |
| `scripts/streamdeck_icon.swift` | Draw Stream Deck icons | Whoever changes the deck profile |
| `scripts/streamdeck_profile.py` | Describe the Stream Deck keys | Whoever changes the deck profile |
| `scripts/sync-goose-from-opencode.sh` | Copy local Goose credentials from OpenCode. Never prints them | Whoever changes that import |
| `scripts/topgrade-precheck.sh` | Pass session and SSH agent before topgrade. Pins Intel formulae | Whoever changes the update flow |
| `scripts/topgrade-wrap.sh` | Skip the Mac App Store step over SSH | Whoever changes the update flow |
| `.gitleaks.toml` | Gitleaks rules and the allowlist, including the license example line | Whoever changes the secret check |
| `.github/workflows/gitleaks.yml` | Gitleaks on push and pull_request | Whoever changes the CI check |
| `.gitignore` | Ignore rules, plus the public fragment for the handoff and the private changelog | Whoever changes ignore rules |
| `.chezmoiignore` | Files chezmoi must not copy into the home directory | Whoever changes what chezmoi manages |
| `ansible/README.md` | How to run the macOS playbook | Whoever changes the playbook |
| `ansible/ansible.cfg` | Ansible defaults for this repo | Whoever changes the playbook |
| `ansible/group_vars/all.yml` | Variables shared by both Macs | Whoever changes the playbook |
| `ansible/group_vars/primary.yml`, `ansible/group_vars/secondary.yml` | Per-role Ansible vars for the `primary` and `secondary` groups. No host names or addresses | Whoever changes that Mac's vars |
| `ansible/inventory.ini` | Public inventory template with placeholders. The real aliases live in gitignored `ansible/inventory.local.ini`, which `ansible.cfg` reads | Whoever changes the inventory |
| `ansible/setup-macos.yml` | Idempotent setup: packages, chezmoi, defaults, npm, mail clients | Whoever changes the playbook |
| `brewfile.home.machines` | Shared Homebrew bundle for both Macs | Whoever changes the bundle |
| `brewfile.secondary.extra` | Extra Homebrew bundle for the secondary Mac only (Syncthing) | Whoever changes the bundle |
| `brewfile.*.extra` | Extra Homebrew bundle for the secondary Mac only | Whoever changes that bundle |
| `dot_config/aerospace/aerospace.toml.tmpl` | AeroSpace config template | Whoever changes the window manager |
| `dot_config/aerospace/scripts/executable_center-floating-window.sh` | Center a floating window. Stream Deck calls it | Whoever changes that helper |
| `dot_config/goose/custom_providers/cohere_oai.json` | Goose provider catalog. No keys | Whoever changes the catalog |
| `dot_config/goose/custom_providers/oc_go.json` | Goose provider catalog. No keys | Whoever changes the catalog |
| `dot_config/goose/custom_providers/oc_go_qwen.json` | Goose provider catalog. No keys | Whoever changes the catalog |
| `dot_config/goose/custom_providers/oc_zen_claude.json` | Goose provider catalog. No keys | Whoever changes the catalog |
| `dot_config/goose/custom_providers/oc_zen_gpt.json` | Goose provider catalog. No keys | Whoever changes the catalog |
| `dot_config/starship.toml` | Starship prompt | Whoever changes the prompt |
| `dot_config/streamdeck/bin/executable_aerospace-reload.command` | Stream Deck action: reload AeroSpace | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_ansible-brew.command.tmpl` | Stream Deck action: Ansible brew tag. Its header comment comes from local chezmoi data | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_check-secrets.command` | Stream Deck action: secret check | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_chezmoi-apply.command` | Stream Deck action: chezmoi apply. Operator only | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_chezmoi-diff.command` | Stream Deck action: chezmoi diff | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_chezmoi-status.command` | Stream Deck action: chezmoi status | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_ensure-ssh-agent.command` | Stream Deck action: load the SSH agent | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_git-diff.command` | Stream Deck action: git diff | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_git-log.command` | Stream Deck action: git log | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_git-pull.command` | Stream Deck action: git pull | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_git-push.command` | Stream Deck action: git push | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_git-status.command` | Stream Deck action: git status | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_grok-tui.command` | Stream Deck action: open the Grok TUI | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_himalaya.command` | Stream Deck action: open Himalaya | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_hue-scene.sh` | Stream Deck action: Hue scene | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_lib.sh` | Shared helpers for the Stream Deck actions | Whoever changes those actions |
| `dot_config/streamdeck/bin/executable_mount-nas.command` | Stream Deck action: mount the NAS | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_open-dotfiles.command` | Stream Deck action: open this repo | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_pass-login.command` | Stream Deck action: Pass login. Does not store the password | Whoever changes that button |
| `dot_config/streamdeck/bin/executable_topgrade.command` | Stream Deck action: run topgrade | Whoever changes that button |
| `dot_config/topgrade.env.example` | Optional topgrade flag names. No passwords | Whoever changes the update flow |
| `dot_config/topgrade.toml` | Topgrade config. Some steps are excluded on purpose | Whoever changes the update flow |
| `dot_gemrc` | RubyGems defaults | Whoever changes that dotfile |
| `dot_gitconfig.tmpl` | Git config template. Name and email come from Pass at apply time | Whoever changes that template |
| `dot_gitignore_global` | Global gitignore chezmoi installs | Whoever changes that ignore file |
| `dot_grok/config.toml.tmpl` | Grok TUI policy. Tokens stay in the local env file | Whoever changes that policy |
| `dot_wgetrc` | wget defaults | Whoever changes that dotfile |
| `dot_zprofile` | Login-shell PATH and tool hooks. No secrets | Whoever changes the login shell |
| `dot_zshenv` | Environment for every zsh session | Whoever changes that env file |
| `dot_zshrc` | Interactive zsh. Sources the gitignored local file when it exists | Whoever changes the interactive shell |
| `macOS.sh` | macOS `defaults` settings. Operator runs it | Whoever changes those settings |
| `machine.md.example` | Template for a gitignored per-machine briefing | Whoever changes the template |
| `machine-ssh-hosts.md.example` | Template for the gitignored SSH inventory | Whoever changes the template |
| `private_dot_ssh/config.tmpl` | Base SSH config chezmoi installs. No host inventory. Private extra host blocks come from the local chezmoi data key `ssh_private_hosts` | Whoever changes the base SSH config |
| `private_dot_ssh/config.local.tmpl` | SSH host config rendered from the Pass note at apply time | Whoever changes that template |
| `templates/zshrc.local.pass.tmpl` | Template for the gitignored local zsh secrets file | Whoever changes bootstrap |

## Hard limits

- Secrets never go into git. No tokens, auth keys, `.env` files other than `.env.example`, `auth.json`, credential files, private keys, or session exports. Use a placeholder such as `<SECRET>` or `YOUR_VAULT_ID`.
- This repository is public. Never add IP addresses, hostnames, MAC addresses, internal paths, usernames, email addresses, vault IDs, credentials, or pane IDs.
- Do not commit `~/.zshrc.local`, filled inject templates, `*.mobileconfig`, `pass-*-map.local`, `himalaya-accounts.local`, `smb-hosts.local`, `hue.local`, or `machine-*.md`.
- Proton Pass via `pass-cli` stays the source of truth. Keys under `~/.ssh/` are a cache after bootstrap. Do not invent a Keychain-only workflow.
- Do not add a LaunchAgent that auto-unlocks Pass or silently loads keys at boot.
- You do not need `pass-cli login` or `scripts/ensure-ssh-agent.sh` before every git command in the same GUI session. You do need them again after reboot, when `ssh-add -l` shows no identities, or when `pass-cli vault list` fails.
- Over SSH the Keychain often will not unlock. Load keys in a GUI Terminal first, or use `ssh -A` from a machine that already has them. See `BUGFIXES.md`.
- On Intel, leave the topgrade formula pins in place. Do not store an Apple ID password in an env file. The zsh `topgrade` function skips `mas` when `SSH_CONNECTION` is set.
- App Store phone SIP passwords live in Pass. The phone app's Keychain is a local cache. Paste in the app so the app writes the Keychain. Never `security add-generic-password`.
- Do not dump `pass-cli item list` or key material into a file that will be committed.
- Ansible inventory uses SSH aliases that resolve through the Pass-rendered local SSH config. Do not put a LAN map in the public docs. Do not switch those aliases to mDNS-only names.
- When behaviour, paths, brew policy, or the Pass flow changes, update `README.md`, `ansible/README.md`, and the playbook tags in the same change.
- Himalaya config is generated locally. Do not commit real mailbox addresses. Mailbox lists belong in a private ops repo. This tree only installs the clients.
- Grok: keep the global permission mode on auto. A session approval is for local tool noise, not a way around the secret policy.
- `just/dotfiles.just` is preview only. Do not `chezmoi apply`, and do not run commands against hosts, devices, VMs, or containers, unless Axel asks.
- Do not commit `HANDOFF.md` or `CHANGELOG.private.md`.
- Verify an app's bundle ID before adding an AeroSpace rule. Cross-check app lists against `brewfile.home.machines` before editing a workspace or float rule.
- Stage by explicit path. Do not use `git add -A` or `git add .`.
- No force-push. A history rewrite needs Axel's approval.
- Mark anything you have not verified as **unverified**.

## Workflow

- Work through tickets and pull requests when the agent-ops board exists. Until then, track the task in `TODO.md`.
- One ticket at a time. Write a holder line on the ticket before you start, so two agents do not take the same ticket.
- Push for this repo is PR only. Open a pull request against `master`. Branch protection requires a pull request (0 approvals, administrators included) and blocks force-push and deletion.
- Before `topgrade`, the GUI session needs a Pass login if the vault is locked, then `scripts/ensure-ssh-agent.sh`.
- Packages and templates are applied with Ansible from `ansible/`, limited to an inventory alias, only when Axel asks. Tags include `brew`, `chezmoi`, `npm`, `macos_defaults`, `himalaya`, and `mailapp`.
- Stage by explicit path. Do not use `git add -A` or `git add .`.
- No force-push. A history rewrite needs Axel's approval.
- If a permission question or a blocker cannot be resolved, stop and say so.

## Documentation, commit & push

Standing rule from Axel (2026-11-12), for every Grok bot and herdr agent working in this repo:

- Document every change in this project: README, `docs/`, and the changelog (`CHANGELOG.md` or `docs/changelog.md`), with date and what/why.
- Commit with a clear message, then push to the repo's existing remote, public or private, after the secret check.
- Before each commit, run a secret check: `git diff --cached --name-only` and `git diff --cached`. Never commit `.env*`, keys, tokens, `auth.json`, credentials, session exports, or `*.bak*` files. If one is staged, unstage it and add it to `.gitignore`.
- Public repos (`gh repo view --json visibility`): be extra strict. Before pushing, review the full diff being pushed (`git diff @{u}..HEAD`) for secrets, tokens, private IPs and hostnames the repo does not already contain, personal data, and session exports. If anything looks sensitive, do not push; report it to Axel.
- If the repo has no remote, commit locally and report that.
- Commit only your own change; do not sweep in someone else's uncommitted work.

Confirmed by Axel (2026-11-14) for every Grok Bot and Herdr agent:

- Document each change in this repo's own files (README, `docs/`, changelog). A memory note, chat message, or handoff outside the repo does not count.
- Then commit and push to the existing remote after the secret check. Stage by explicit path only (no `git add -A` or `git add .`).
- Force-pushes and history rewrites need Axel's explicit approval.

## Secrets

Secrets live in Proton Pass, in `~/.grok/.env`, or on Axel's secure secret cards. They do not live in this repository.

| Piece | Persistence |
| --- | --- |
| Keys and host config on disk after chezmoi and bootstrap | Until reinstall or a new bootstrap |
| `pass-cli login` | Until logout, reboot, or Keychain lock |
| Identities loaded into `ssh-agent` | Until the agent is emptied |

Bootstrap is `scripts/bootstrap-secrets-from-pass.sh`. It needs the gitignored maps and a Pass login.

Before every commit, run:

```
git diff --cached --name-only
git diff --cached
scripts/check-secrets.sh --staged
```

The `pre-commit` hook runs `scripts/check-secrets.sh --staged` after `just setup`.

If a secret was committed: rotate it first, tell Axel, and do not rewrite history unless Axel approves the force-push.

## Handoff

Before you stop, write what you did, what is next, and the open questions.

In a private repository, update `HANDOFF.md` and keep it tracked.

In a public repository, `HANDOFF.md` is gitignored. Write the note in the agent-platform repository at `handoffs/dotfiles-macos.md`.

## Work tracking

Rule from the owner (2026-11-13): all open work goes on the owner's private GitHub Project board, not into new TODO.md items or chat-only lists.

1. File an issue in this repo (or a draft item on the board if no repo fits) and add it to the board with `gh project item-add` (find the board with `gh project list --owner @me`).
2. Link each pull request to its issue (`Closes #<n>` in the PR body) and add the PR to the board too.
3. Set **Status** (Inbox / Waiting on Axel / In progress / Done) and **Owner** (your agent or bot name; if your name is not an Owner option yet, pick your lead bot and write your name in the item).
4. Anything that needs the owner gets Status "Waiting on Axel" and the `waiting-on-axel` label. Ping the owner only if it is urgent; the morning digest covers the rest.
5. Use `gh` on the owner's machine (it has the `project` scope). The GitHub connector cannot reach personal Projects.
6. Existing TODO.md files stay for now; do not add new items to them.
