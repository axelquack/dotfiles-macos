# Bartender 6 (menu bar)

Shared menu-bar manager for both home Macs. Keep a few icons next to the clock; fold the rest and click Bartender to unfold.

**Public repo:** never commit the license name or key. Store them in Proton Pass (or the vendor email). Retrieve at [macbartender.com support](https://www.macbartender.com/Bartender6/support/).

## Why this app

| Host | OS | Chip |
|------|----|------|
| Primary | Tahoe 26 | Apple Silicon |
| Secondary | Sequoia 15 | Intel |

Bartender 6 is the one product that officially spans **Sequoia + Tahoe** (Intel and Apple Silicon). Ice installs on both but is not maintained for Tahoe; Thaw is the Ice fork and requires macOS ≥ 26, so it cannot go in the shared brewfile. Ice / Thaw / Hidden Bar are **not** in SoT — do not add them back.

Bundle ID: `com.surteesstudios.Bartender`. App path: `/Applications/Bartender 6.app`.

## Install

Cask `bartender` in [`brewfile.home.machines`](../brewfile.home.machines).

```bash
brew bundle --file="$(chezmoi source-path)/brewfile.home.machines"
# or just:
brew install --cask bartender
open "/Applications/Bartender 6.app"
```

Ansible `--tags brew` also installs it. One license covers every Mac you own and are the main user of — register the app **on each host** (the key is not in chezmoi).

## License (local only)

1. Bartender menu → **License** / **Register**.
2. License name = the name on the receipt, **or** the purchase email if bought after about August 2025.
3. Paste the **full** key (5-character groups). Do not put it in this repo, brewfile comments, or `machine-*.md` if that file is ever copied around carelessly.

A **Bartender 5** key does not always unlock Bartender 6. If the app rejects it, use the [upgrade page](https://www.macbartender.com/Bartender6/upgrade/): Bartender 5 bought in **2025** is a free Bartender 6 upgrade; older keys are a discount. Then register the **Bartender 6** key it emails.

Lookup if lost: [license retrieve](https://www.macbartender.com/Bartender6/support/) or FastSpring order mail.

## Permissions

On first run, grant:

- **Accessibility** (required to move/hide menu bar items)
- **Screen Recording** (appearance / some layout features)

System Settings → Privacy & Security. Re-launch Bartender after granting.

Enable **Launch at login** in Bartender’s settings.

## Layout

Arrange icons in Bartender’s layout pane: always-visible (clock side), hidden until unfold, optionally always-hidden. This is per-Mac and stays in the app’s preferences — not git.
