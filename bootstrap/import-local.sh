#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
CODEX_DIR=$(codex_home_dir)
TARGET_CODEX_DIR="$REPO_DIR/codex"
LOCAL_CONFIG_PATH="$CODEX_DIR/config.local.toml"
LOCAL_CONFIG_MODE="if-missing"

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --overwrite-local)
        LOCAL_CONFIG_MODE="overwrite"
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
    shift
  done
}

copy_if_exists() {
  local src="$1"
  local dst="$2"

  if [ -L "$src" ]; then
    echo "Skipping symlink source: $src"
    return 0
  fi

  if [ ! -e "$src" ]; then
    rm -rf "$dst"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"
  cp -fp "$src" "$dst"
}

sync_tree() {
  local src="$1"
  local dst="$2"
  local link
  shift 2
  local -a excludes=("$@")

  if [ -L "$src" ]; then
    echo "Skipping symlink source: $src"
    return 0
  fi

  if [ ! -d "$src" ]; then
    rm -rf "$dst"
    return 0
  fi

  mkdir -p "$dst"

  while IFS= read -r -d '' link; do
    echo "Skipping symlink source: $link"
  done < <(find -P "$src" -mindepth 1 -type l -print0)

  if command -v rsync >/dev/null 2>&1; then
    local err_file

    err_file=$(mktemp)
    if ! rsync -a --delete --no-links --quiet "${excludes[@]}" "$src/" "$dst/" 2>"$err_file"; then
      cat "$err_file" >&2
      rm -f "$err_file"
      return 1
    fi

    [ ! -s "$err_file" ] || cat "$err_file" >&2
    rm -f "$err_file"
    return 0
  fi

  local pattern
  local -a portable_excludes=()
  for pattern in "${excludes[@]}"; do
    case "$pattern" in
      --exclude=*)
        portable_excludes+=("${pattern#--exclude=}")
        ;;
    esac
  done

  copy_tree_contents "$src" "$dst" "${portable_excludes[@]}"
}

main() {
  parse_args "$@"

  mkdir -p "$TARGET_CODEX_DIR" "$TARGET_CODEX_DIR/rules" "$TARGET_CODEX_DIR/skills"

  copy_if_exists "$CODEX_DIR/AGENTS.md" "$TARGET_CODEX_DIR/AGENTS.md"
  copy_if_exists "$CODEX_DIR/instruction.md" "$TARGET_CODEX_DIR/instruction.md"

  sync_tree "$CODEX_DIR/rules" "$TARGET_CODEX_DIR/rules"

  if [ -f "$CODEX_DIR/config.toml" ]; then
    sanitize_shared_config "$CODEX_DIR/config.toml" "$TARGET_CODEX_DIR/config.shared.toml"
    if extract_local_config "$CODEX_DIR/config.toml" "$LOCAL_CONFIG_PATH" "$LOCAL_CONFIG_MODE"; then
      echo "Extracted machine-local config to $LOCAL_CONFIG_PATH"
    fi
  elif [ ! -f "$TARGET_CODEX_DIR/config.shared.toml" ]; then
    : > "$TARGET_CODEX_DIR/config.shared.toml"
  fi

  sync_tree \
    "$CODEX_DIR/skills" \
    "$TARGET_CODEX_DIR/skills" \
    --exclude='.system/' \
    --exclude='__pycache__/' \
    --exclude='*.pyc'
}

main "$@"
