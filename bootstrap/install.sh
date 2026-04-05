#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
SOURCE_DIR="$REPO_DIR/codex"
TARGET_DIR=$(codex_home_dir)
SHARED_CONFIG="$SOURCE_DIR/config.shared.toml"

sync_file() {
  local src="$1"
  local dst="$2"

  if [ ! -f "$src" ]; then
    rm -rf "$dst"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  cp -fLp "$src" "$dst"
}

sync_tree() {
  local src_dir="$1"
  local dst_dir="$2"

  if [ ! -d "$src_dir" ]; then
    rm -rf "$dst_dir"
    return 0
  fi

  if command -v rsync >/dev/null 2>&1; then
    rm -rf "$dst_dir"
    mkdir -p "$dst_dir"
    rsync -aL --delete --exclude='.gitkeep' "$src_dir/" "$dst_dir/"
    return 0
  fi

  copy_tree_contents "$src_dir" "$dst_dir" '.gitkeep'
}

mkdir -p "$TARGET_DIR" "$TARGET_DIR/rules" "$TARGET_DIR/skills"
[ -f "$SHARED_CONFIG" ] || die "Missing $SHARED_CONFIG. Run ./codexctl init first, or create codex/config.shared.toml."

for file in AGENTS.md instruction.md; do
  sync_file "$SOURCE_DIR/$file" "$TARGET_DIR/$file"
done

sync_tree "$SOURCE_DIR/rules" "$TARGET_DIR/rules"
sync_tree "$SOURCE_DIR/skills" "$TARGET_DIR/skills"

"$SCRIPT_DIR/render-config.sh"

echo "Synced managed Codex files into $TARGET_DIR"
echo "Machine-local archive: $TARGET_DIR/config.local.toml"
