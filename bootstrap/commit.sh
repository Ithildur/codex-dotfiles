#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage:
  ./codexctl commit [--push] ["commit message"]
EOF
}

is_allowed_tracked_path() {
  case "$1" in
    .gitignore|LICENSE|README.md|README.zh-CN.md|codexctl|.codex-dotfiles-id)
      return 0
      ;;
    bootstrap/*)
      return 0
      ;;
    codex/.gitkeep|codex/AGENTS.md|codex/instruction.md|codex/config.shared.toml)
      return 0
      ;;
    codex/rules/*|codex/skills/*)
      return 0
      ;;
  esac

  return 1
}

build_message() {
  local ts
  ts=$(timestamp)

  if [ "$#" -eq 0 ]; then
    printf 'sync shared config [%s]\n' "$ts"
    return 0
  fi

  printf '%s [%s]\n' "$*" "$ts"
}

ensure_only_allowed_files_tracked() {
  local path

  while IFS= read -r path; do
    is_allowed_tracked_path "$path" || die "Tracked file outside allowed set: $path"
  done < <(git_repo ls-files)
}

stage_tracked_paths() {
  local path
  local -a stage_paths=(
    .gitignore
    LICENSE
    README.md
    README.zh-CN.md
    codexctl
    bootstrap
    codex
  )

  if [ -e "$REPO_DIR/.codex-dotfiles-id" ] || git_repo ls-files --error-unmatch .codex-dotfiles-id >/dev/null 2>&1; then
    stage_paths+=(.codex-dotfiles-id)
  fi

  git_repo add -A -- "${stage_paths[@]}"
}

main() {
  local push=0

  if [ "${1:-}" = "--push" ]; then
    push=1
    shift
  fi

  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  ensure_only_allowed_files_tracked

  stage_tracked_paths

  if git_repo diff --cached --quiet; then
    echo "No changes to commit."
    if [ "$push" -eq 1 ]; then
      push_current_branch
    fi
    exit 0
  fi

  git_repo commit -m "$(build_message "$@")"
  if [ "$push" -eq 1 ]; then
    push_current_branch
  fi
}

main "$@"
