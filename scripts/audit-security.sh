#!/bin/bash
set -euo pipefail
# Security audit for dotfiles-macos
# Runs shellcheck on all shell scripts and checks installed npm package versions against OSV.dev
# Run before committing changes to scripts, dotfiles, or package version pins

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- shellcheck ---
echo "==> Running shellcheck..."

SHELL_FILES=(
    "$REPO_ROOT/macOS.sh"
    "$REPO_ROOT/scripts/install-npm-cli-tools.sh"
    "$REPO_ROOT/scripts/install-npm-acp-agents.sh"
    "$REPO_ROOT/scripts/pass-cli-chezmoi.sh"
    # Optional (add when present):
    # "$REPO_ROOT/scripts/topgrade-precheck.sh"
)

SHELLCHECK_FAILED=0
for f in "${SHELL_FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
        echo "    SKIP missing: $f"
        continue
    fi
    if shellcheck "$f"; then
        echo "    OK: $f"
    else
        SHELLCHECK_FAILED=1
    fi
done

if [[ "$SHELLCHECK_FAILED" -eq 0 ]]; then
    echo "    shellcheck: all present files passed"
fi

# --- Resolve installed npm package versions ---
echo ""
echo "==> Resolving installed npm package versions..."

eval "$(fnm env)"

NPM_LIST=$(npm list -g --depth=0 --json 2>/dev/null)

PACKAGE_NAMES=(
    "@google/gemini-cli"
    "@agentclientprotocol/claude-agent-acp"
    "@zed-industries/codex-acp"
)

PACKAGE_VERSIONS=()
for pkg in "${PACKAGE_NAMES[@]}"; do
    version=$(echo "$NPM_LIST" | python3 -c "
import sys, json
data = json.load(sys.stdin)
deps = data.get('dependencies', {})
pkg = deps.get('$pkg', {})
print(pkg.get('version', ''))
" 2>/dev/null)
    if [[ -z "$version" ]]; then
        echo "    SKIP: $pkg — not installed"
        PACKAGE_VERSIONS+=("SKIP")
    else
        echo "    Found: $pkg@$version"
        PACKAGE_VERSIONS+=("$version")
    fi
done

# --- Build OSV.dev query from installed versions ---
echo ""
echo "==> Checking installed versions against OSV.dev..."

QUERIES="["
QUERY_PACKAGES=()
for i in "${!PACKAGE_NAMES[@]}"; do
    version="${PACKAGE_VERSIONS[$i]}"
    if [[ "$version" == "SKIP" ]]; then
        continue
    fi
    pkg="${PACKAGE_NAMES[$i]}"
    QUERIES+="{\"package\":{\"name\":\"$pkg\",\"ecosystem\":\"npm\"},\"version\":\"$version\"},"
    QUERY_PACKAGES+=("$pkg@$version")
done
QUERIES="${QUERIES%,}]"

if [[ ${#QUERY_PACKAGES[@]} -eq 0 ]]; then
    echo "    No npm packages to check"
    OSV_FAILED=0
else
    OSV_RESPONSE=$(curl -sf -X POST "https://api.osv.dev/v1/querybatch" \
        -H "Content-Type: application/json" \
        -d "{\"queries\":$QUERIES}")

    OSV_FAILED=0
    for i in "${!QUERY_PACKAGES[@]}"; do
        pkg="${QUERY_PACKAGES[$i]}"
        VULNS=$(echo "$OSV_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
result = data['results'][$i]
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
    done
fi

# --- Summary ---
echo ""
if [[ "$SHELLCHECK_FAILED" -eq 0 && "$OSV_FAILED" -eq 0 ]]; then
    echo "==> Audit passed — no issues found."
    exit 0
else
    echo "==> Audit FAILED — fix the issues above before committing."
    exit 1
fi
