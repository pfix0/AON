#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_DIR="$HOME/.config/aon"
CONFIG_FILE="$CONFIG_DIR/telegram.env"

if [ -t 1 ]; then
  RESET='\033[0m'
  BOLD='\033[1m'
  GREEN='\033[32m'
  YELLOW='\033[33m'
  CYAN='\033[36m'
  RED='\033[31m'
else
  RESET=''; BOLD=''; GREEN=''; YELLOW=''; CYAN=''; RED=''
fi

say()  { printf '%b\n' "$*"; }
ok()   { say "$GREEN✓$RESET $*"; }
warn() { say "$YELLOW!$RESET $*"; }
die()  { say "$RED✗$RESET $*" >&2; exit 1; }

load_config() {
  [ -f "$CONFIG_FILE" ] || return 1
  . "$CONFIG_FILE"
  [ -n "$AON_TELEGRAM_BOT_TOKEN" ] && [ -n "$AON_TELEGRAM_CHAT_ID" ]
}

send_message() {
  local message="$1"
  load_config || die "Telegram is not configured. Run: aon-notify setup"

  curl -fsS --max-time 15 -X POST     "https://api.telegram.org/bot$AON_TELEGRAM_BOT_TOKEN/sendMessage"     --data-urlencode "chat_id=$AON_TELEGRAM_CHAT_ID"     --data-urlencode "text=$message" >/dev/null
}

setup_telegram() {
  mkdir -p "$CONFIG_DIR"

  printf "Telegram Bot Token: "
  read -r -s token
  printf "\nTelegram Chat ID: "
  read -r chat_id

  [ -n "$token" ] || die "Bot token is required."
  [ -n "$chat_id" ] || die "Chat ID is required."

  umask 077
  {
    printf "AON_TELEGRAM_BOT_TOKEN='%s'\n" "$token"
    printf "AON_TELEGRAM_CHAT_ID='%s'\n" "$chat_id"
  } > "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"

  send_message "AON notifications connected on $(hostname)."
  ok "Telegram configured. A test message was sent."
}

status() {
  if load_config; then
    ok "Telegram is configured."
    say "Config: $CONFIG_FILE"
  else
    warn "Telegram is not configured."
  fi
}

disable() {
  rm -f "$CONFIG_FILE"
  ok "Telegram configuration removed."
}

notify() {
  [ "$#" -gt 0 ] || die "Usage: aon-notify send <message>"

  local session="none"
  if [ -n "$TMUX" ]; then
    session="$(tmux display-message -p '#S' 2>/dev/null || echo none)"
  fi

  send_message "AON Notification
Host: $(hostname)
Session: $session
Message: $*"

  ok "Notification sent."
}

run_and_notify() {
  [ "$#" -gt 0 ] || die "Usage: aon-notify run <command> [args...]"

  local start end duration rc session command_text
  start="$(date +%s)"
  session="none"

  if [ -n "$TMUX" ]; then
    session="$(tmux display-message -p '#S' 2>/dev/null || echo none)"
  fi

  printf -v command_text '%q ' "$@"

  set +e
  "$@"
  rc=$?
  set -e

  end="$(date +%s)"
  duration=$((end - start))

  if load_config; then
    if [ "$rc" -eq 0 ]; then
      send_message "AON Task Completed
Host: $(hostname)
Session: $session
Command: $command_text
Exit code: $rc
Duration: ${duration}s"
    else
      send_message "AON Task Failed
Host: $(hostname)
Session: $session
Command: $command_text
Exit code: $rc
Duration: ${duration}s"
    fi
  else
    warn "Task finished, but Telegram is not configured."
  fi

  return "$rc"
}

help_text() {
  cat <<'HELP'

AON Notify
==========

Generic Telegram notifications for any terminal command or AI CLI.

Commands:
  aon-notify setup
      Configure Telegram Bot Token + Chat ID.

  aon-notify test
      Send a test message.

  aon-notify status
      Show configuration status.

  aon-notify disable
      Remove Telegram configuration.

  aon-notify send "message"
      Send a manual notification.

  aon-notify run <command> [args...]
      Run any command and notify when the process exits.

Examples:
  aon-notify run claude
  aon-notify run codex
  aon-notify run kimi
  aon-notify run npm run build
  aon-notify send "Deployment finished"

Note:
  For interactive AI tools, the completion notification is sent when
  the CLI process exits. For one-shot commands, it is sent immediately
  when that command finishes.

HELP
}

case "$1" in
  setup) setup_telegram ;;
  test) send_message "AON test notification from $(hostname)."; ok "Test message sent." ;;
  status) status ;;
  disable) disable ;;
  send) shift; notify "$@" ;;
  run) shift; run_and_notify "$@" ;;
  help|-h|--help|"") help_text ;;
  *) die "Unknown command: $1. Run: aon-notify help" ;;
esac
