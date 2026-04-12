#!/bin/bash
# Standalone AI CLI tools (not ACP/Obsidian specific)
# Run after: fnm is installed and a Node.js version is active

eval "$(fnm env)"

npm install -g @anthropic-ai/claude-code               # Anthropic's Claude Code CLI
npm install -g @google/gemini-cli                      # Google's Gemini CLI
