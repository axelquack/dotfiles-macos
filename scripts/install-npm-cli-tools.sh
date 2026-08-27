#!/bin/bash
set -euo pipefail
# Standalone AI CLI tools (not ACP/Obsidian specific)
# Run after: fnm is installed and a Node.js version is active

eval "$(fnm env)"

# Consumer / Code Assist-for-individuals login died 2026-06-18 (migrate to brew cask antigravity-cli / agy).
# Paid Gemini API keys still work with this CLI. Do not use it as the Obsidian agent for Google-account login.
npm install -g @google/gemini-cli@0.37.1                       # Gemini CLI (API-key path only)
