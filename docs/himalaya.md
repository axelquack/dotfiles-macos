# Himalaya + Mail.app IMAP (public)

**This repository is public.** Mailbox addresses, IMAP passwords, and generated profiles stay **off git**.

Installs [himalaya](https://github.com/pimalaya/himalaya) (CLI) and [himalaya-tui](https://github.com/pimalaya/himalaya-tui) on the home Macs, and can generate an unsigned Apple Mail IMAP profile for extra (non-iCloud) `mail@` accounts.

Mailbox inventory and MX live in a **private** ops repo. This tree only installs clients and materializes local config from Proton Pass.

## What is committed vs local

| Piece | Where |
|-------|--------|
| Homebrew formula `himalaya` | `brewfile.home.machines` |
| himalaya-tui (not bottled) | `scripts/himalaya-setup.sh --tui` (cargo git, pinned rev) |
| Account map (addresses + Pass **titles**) | gitignored `scripts/himalaya-accounts.local` (copy [himalaya-accounts.example](../scripts/himalaya-accounts.example)) |
| `~/.config/himalaya/config.toml` | generated locally (`0600`); `password.command` → `pass-cli`, never `password.raw` |
| Mail.app `.mobileconfig` | generated locally (`0600`); passwords injected at apply time; **delete after install** (`rm -P`) |

Suggested Pass title patterns (customize privately):

| Kind | Title pattern |
|------|----------------|
| Hosted IMAP mailbox | `{addr} (INWX Froxlor)` |
| iCloud app-specific password | `Himalaya (Apple)` |
| Gmail app password | `Himalaya (Google Mail)` |

Do **not** use the Google account login item for IMAP. Gmail app passwords need 2-Step Verification.

## Apply

```bash
# Packages (himalaya CLI)
cd ansible && ansible-playbook setup-macos.yml --limit haumea --tags brew

# TUI + config.toml (skips config if the local map is missing)
ansible-playbook setup-macos.yml --limit haumea --tags himalaya
# secondary: --limit moon

# Or without Ansible:
./scripts/himalaya-setup.sh --tui
```

Copy the map once per clone (not via git):

```bash
cp scripts/himalaya-accounts.example scripts/himalaya-accounts.local
# edit addresses + Pass titles; keep gitignored
```

`pass-cli` over SSH often fails with Keychain **-25308**. Generate Mail.app profiles and run `himalaya account check` in a **GUI Terminal** on that Mac.

## Mail.app extra IMAP (`mail@` only)

Unsigned `com.apple.mail.managed` profile. `profiles` has **no** install verb on current macOS — open the file, then **System Settings → General → Device Management → Install**.

```bash
# GUI Terminal, pass-cli already logged in
./scripts/himalaya-setup.sh --mailapp

# Ansible (off by default — needs GUI Pass + a click in System Settings)
cd ansible && ansible-playbook setup-macos.yml --limit haumea --tags mailapp
```

Only map rows with `mailapp=true` are included (the extra IMAP `mail@` boxes, not `spam@` / `admin@`, not iCloud, not Gmail). iCloud custom-domain addresses are identities on the Apple ID mailbox — signing into iCloud Mail is enough; do not add one IMAP account per iCloud domain.

After Mail.app authenticates: `rm -P` the `.mobileconfig` (it contained passwords). Do not leave it in Downloads or the git clone.

iPhone is **not** automated here.

## Behaviour notes

- Himalaya v2 config is first of `$XDG_CONFIG_HOME/himalaya/config.toml`, `~/.config/himalaya/config.toml`.
- Default account is the map row with `default=true` (iCloud in the usual private map).
- TUI is **one IMAP login per session** (`himalaya-tui -a name`). No unified inbox.
- Bare `himalaya` (no subcommand) starts the wizard — do not run it against the live file unless you mean to.
- Do not wire himalaya-mcp, Fastmail MCP, or IMAP inside `~/.grok/config.toml` unless asked.
- Do not auto-send mail unless explicitly asked.

## Related

- Ansible tags: [ansible/README.md](../ansible/README.md)
- Secrets: [secrets-pass.md](./secrets-pass.md)
- Host notes: [haumea.md](./haumea.md) · [moon.md](./moon.md)
