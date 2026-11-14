#!/usr/bin/env bash
# Run `just -g` when the first recipe exists only in the global justfile.
# Project justfiles always win. Called from the zsh `just` wrapper
# (~/.config/just/just-wrapper.zsh). See docs/himalaya.md.
#
# Set JUST_NO_GLOBAL_FALLBACK=1 to skip the fallback and call just as-is.

set -euo pipefail

if ! command -v just >/dev/null 2>&1; then
  echo "just-global-fallback: just is not on PATH." >&2
  exit 127
fi

if [[ "${JUST_NO_GLOBAL_FALLBACK:-}" == 1 ]]; then
  exec just "$@"
fi

# Long options that take a following argument.
# --set is handled separately (variable + value). --command / -c consume the rest.
long_opt_with_arg() {
  case "$1" in
    --alias-style|--ceiling|--chooser|--color|--command-color|--cygpath|--dotenv-command|--dotenv-filename|--dotenv-path|--dump-format|--evaluate-format|--group|--indentation|--jobs|--justfile|--justfile-name|--list-heading|--list-prefix|--shell|--shell-arg|--tempdir|--timestamp-format|--working-directory|--completions)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Command flags that do not take a recipe from the positional list
# (--show / -s is the exception: the next argument is a recipe name).
is_passthrough_command() {
  case "$1" in
    --changelog|--choose|--clean|--command|-c|--completions|--dump|--edit|-e|--evaluate|--fmt|--groups|--init|--json|--list|-l|--man|--summary|--usage|--variables|--help|-h|--version|-V)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

already_global=0
explicit_justfile=0
first_recipe=""
passthrough=0

args=("$@")
n=${#args[@]}
i=0
while ((i < n)); do
  a="${args[i]}"
  case "$a" in
    --)
      i=$((i + 1))
      if ((i < n)) && [[ -z "${first_recipe}" ]]; then
        first_recipe="${args[i]}"
      fi
      break
      ;;
    -g|--global-justfile)
      already_global=1
      i=$((i + 1))
      ;;
    --justfile|--justfile-name|-f)
      explicit_justfile=1
      i=$((i + 2))
      ;;
    --justfile=*|--justfile-name=*)
      explicit_justfile=1
      i=$((i + 1))
      ;;
    --set)
      i=$((i + 3))
      ;;
    --show|-s)
      i=$((i + 1))
      if ((i < n)) && [[ "${args[i]}" != -* ]]; then
        first_recipe="${args[i]}"
      fi
      break
      ;;
    --command|-c|--completions)
      passthrough=1
      break
      ;;
    --*=*)
      i=$((i + 1))
      ;;
    --*)
      if is_passthrough_command "$a"; then
        passthrough=1
        break
      fi
      if long_opt_with_arg "$a"; then
        i=$((i + 2))
      else
        i=$((i + 1))
      fi
      ;;
    -)
      i=$((i + 1))
      ;;
    -*)
      # Clustered short flags, e.g. -nv, or a single short option.
      cluster="${a:1}"
      if [[ "$cluster" == *f* || "$cluster" == *d* || "$cluster" == *F* || "$cluster" == *E* ]]; then
        # With-arg short option; next argv is the value if present.
        # just's help uses a separate argument, not -fFILE glued together.
        i=$((i + 2))
        continue
      fi
      if [[ "$cluster" == *c* ]]; then
        passthrough=1
        break
      fi
      if [[ "$cluster" == *s* ]]; then
        i=$((i + 1))
        if ((i < n)) && [[ "${args[i]}" != -* ]]; then
          first_recipe="${args[i]}"
        fi
        break
      fi
      if [[ "$cluster" == *l* || "$cluster" == *e* || "$cluster" == *h* || "$cluster" == *V* ]]; then
        passthrough=1
        break
      fi
      if [[ "$cluster" == *g* ]]; then
        already_global=1
      fi
      i=$((i + 1))
      ;;
    *=*)
      # just VAR=value override, not a recipe.
      i=$((i + 1))
      ;;
    *)
      first_recipe="$a"
      break
      ;;
  esac
done

if ((passthrough == 1 || already_global == 1 || explicit_justfile == 1)) || [[ -z "${first_recipe}" ]]; then
  exec just "$@"
fi

has_recipe() {
  local mode="$1"
  local name="$2"
  local summary
  if [[ "$mode" == global ]]; then
    summary="$(just -g --summary 2>/dev/null || true)"
  else
    summary="$(just --summary 2>/dev/null || true)"
  fi
  # `just --summary` prints one space-separated line of recipe names.
  if printf '%s' "${summary}" | tr ' ' '\n' | grep -qxF -- "${name}"; then
    return 0
  fi
  return 1
}

if ! has_recipe local "${first_recipe}" && has_recipe global "${first_recipe}"; then
  exec just -g "$@"
fi

exec just "$@"
