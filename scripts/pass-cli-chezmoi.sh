#!/usr/bin/env bash
# pass-cli-chezmoi.sh — chezmoi [protonPass] backend
#
# Full user sessions: pass://SHARE/ITEM[/FIELD] works with the real vault share id.
# PAT sessions: Personal vault is exposed under a different share id (access grant).
# Fall back to --vault-name + --item-id so the same chezmoi.toml data works either way.
set -euo pipefail

PASS_CLI="${PASS_CLI_BIN:-pass-cli}"

if [[ "${1:-}" == "item" && "${2:-}" == "view" && "${3:-}" == pass://* ]]; then
    uri="$3"
    if out="$("$PASS_CLI" item view "$uri" 2>/dev/null)"; then
        printf '%s\n' "$out"
        exit 0
    fi

    rest="${uri#pass://}"
    item_and_field="${rest#*/}"
    item="${item_and_field%%/*}"
    field=""
    if [[ "$item_and_field" == */* ]]; then
        field="${item_and_field#*/}"
    fi

    for vault in Personal Shared; do
        if [[ -n "$field" ]]; then
            if out="$("$PASS_CLI" item view --vault-name "$vault" --item-id "$item" --field "$field" 2>/dev/null)"; then
                printf '%s\n' "$out"
                exit 0
            fi
        else
            if out="$("$PASS_CLI" item view --vault-name "$vault" --item-id "$item" 2>/dev/null)"; then
                printf '%s\n' "$out"
                exit 0
            fi
        fi
    done

    # Surface original error
    exec "$PASS_CLI" item view "$uri"
fi

exec "$PASS_CLI" "$@"
