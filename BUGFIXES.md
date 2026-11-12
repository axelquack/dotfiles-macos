# Bugfixes

Durable bug writeups. One heading per bug: `BF-NNN`. Keep the number. Do not reuse it.

These limits were already true in this repository. They were recorded here on 2026-11-12 so the next agent does not "fix" them by weakening the secret rules.

## BF-001 — Pass Keychain is unavailable over SSH

- Status: open
- Date: 2026-11-12
- Symptom: Over SSH, `pass-cli` cannot unlock the Keychain. A login shell on that Mac may also see an empty `ssh-agent` after reboot.
- Cause: The Keychain unlock needs the GUI session. A remote shell does not get it.
- Policy: Load keys in a GUI Terminal with `scripts/ensure-ssh-agent.sh`, or use `ssh -A` from a machine that already has them. Do not add a LaunchAgent that unlocks Pass or loads keys at boot. `scripts/topgrade-precheck.sh` soft-fails the Keychain over SSH and still tries to attach an agent.

## BF-002 — Mac App Store CLI prompts over SSH

- Status: open
- Date: 2026-11-12
- Symptom: `mas` asks for an Apple ID password when `topgrade` runs over SSH.
- Cause: `mas signin` is gone. The CLI cannot take the password from an environment file.
- Policy: `scripts/topgrade-wrap.sh` skips `mas` when `SSH_CONNECTION` is set. Do not put the Apple ID password in `~/.config/topgrade.env`. Upgrade the App Store apps from a GUI Terminal.

## BF-003 — Some Homebrew formulae have no Intel bottles

- Status: open
- Date: 2026-11-12
- Symptom: On Intel (`x86_64`), `topgrade` would compile outdated formulae for a long time.
- Cause: Homebrew dropped bottles for those formulae on that architecture.
- Policy: `scripts/topgrade-precheck.sh` pins those formulae on Intel. Do not unpin them unless someone is ready to compile.

## BF-004 — pass-cli treats a loose session directory as logged out

- Status: open
- Date: 2026-11-12
- Symptom: `scripts/topgrade-precheck.sh` says pass-cli is not logged in even after a successful login.
- Cause: pass-cli 2.5.0 requires the session directory under Application Support to be mode `700`.
- Policy: Fix the directory mode. Do not bypass the precheck, and do not store the Pass password in the repo.
