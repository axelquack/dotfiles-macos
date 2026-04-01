#!/bin/bash
# Global npm packages to install via fnm
# Run after: fnm is installed and configured in shell

eval "$(fnm env)"

# AI CLI Tools
npm install -g @google/gemini-cli                  # Google's Gemini CLI
npm install -g @zed-industries/claude-agent-acp    # Zed's Claude agent
npm install -g @zed-industries/codex-acp           # Zed's Codex agent
