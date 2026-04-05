#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
IDENTIFIER_FILE="$REPO_DIR/.codex-dotfiles-id"
PENDING_INIT_FILE=$(repo_state_file init-pending)
INIT_SUCCESS=0
CREATED_IDENTIFIER=0

prompt_value() {
  local label="$1"
  local default="${2:-}"
  local value

  if [ -n "$default" ]; then
    read -r -p "$label [$default]: " value
    printf '%s\n' "${value:-$default}"
    return 0
  fi

  while :; do
    read -r -p "$label: " value
    if [ -n "$value" ]; then
      printf '%s\n' "$value"
      return 0
    fi
  done
}

prompt_yes_no() {
  local label="$1"
  local default="${2:-y}"
  local answer

  while :; do
    if [ "$default" = "y" ]; then
      read -r -p "$label [Y/n]: " answer
      answer=${answer:-y}
    else
      read -r -p "$label [y/N]: " answer
      answer=${answer:-n}
    fi

    case "$answer" in
      y|Y|yes|YES)
        return 0
        ;;
      n|N|no|NO)
        return 1
        ;;
    esac
  done
}

generate_identifier() {
  uuidgen 2>/dev/null || date '+%Y%m%d%H%M%S'"-$$-$(hostname)"
}

cleanup_init() {
  if [ "${INIT_SUCCESS:-0}" -eq 1 ]; then
    rm -f "$PENDING_INIT_FILE"
    return 0
  fi

  if [ "${CREATED_IDENTIFIER:-0}" -eq 1 ] && [ "${INIT_SUCCESS:-0}" -ne 1 ]; then
    if git_repo ls-files --error-unmatch .codex-dotfiles-id >/dev/null 2>&1; then
      return 0
    fi
    rm -f "$IDENTIFIER_FILE"
  fi
}

ensure_git_repo() {
  if git_repo rev-parse --show-toplevel >/dev/null 2>&1; then
    return 0
  fi

  git -C "$REPO_DIR" init -b main >/dev/null 2>&1 || {
    git -C "$REPO_DIR" init >/dev/null
    git_repo branch -M main
  }
}

git_config_value() {
  git_repo config --local "$1" 2>/dev/null || git config --global "$1" 2>/dev/null || true
}

set_origin_remote() {
  local remote_url="$1"

  if [ -z "$remote_url" ]; then
    return 0
  fi

  if git_repo remote get-url origin >/dev/null 2>&1; then
    git_repo remote set-url origin "$remote_url"
  else
    git_repo remote add origin "$remote_url"
  fi
}

clear_schedulers() {
  command -v crontab >/dev/null 2>&1 && "$SCRIPT_DIR/install-cron.sh" none >/dev/null 2>&1 || true
}

install_scheduler() {
  local mode="$1"

  if [ "$mode" = "none" ]; then
    clear_schedulers
    return 0
  fi

  ensure_command crontab
  clear_schedulers
  "$SCRIPT_DIR/install-cron.sh" "$mode" >/dev/null
}

write_identifier_if_needed() {
  [ -f "$IDENTIFIER_FILE" ] && return 0

  printf '%s\n' "$(generate_identifier)" > "$IDENTIFIER_FILE"
  CREATED_IDENTIFIER=1
}

mark_init_pending() {
  mkdir -p "$(dirname "$PENDING_INIT_FILE")"
  printf 'pending\n' > "$PENDING_INIT_FILE"
}

has_imported_repo_state() {
  [ -f "$REPO_DIR/codex/config.shared.toml" ]
}

main() {
  local codex_home imported_local=0

  trap cleanup_init EXIT

  if [ ! -t 0 ]; then
    echo "init requires an interactive terminal." >&2
    exit 1
  fi

  codex_home=$(codex_home_dir)

  if [ -f "$PENDING_INIT_FILE" ]; then
    if has_imported_repo_state; then
      echo "Found incomplete init state, skip re-import from $codex_home and resume initialization."
    else
      rm -f "$PENDING_INIT_FILE"
      "$SCRIPT_DIR/import-local.sh" --overwrite-local
      mark_init_pending
      imported_local=1
      echo "Found stale init state without imported config, re-imported shared files from $codex_home."
    fi
  elif [ ! -f "$IDENTIFIER_FILE" ]; then
    "$SCRIPT_DIR/import-local.sh" --overwrite-local
    mark_init_pending
    imported_local=1
    echo "Imported shared files from $codex_home."
  else
    echo "Repository identifier exists, skip importing from $codex_home."
  fi

  ensure_git_repo

  local default_name default_email default_remote git_name git_email remote_url
  default_name=$(git_config_value user.name)
  default_email=$(git_config_value user.email)
  default_remote=$(git_repo remote get-url origin 2>/dev/null || true)

  git_name=$(prompt_value "Local git user.name" "$default_name")
  git_email=$(prompt_value "Local git user.email" "$default_email")
  remote_url=$(prompt_value "Git remote origin URL" "$default_remote")

  git_repo config --local user.name "$git_name"
  git_repo config --local user.email "$git_email"
  set_origin_remote "$remote_url"

  "$SCRIPT_DIR/install.sh"

  if is_windows_host; then
    install_scheduler none >/dev/null 2>&1 || true
    write_identifier_if_needed
    INIT_SUCCESS=1
    if [ "$imported_local" -eq 1 ]; then
      echo "Created repository identifier."
    fi
    echo "Windows host detected: configured as secondary environment with manual sync only."
    echo "Run ./codexctl sync manually when you want to pull updates."
    return 0
  fi

  if prompt_yes_no "Use this environment as the primary environment" "n"; then
    install_scheduler publish
    write_identifier_if_needed
    "$SCRIPT_DIR/commit.sh" --push "initialize primary environment"
    INIT_SUCCESS=1
    if [ "$imported_local" -eq 1 ]; then
      echo "Created repository identifier."
    fi
    echo "Primary environment initialized."
    return 0
  fi

  if prompt_yes_no "Enable periodic auto-pull for this environment" "y"; then
    install_scheduler sync
  else
    install_scheduler none >/dev/null
  fi

  write_identifier_if_needed
  INIT_SUCCESS=1
  if [ "$imported_local" -eq 1 ]; then
    echo "Created repository identifier."
  fi
  echo "Secondary environment initialized."
}

main "$@"
