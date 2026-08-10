#!/usr/bin/env bash
# Shared helpers for loading gitignored Pass maps (public-repo safe).
# Sourced by pass-import / bootstrap / pass-write-zshrc-local.
# shellcheck shell=bash

pass_map_load_lines() {
  # Usage: pass_map_load_lines /path/to/map.local → prints non-comment lines
  local f="$1"
  if [[ ! -f "$f" ]]; then
    return 1
  fi
  # strip comments and blank lines
  grep -v '^\s*#' "$f" | grep -v '^\s*$' || true
}

pass_map_require() {
  local f="$1"
  local example="$2"
  if [[ ! -f "$f" ]]; then
    echo "ERROR: missing map file: $f" >&2
    echo "  Copy the example and edit (gitignored):" >&2
    echo "    cp $example $f" >&2
    return 1
  fi
}
