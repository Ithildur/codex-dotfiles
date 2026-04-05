#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
TARGET_DIR=$(codex_home_dir)
LOCK_FILE=$(lock_file_for sync)
LOG_FILE="$STATE_DIR/sync.log"

main() {
  acquire_lock "$LOCK_FILE" || {
    log_to "$LOG_FILE" "sync already running, skip"
    exit 0
  }
  ensure_git_repo

  if [ -n "$(git_repo status --porcelain)" ]; then
    log_to "$LOG_FILE" "repo has local changes, skip sync"
    exit 0
  fi

  if ! git_repo rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
    log_to "$LOG_FILE" "current branch has no upstream, skip sync"
    exit 0
  fi

  local before after
  before=$(git_repo rev-parse HEAD)

  log_to "$LOG_FILE" "pull start"
  git_repo pull --ff-only
  after=$(git_repo rev-parse HEAD)

  "$SCRIPT_DIR/install.sh" >/dev/null

  if [ "$before" = "$after" ]; then
    log_to "$LOG_FILE" "sync complete, already up to date"
  else
    log_to "$LOG_FILE" "sync complete, updated $before -> $after"
  fi

  log_to "$LOG_FILE" "rendered config at $TARGET_DIR/config.toml"
}

main "$@"
