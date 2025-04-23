# My macOS Dotfiles

Welcome to my personal collection of dotfiles and setup scripts for macOS, available at [github.com/axelquack/dotfiles-macos](https://github.com/axelquack/dotfiles-macos). This repository contains configurations for Zsh, Starship, various development tools, and system preferences, aiming for a productive command-line environment.

## Overview

This setup utilizes:

*   **Shell:** Zsh (configured via `.zshrc` and `.zshenv`)
*   **Prompt:** Starship (`starship.toml`)
*   **History:** Atuin (`atuin init zsh` in `.zshrc`)
*   **Package Manager:** Homebrew (managed via `brewfile.private`)
*   **Updating:** Topgrade (`topgrade.toml`)
*   **Language Version Managers:**
    *   Python: `pyenv` + `uv`
    *   Ruby: `rbenv` + `ruby-build`
    *   Node.js: `fnm`
*   **macOS Configuration:** Script using `defaults write` (`macos.sh`)
*   **Other Tools:** `eza`, `btop`, `wget`, `rmtrash`, `colima`/`docker`, etc.

## Prerequisites

*   macOS (Scripts are tailored for it)
*   Optional but Recommended: Git (for cloning this repository)

## Setup Instructions

1.  **Clone the Repository:** It's best to clone this repository to your local machine first, for example, into `~/dotfiles`:
    ```bash
    git clone https://github.com/axelquack/dotfiles-macos.git ~/dotfiles
    cd ~/dotfiles
    ```

2.  **Review Configuration:** Look through `brewfile.private` and `macos.sh` to ensure you agree with the software being installed and the system settings being applied. Comment out or remove anything you don't want.

3.  **Run Bootstrap Script:** This script handles prerequisites (Xcode Command Line Tools check, Homebrew install) and then installs applications listed in `brewfile.private`.
    ```bash
    ./bootstrap.sh
    ```
    *   *Note:* The script expects `brewfile.private` to be in the same directory it's run from (`~/dotfiles/brewfile.private` based on the clone path above). Adjust the `BREWFILE_PATH` inside `bootstrap.sh` if needed.
    *   You might be prompted for your password for Homebrew or MAS installs. Ensure you're logged into the App Store if installing MAS apps.

4.  **Apply macOS Settings:** The `macos.sh` script applies various system and application preferences using `defaults write`. Run it separately:
    ```bash
    ./macos.sh
    ```
    *   This script requires `sudo` privileges for some commands.
    *   Some changes may require a logout/restart to take full effect.

5.  **Link Dotfiles:** Manually link or copy the configuration files from this repository to their correct locations in your home directory (or use a dotfile manager like `stow`).
    *   `.zshrc` -> `~/.zshrc`
    *   `.zshenv` -> `~/.zshenv`
    *   `.wgetrc` -> `~/.wgetrc`
    *   `.gitignore` -> Copy contents to `~/.gitignore_global` or project `.gitignore`.
    *   `.gemrc` -> `~/.gemrc`
    *   `starship.toml` -> `~/.config/starship.toml`
    *   `topgrade.toml` -> `~/.config/topgrade.toml`
    *   *(Vim files need review - see below)*

6.  **Restart Terminal:** Open a new terminal window or tab for all Zsh settings, PATH changes, and tool initializations to take effect.

## Included Configuration Files

*   **`.zshrc`:** Main configuration file for **interactive** Zsh sessions. Sets up PATH, initializes version managers (`pyenv`, `rbenv`, `fnm`), Starship prompt, Atuin history, aliases, and functions.
*   **`.zshenv`:** Sourced for **all** Zsh sessions. Used for setting essential environment variables like `$EDITOR` and `$PAGER`.
*   **`starship.toml`:** Configuration for the Starship cross-shell prompt. Place in `~/.config/starship.toml`.
*   **`topgrade.toml`:** Configuration for the Topgrade universal updater tool. Place in `~/.config/topgrade.toml`.
*   **`.wgetrc`:** Default configuration settings for the `wget` download utility.
*   **`.gitignore`:** A comprehensive global Git ignore file. Can be used as `~/.gitignore_global` or copied/adapted for individual projects.
*   **`.gemrc`:** Configuration file for RubyGems (e.g., disabling documentation install).
*   **`.vimrcAfter.vimrc`, `.vimrcBefore.vimrc`:** *(Under Review)* Vim configuration files. These likely need updating or consolidation into a modern Vim/Neovim setup.

## Installation & Bootstrap

*   **`bootstrap.sh`:** Shell script to automate initial setup: checks/installs Xcode Command Line Tools, Homebrew, and then runs `brew bundle`.
*   **`brewfile.private`:** Defines all applications and tools to be installed via Homebrew (using `brew`, `cask`, and `mas` commands). Used by `bootstrap.sh`.

## macOS Configuration

*   **`macos.sh`:** Applies various macOS system preferences and application settings using `defaults write` and other commands. Run manually after `bootstrap.sh`.

## Updating Tools

*   Run `topgrade` regularly. It uses the `topgrade.toml` configuration to update Homebrew packages, MAS apps, macOS system updates, and potentially other configured items.
*   Language versions installed via `pyenv`, `rbenv`, `fnm` are generally updated manually as needed (e.g., `pyenv install 3.x.y`, `rbenv install 3.x.x`).

## Manual Steps & Notes

*   **Docker/Colima:** This setup uses Colima for a CLI-based Docker environment. Remember to run `colima start` before using Docker commands and `colima stop` when finished.
*   **Vim Configuration:** The included Vim files (`.vimrcBefore`, `.vimrcAfter`) are noted as potentially outdated or needing review. They might need to be replaced with a modern Vim/Neovim setup using a plugin manager.

## License

The code and configuration files in this repository are licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

## Feedback

If you have any questions or feedback (especially regarding improvements or potential issues), please feel free to open an issue on the [GitHub repository](https://github.com/axelquack/dotfiles-macos) or contact the repository owner.
