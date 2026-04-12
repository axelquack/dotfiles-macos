#!/bin/bash
set -euo pipefail
# Standalone AI CLI tools (not ACP/Obsidian specific)
# Run after: fnm is installed and a Node.js version is active

eval "$(fnm env)"

npm install -g @anthropic-ai/claude-code@2.1.104               # Anthropic's Claude Code CLI
npm install -g @google/gemini-cli@0.37.1                       # Google's Gemini CLI
