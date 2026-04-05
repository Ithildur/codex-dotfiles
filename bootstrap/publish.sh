#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
LOCK_FILE=$(lock_file_for publish)
LOG_FILE="$STATE_DIR/publish.log"

main() {
  if is_windows_host; then
    die "publish is disabled on Windows hosts. Use a primary non-Windows environment to publish."
  fi

  acquire_lock "$LOCK_FILE" || {
    log_to "$LOG_FILE" "publish already running, skip"
    exit 0
  }
  ensure_git_repo

  log_to "$LOG_FILE" "publish start"
  "$SCRIPT_DIR/commit.sh" --push "scheduled publish"
  log_to "$LOG_FILE" "publish complete"
}

main "$@"
