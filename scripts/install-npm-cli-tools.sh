#!/bin/bash
set -euo pipefail
# Standalone AI CLI tools (not ACP/Obsidian specific)
# Run after: fnm is installed and a Node.js version is active

eval "$(fnm env)"

npm install -g @google/gemini-cli@0.37.1                       # Google's Gemini CLI
