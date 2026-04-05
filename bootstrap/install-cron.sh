#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
MODE="${1:-sync}"

case "$MODE" in
  sync|publish|none)
    ;;
  *)
    die "Usage: ./codexctl install-cron [sync|publish|none]"
    ;;
esac

[ "$#" -le 1 ] || die "Usage: ./codexctl install-cron [sync|publish|none]"

if is_windows_host; then
  die "install-cron is not supported on Windows hosts. Use manual ./codexctl sync instead."
fi

ensure_command crontab

BEGIN_MARKER="# BEGIN codex-dotfiles"
END_MARKER="# END codex-dotfiles"
EXISTING=$(crontab -l 2>/dev/null | awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
  $0 == begin {skip=1; next}
  $0 == end {skip=0; next}
  !skip {print}
' || true)

{
  if [ -n "$EXISTING" ]; then
    echo "$EXISTING"
  fi
  if [ "$MODE" != "none" ]; then
    echo "$BEGIN_MARKER"
    echo "0 * * * * cd '$REPO_DIR' && '$SCRIPT_DIR/$MODE.sh' >/dev/null 2>&1"
    echo "$END_MARKER"
  fi
} | crontab -

if [ "$MODE" = "none" ]; then
  echo "Removed codex-dotfiles cron job."
else
  echo "Installed hourly cron job for $MODE."
fi
