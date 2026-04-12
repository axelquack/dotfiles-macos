#!/bin/bash
set -euo pipefail
# Security audit for dotfiles-macos
# Runs shellcheck on all shell scripts and checks npm package versions against OSV.dev
# Run before committing changes to scripts, dotfiles, or package version pins

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- shellcheck ---
echo "==> Running shellcheck..."

SHELL_FILES=(
    "$REPO_ROOT/macOS.sh"
    "$REPO_ROOT/scripts/install-npm-cli-tools.sh"
    "$REPO_ROOT/scripts/install-npm-acp-agents.sh"
)

SHELLCHECK_FAILED=0
for f in "${SHELL_FILES[@]}"; do
    if shellcheck "$f"; then
        echo "    OK: $f"
    else
        SHELLCHECK_FAILED=1
    fi
done

if [[ "$SHELLCHECK_FAILED" -eq 0 ]]; then
    echo "    shellcheck: all files passed"
fi

# --- OSV.dev vulnerability check ---
echo ""
echo "==> Checking npm packages against OSV.dev..."

OSV_RESPONSE=$(curl -sf -X POST "https://api.osv.dev/v1/querybatch" \
    -H "Content-Type: application/json" \
    -d '{
        "queries": [
            {"package": {"name": "@anthropic-ai/claude-code", "ecosystem": "npm"}, "version": "2.1.104"},
            {"package": {"name": "@google/gemini-cli", "ecosystem": "npm"}, "version": "0.37.1"},
            {"package": {"name": "@agentclientprotocol/claude-agent-acp", "ecosystem": "npm"}, "version": "0.26.0"},
            {"package": {"name": "@zed-industries/codex-acp", "ecosystem": "npm"}, "version": "0.11.1"}
        ]
    }')

PACKAGES=(
    "@anthropic-ai/claude-code@2.1.104"
    "@google/gemini-cli@0.37.1"
    "@agentclientprotocol/claude-agent-acp@0.26.0"
    "@zed-industries/codex-acp@0.11.1"
)

OSV_FAILED=0
INDEX=0
for pkg in "${PACKAGES[@]}"; do
    VULNS=$(echo "$OSV_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
result = data['results'][$INDEX]
vulns = result.get('vulns', [])
print(len(vulns))
for v in vulns:
    print('  -', v.get('id', '?'), v.get('summary', ''))
")
    COUNT=$(echo "$VULNS" | head -1)
    if [[ "$COUNT" -eq 0 ]]; then
        echo "    OK: $pkg — no known vulnerabilities"
    else
        echo "    VULNERABLE: $pkg"
        echo "$VULNS" | tail -n +2
        OSV_FAILED=1
    fi
    INDEX=$((INDEX + 1))
done

# --- Summary ---
echo ""
if [[ "$SHELLCHECK_FAILED" -eq 0 && "$OSV_FAILED" -eq 0 ]]; then
    echo "==> Audit passed — no issues found."
    exit 0
else
    echo "==> Audit FAILED — fix the issues above before committing."
    exit 1
fi
