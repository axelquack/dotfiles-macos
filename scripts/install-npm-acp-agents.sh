#!/bin/bash
set -euo pipefail
# ACP agent servers for the Obsidian Agent Client plugin
# See: https://rait-09.github.io/obsidian-agent-client/agent-setup/
# Run after: fnm is installed and a Node.js version is active

eval "$(fnm env)"

npm install -g @agentclientprotocol/claude-agent-acp@0.26.0   # Claude agent (ACP server)
npm install -g @zed-industries/codex-acp@0.11.1               # Codex agent (ACP server)
