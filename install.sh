#!/usr/bin/env bash
set -Eeuo pipefail

AON_VERSION="1.0.0"
AON_AUTHOR="pfix0"
AON_BIN="/usr/local/bin/aon"

GREEN="$(printf '\033[32m')"
CYAN="$(printf '\033[36m')"
YELLOW="$(printf '\033[33m')"
RED="$(printf '\033[31m')"
BOLD="$(printf '\033[1m')"
RESET="$(printf '\033[0m')"

info() { printf "${CYAN}%s${RESET}\n" "$*"; }
ok()   { printf "${GREEN}%s${RESET}\n" "$*"; }
warn() { printf "${YELLOW}%s${RESET}\n" "$*"; }
die()  { printf "${RED}%s${RESET}\n" "$*" >&2; exit 1; }

cat <<EOF

${BOLD}AON${RESET}
Terminal Session Assistant
Version: ${AON_VERSION}
Author: ${AON_AUTHOR}

AON is a lightweight terminal session manager built on tmux.

It helps you:
  - keep Claude Code, Codex, servers, builds and scripts running
  - detach with F6 without stopping your work
  - return to the same session later
  - create multiple terminal windows
  - split the terminal into panes
  - zoom the active pane to full-screen
  - switch panes and windows with the mouse
  - use TAB completion for session names
  - use AON help from inside an AON session

Outside AON, your normal shell help remains unchanged.

EOF

case "$(uname -s)" in
  Linux) HOST_OS="linux" ;;
  Darwin) HOST_OS="macos" ;;
  *) die "Unsupported host OS: $(uname -s). Use Linux, macOS, or Windows through WSL." ;;
esac

if [ "$(id -u)" -eq 0 ]; then
  TARGET_USER="${SUDO_USER:-root}"
else
  TARGET_USER="${USER}"
fi

if command -v getent >/dev/null 2>&1; then
  TARGET_HOME="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6 || true)"
else
  TARGET_HOME=""
fi

if [ -z "${TARGET_HOME:-}" ]; then
  TARGET_HOME="$(eval echo "~${TARGET_USER}")"
fi

[ -d "$TARGET_HOME" ] || die "Cannot determine home directory for $TARGET_USER"
TARGET_GROUP="$(id -gn "$TARGET_USER")"

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "sudo is required."
  fi
}

install_linux_packages() {
  [ -f /etc/os-release ] || die "Cannot detect Linux distribution."
  . /etc/os-release
  local os_id="${ID:-unknown}"
  local os_like="${ID_LIKE:-}"

  if [[ "$os_id" =~ ^(ubuntu|debian|linuxmint|pop)$ ]] || [[ "$os_like" == *debian* ]]; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get update -y
    run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y       tmux byobu bash-completion zsh git curl wget ca-certificates       locales ncurses-term openssh-client procps util-linux less nano
    return
  fi

  if [[ "$os_id" =~ ^(fedora|rhel|centos|rocky|almalinux)$ ]] || [[ "$os_like" =~ (rhel|fedora|centos) ]]; then
    if command -v dnf >/dev/null 2>&1; then
      run_root dnf install -y tmux bash-completion zsh git curl wget ca-certificates         ncurses openssh-clients procps-ng util-linux less nano
    else
      run_root yum install -y tmux bash-completion zsh git curl wget ca-certificates         ncurses openssh-clients procps-ng util-linux less nano
    fi
    return
  fi

  if command -v pacman >/dev/null 2>&1; then
    run_root pacman -Sy --noconfirm tmux bash-completion zsh git curl wget ca-certificates       openssh procps-ng util-linux less nano
    return
  fi

  if command -v zypper >/dev/null 2>&1; then
    run_root zypper --non-interactive install tmux bash-completion zsh git curl wget       ca-certificates openssh procps util-linux less nano
    return
  fi

  die "Unsupported Linux distribution/package manager."
}

install_macos_packages() {
  command -v brew >/dev/null 2>&1 || die "Homebrew is required on macOS: https://brew.sh"
  brew install tmux bash-completion@2 zsh git curl wget || true
}

info "[1/11] Installing required packages..."
if [ "$HOST_OS" = "linux" ]; then
  install_linux_packages
else
  install_macos_packages
fi

info "[2/11] Verifying dependencies..."
for cmd in tmux bash zsh git curl ssh sed grep awk; do
  command -v "$cmd" >/dev/null 2>&1 || die "Missing required command: $cmd"
done
ok "Dependencies OK."

info "[3/11] Installing AON command..."

TMP_AON="$(mktemp)"
cat > "$TMP_AON" <<'AON'
#!/usr/bin/env bash
set -Eeuo pipefail

AON_VERSION="1.0.0"
AON_AUTHOR="pfix0"

die() {
  echo "AON: $*" >&2
  exit 1
}

session_exists() {
  tmux has-session -t "$1" 2>/dev/null
}

mark_session() {
  tmux set-option -t "$1" @aon_session 1 >/dev/null
}

create_session() {
  local name="$1"
  tmux new-session -d -s "$name"
  mark_session "$name"
  exec tmux attach-session -t "$name"
}

list_sessions() {
  if ! tmux list-sessions >/dev/null 2>&1; then
    echo "No AON sessions."
    return 0
  fi

  printf "%-24s %-8s %-12s %-20s\n" "SESSION" "WINDOWS" "STATUS" "CREATED"
  printf "%-24s %-8s %-12s %-20s\n" "-------" "-------" "------" "-------"

  tmux list-sessions -F '#{session_name}|#{session_windows}|#{?session_attached,attached,background}|#{session_created_string}' |
  while IFS='|' read -r name windows status created; do
    printf "%-24s %-8s %-12s %-20s\n" "$name" "$windows" "$status" "$created"
  done
}

new_session() {
  local name="${1:-}"
  [ -n "$name" ] || die "Usage: aon new <name>"
  session_exists "$name" && die "Session '$name' already exists."
  create_session "$name"
}

attach_session() {
  local name="${1:-}"
  [ -n "$name" ] || die "Usage: aon attach <name>"
  session_exists "$name" || die "Session '$name' does not exist."
  mark_session "$name"
  exec tmux attach-session -t "$name"
}

open_session() {
  local name="${1:-}"
  [ -n "$name" ] || die "Usage: aon open <name>"
  if session_exists "$name"; then
    mark_session "$name"
    exec tmux attach-session -t "$name"
  else
    create_session "$name"
  fi
}

kill_session() {
  local name="${1:-}"
  [ -n "$name" ] || die "Usage: aon kill <name>"
  session_exists "$name" || die "Session '$name' does not exist."
  tmux kill-session -t "$name"
  echo "Stopped session: $name"
}

rename_session() {
  local old="${1:-}"
  local new="${2:-}"
  [ -n "$old" ] && [ -n "$new" ] || die "Usage: aon rename <old> <new>"
  session_exists "$old" || die "Session '$old' does not exist."
  session_exists "$new" && die "Session '$new' already exists."
  tmux rename-session -t "$old" "$new"
  mark_session "$new"
  echo "Renamed: $old -> $new"
}

current_session() {
  if [ -n "${TMUX:-}" ]; then
    tmux display-message -p '#S'
  else
    echo "Not inside an AON session."
  fi
}

detach_session() {
  [ -n "${TMUX:-}" ] || die "You are not inside an AON session."
  tmux detach-client
}

kill_all() {
  if ! tmux list-sessions >/dev/null 2>&1; then
    echo "No AON sessions."
    return 0
  fi
  tmux kill-server
  echo "All AON sessions stopped."
}

doctor() {
  echo
  echo "AON Doctor"
  echo "=========="
  local failed=0

  for cmd in tmux bash zsh git curl ssh; do
    if command -v "$cmd" >/dev/null 2>&1; then
      printf "%-18s OK\n" "$cmd"
    else
      printf "%-18s MISSING\n" "$cmd"
      failed=1
    fi
  done

  if [ -f "$HOME/.tmux.conf" ]; then
    printf "%-18s OK\n" "tmux config"
  else
    printf "%-18s MISSING\n" "tmux config"
    failed=1
  fi

  printf "%-18s %s\n" "AON version" "$AON_VERSION"
  printf "%-18s %s\n" "Author" "$AON_AUTHOR"
  printf "%-18s %s\n" "tmux" "$(tmux -V 2>/dev/null || echo unknown)"
  echo

  [ "$failed" -eq 0 ] && echo "AON installation is healthy." || return 1
}

keys_text() {
cat <<'KEYS'

AON Keyboard
============

F4    Zoom / unzoom current pane
F5    New window
F6    Background / Detach
F7    Previous window
F8    Next window
F9    Split left / right
F10   Split top / bottom
F11   Close current pane
F12   Close current window

Alt + 1..9
      Jump directly to a window

Alt + Arrow
      Move between panes

Shift + Arrow
      Resize current pane

Mouse:
  Click a pane to focus it.
  Click a window in the bottom status bar to switch to it.
  Double-click remains available for normal terminal text selection.

tmux fallback:
  Ctrl+b then c   New window
  Ctrl+b then d   Detach
  Ctrl+b then n   Next window
  Ctrl+b then p   Previous window
  Ctrl+b then %   Split left / right
  Ctrl+b then "   Split top / bottom
  Ctrl+b then x   Close pane

KEYS
}

quick_help() {
cat <<'HELP'

AON Help
========

Sessions:
  aon new NAME
  aon open NAME
  aon attach NAME
  aon list
  aon kill NAME

Keyboard:
  F4    Zoom / unzoom
  F5    New window
  F6    Background / Detach
  F7    Previous window
  F8    Next window
  F9    Split left / right
  F10   Split top / bottom
  F11   Close pane
  F12   Close window

Mouse:
  Click a pane to focus it.
  Click a window in the bottom bar to switch to it.

More:
  help --
  help --keys
  help --commands
  help --mac
  help --windows
  help --linux

HELP
}

commands_help() {
cat <<'COMMANDS'

AON Commands
============

aon list
aon new <name>
aon open <name>
aon attach <name>
aon detach
aon bg
aon background
aon kill <name>
aon rename <old> <new>
aon current
aon kill-all
aon keys
aon doctor
aon version
aon help
aon help --

COMMANDS
}

mac_help() {
cat <<'MAC'

AON - macOS
===========

Many MacBooks use:
  Fn + F4 ... Fn + F12

If standard function keys are enabled:
  F4 ... F12

MAC
}

windows_help() {
cat <<'WINDOWS'

AON - Windows
=============

Use AON locally through WSL/WSL2, or connect to an AON host over SSH.

Desktop keyboards usually use:
  F4 ... F12

Some laptops require:
  Fn + F4 ... Fn + F12

WINDOWS
}

linux_help() {
cat <<'LINUX'

AON - Linux
===========

Desktop keyboards usually use:
  F4 ... F12

Some laptops require Fn depending on firmware and keyboard settings.

LINUX
}

full_help() {
cat <<'HELP'

AON - Terminal Session Assistant
================================

Author: pfix0
Version: 1.0.0

AON keeps terminal work alive inside tmux sessions.

Typical workflow:

  aon new project

Run your work:

  claude
  codex
  npm run dev
  python app.py

Press F6 to detach.

Everything inside the session continues running.

Return later:

  aon attach project

Inside AON:
  help
  help --
  help --keys
  help --commands
  help --mac
  help --windows
  help --linux

Outside AON, normal shell help remains unchanged.

HELP
keys_text
}

help_router() {
  case "${1:-}" in
    ""|quick) quick_help ;;
    --|--full|-f|full) full_help ;;
    --keys|keys) keys_text ;;
    --commands|commands) commands_help ;;
    --mac|mac|macos) mac_help ;;
    --windows|windows|win) windows_help ;;
    --linux|linux) linux_help ;;
    *) echo "Unknown help option: $1"; echo; quick_help ;;
  esac
}

case "${1:-list}" in
  list|ls) list_sessions ;;
  new|create) new_session "${2:-}" ;;
  attach|a) attach_session "${2:-}" ;;
  open|o) open_session "${2:-}" ;;
  kill|rm|delete) kill_session "${2:-}" ;;
  rename|mv) rename_session "${2:-}" "${3:-}" ;;
  current) current_session ;;
  detach|background|bg) detach_session ;;
  kill-all) kill_all ;;
  keys|shortcuts) keys_text ;;
  doctor|check) doctor ;;
  version|-v|--version) echo "AON $AON_VERSION — by $AON_AUTHOR" ;;
  help) help_router "${2:-}" ;;
  -h|--help) full_help ;;
  *) echo "Unknown AON command: $1"; echo; quick_help; exit 1 ;;
esac
AON

run_root install -m 0755 "$TMP_AON" "$AON_BIN"
rm -f "$TMP_AON"

info "[4/11] Configuring tmux..."

touch "$TARGET_HOME/.tmux.conf"
sed -i.bak '/# >>> AON CONFIG >>>/,/# <<< AON CONFIG <<</d' "$TARGET_HOME/.tmux.conf" 2>/dev/null || true

cat >> "$TARGET_HOME/.tmux.conf" <<'TMUX'

# >>> AON CONFIG >>>

set -g default-terminal "tmux-256color"
set -g mouse on
set -g history-limit 100000
set -sg escape-time 10
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g exit-empty off
set -g focus-events on
set -g set-clipboard on

# AON shortcuts
bind-key -n F4 resize-pane -Z
bind-key -n F5 new-window -c "#{pane_current_path}"
bind-key -n F6 detach-client
bind-key -n F7 previous-window
bind-key -n F8 next-window
bind-key -n F9 split-window -h -c "#{pane_current_path}"
bind-key -n F10 split-window -v -c "#{pane_current_path}"
bind-key -n F11 confirm-before -p "Close pane? (y/n)" kill-pane
bind-key -n F12 confirm-before -p "Close window? (y/n)" kill-window

# Direct window access
bind-key -n M-1 select-window -t 1
bind-key -n M-2 select-window -t 2
bind-key -n M-3 select-window -t 3
bind-key -n M-4 select-window -t 4
bind-key -n M-5 select-window -t 5
bind-key -n M-6 select-window -t 6
bind-key -n M-7 select-window -t 7
bind-key -n M-8 select-window -t 8
bind-key -n M-9 select-window -t 9

# Pane navigation
bind-key -n M-Left  select-pane -L
bind-key -n M-Right select-pane -R
bind-key -n M-Up    select-pane -U
bind-key -n M-Down  select-pane -D

# Mouse
bind-key -n MouseDown1Pane select-pane -t= \; send-keys -M
bind-key -n MouseDown1Status select-window -t=

# Pane resize
bind-key -n S-Left  resize-pane -L 5
bind-key -n S-Right resize-pane -R 5
bind-key -n S-Up    resize-pane -U 2
bind-key -n S-Down  resize-pane -D 2

# tmux fallbacks
bind-key c new-window -c "#{pane_current_path}"
bind-key d detach-client
bind-key n next-window
bind-key p previous-window
bind-key '%' split-window -h -c "#{pane_current_path}"
bind-key '"' split-window -v -c "#{pane_current_path}"
bind-key r source-file ~/.tmux.conf \; display-message "AON configuration reloaded"

# Status bar
set -g status on
set -g status-interval 5
set -g status-left-length 60
set -g status-right-length 100
set -g status-left '#[bold] AON #[default] #S '
setw -g window-status-format ' #I:#W '
setw -g window-status-current-format ' [#I:#W] '
set -g status-right '#H | %Y-%m-%d %H:%M '
set -g set-titles on
set -g set-titles-string 'AON | #S | #I:#W'

# <<< AON CONFIG <<<
TMUX

info "[5/11] Configuring Byobu when available..."

if command -v byobu >/dev/null 2>&1; then
  mkdir -p "$TARGET_HOME/.byobu"
  touch "$TARGET_HOME/.byobu/keybindings.tmux"
  sed -i.bak '/# >>> AON BYOBU >>>/,/# <<< AON BYOBU <<</d' "$TARGET_HOME/.byobu/keybindings.tmux" 2>/dev/null || true

  cat >> "$TARGET_HOME/.byobu/keybindings.tmux" <<'BYOBU'

# >>> AON BYOBU >>>
bind-key -n F4 resize-pane -Z
bind-key -n F5 new-window -c "#{pane_current_path}"
bind-key -n F6 detach-client
bind-key -n F7 previous-window
bind-key -n F8 next-window
bind-key -n F9 split-window -h -c "#{pane_current_path}"
bind-key -n F10 split-window -v -c "#{pane_current_path}"
bind-key -n F11 confirm-before -p "Close pane? (y/n)" kill-pane
bind-key -n F12 confirm-before -p "Close window? (y/n)" kill-window
# <<< AON BYOBU <<<
BYOBU
fi

info "[6/11] Installing Bash completion..."

if [ "$HOST_OS" = "linux" ]; then
  BASH_COMPLETION_FILE="/etc/bash_completion.d/aon"
else
  mkdir -p "$TARGET_HOME/.aon"
  BASH_COMPLETION_FILE="$TARGET_HOME/.aon/aon.bash"
fi

TMP_BASH_COMP="$(mktemp)"
cat > "$TMP_BASH_COMP" <<'BASHCOMP'
_aon_sessions() {
  tmux list-sessions -F '#{session_name}' 2>/dev/null
}

_aon_completion() {
  local cur
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"

  local commands="list new attach open kill rename current detach bg background kill-all keys doctor version help"

  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
    return
  fi

  case "${COMP_WORDS[1]}" in
    attach|a|open|o|kill|rm|delete)
      COMPREPLY=( $(compgen -W "$(_aon_sessions)" -- "$cur") )
      ;;
    rename|mv)
      [ "$COMP_CWORD" -eq 2 ] && COMPREPLY=( $(compgen -W "$(_aon_sessions)" -- "$cur") )
      ;;
    help)
      COMPREPLY=( $(compgen -W "-- --full --keys --commands --mac --windows --linux" -- "$cur") )
      ;;
  esac
}

complete -F _aon_completion aon
BASHCOMP

if [ "$HOST_OS" = "linux" ]; then
  run_root install -m 0644 "$TMP_BASH_COMP" "$BASH_COMPLETION_FILE"
else
  cp "$TMP_BASH_COMP" "$BASH_COMPLETION_FILE"
fi
rm -f "$TMP_BASH_COMP"

info "[7/11] Installing Zsh completion..."

mkdir -p "$TARGET_HOME/.aon"
cat > "$TARGET_HOME/.aon/completion.zsh" <<'ZSHCOMP'
_aon_sessions() {
  local -a sessions
  sessions=("${(@f)$(tmux list-sessions -F '#{session_name}' 2>/dev/null)}")
  _describe 'AON sessions' sessions
}

_aon() {
  local state
  _arguments '1:command:->commands' '*:argument:->arguments'

  case "$state" in
    commands)
      local -a commands
      commands=(
        'list:List sessions'
        'new:Create session'
        'attach:Attach session'
        'open:Attach or create session'
        'kill:Stop session'
        'rename:Rename session'
        'current:Show current session'
        'detach:Run session in background'
        'bg:Run session in background'
        'background:Run session in background'
        'kill-all:Stop all sessions'
        'keys:Show shortcuts'
        'doctor:Check installation'
        'version:Show version'
        'help:Show help'
      )
      _describe 'AON command' commands
      ;;
    arguments)
      case "${words[2]}" in
        attach|a|open|o|kill|rm|delete) _aon_sessions ;;
        rename|mv) (( CURRENT == 3 )) && _aon_sessions ;;
      esac
      ;;
  esac
}

compdef _aon aon
ZSHCOMP

info "[8/11] Configuring shell integration..."

touch "$TARGET_HOME/.bashrc"
sed -i.bak '/# >>> AON SHELL >>>/,/# <<< AON SHELL <<</d' "$TARGET_HOME/.bashrc" 2>/dev/null || true

cat >> "$TARGET_HOME/.bashrc" <<'BASHRC'

# >>> AON SHELL >>>

help() {
  if [ -n "${TMUX:-}" ] && [ "$(tmux show-options -qv @aon_session 2>/dev/null)" = "1" ]; then
    command aon help "$@"
  else
    builtin help "$@"
  fi
}

# <<< AON SHELL <<<
BASHRC

touch "$TARGET_HOME/.zshrc"
sed -i.bak '/# >>> AON SHELL >>>/,/# <<< AON SHELL <<</d' "$TARGET_HOME/.zshrc" 2>/dev/null || true

cat >> "$TARGET_HOME/.zshrc" <<'ZSHRC'

# >>> AON SHELL >>>

autoload -Uz compinit
compinit -i

if [ -f "$HOME/.aon/completion.zsh" ]; then
  source "$HOME/.aon/completion.zsh"
fi

help() {
  if [ -n "${TMUX:-}" ] && [ "$(tmux show-options -qv @aon_session 2>/dev/null)" = "1" ]; then
    command aon help "$@"
  else
    if whence run-help >/dev/null 2>&1; then
      run-help "$@"
    else
      print "help: no default Zsh help command is configured"
    fi
  fi
}

# <<< AON SHELL <<<
ZSHRC

if [ "$HOST_OS" = "macos" ]; then
  cat >> "$TARGET_HOME/.bashrc" <<'BASHMAC'

if [ -f "$HOME/.aon/aon.bash" ]; then
  source "$HOME/.aon/aon.bash"
fi
BASHMAC
fi

info "[9/11] Fixing permissions..."

if [ "$(id -u)" -eq 0 ]; then
  chown "$TARGET_USER:$TARGET_GROUP" "$TARGET_HOME/.tmux.conf" "$TARGET_HOME/.bashrc" "$TARGET_HOME/.zshrc"
  chown -R "$TARGET_USER:$TARGET_GROUP" "$TARGET_HOME/.aon"
  [ -d "$TARGET_HOME/.byobu" ] && chown -R "$TARGET_USER:$TARGET_GROUP" "$TARGET_HOME/.byobu"
fi

info "[10/11] Validating tmux configuration..."

if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
  sudo -u "$TARGET_USER" tmux -L aon-install-test -f "$TARGET_HOME/.tmux.conf" new-session -d -s aon-install-test
  sudo -u "$TARGET_USER" tmux -L aon-install-test kill-server
else
  tmux -L aon-install-test -f "$TARGET_HOME/.tmux.conf" new-session -d -s aon-install-test
  tmux -L aon-install-test kill-server
fi

info "[11/11] Final verification..."

"$AON_BIN" version
"$AON_BIN" doctor || true

# --------------------------------------------------
# AON OPTIONAL SETUP LAUNCHER
# --------------------------------------------------

if [ -t 0 ]; then
  echo
  printf "\033[1;36mOptional Server Setup\033[0m\n"
  printf "\033[2mAON core is installed. Everything below is optional.\033[0m\n"
  echo
  echo "Optional tools can include:"
  echo "  - Common CLI utilities"
  echo "  - GitHub CLI"
  echo "  - Node.js + npm"
  echo "  - Python + pip"
  echo "  - Claude Code"
  echo "  - OpenAI Codex"
  echo "  - Kimi Code CLI"
  echo "  - Telegram completion notifications"
  echo "  - NGINX / PM2 / UFW / Fail2ban / Docker"
  echo

  read -r -p "Run optional server setup now? [y/N]: " AON_OPTIONAL_SETUP

  if [[ "$AON_OPTIONAL_SETUP" =~ ^[Yy]$ ]]; then
    SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || true)"

    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/scripts/bootstrap.sh" ]; then
      bash "$SCRIPT_DIR/scripts/bootstrap.sh"
    else
      TMP_BOOTSTRAP="$(mktemp)"
      curl -fsSL https://raw.githubusercontent.com/pfix0/AON/main/scripts/bootstrap.sh -o "$TMP_BOOTSTRAP"
      bash "$TMP_BOOTSTRAP"
      rm -f "$TMP_BOOTSTRAP"
    fi
  else
    echo
    echo "Optional tools skipped."
    echo "Run later from the AON repository:"
    echo "  bash scripts/bootstrap.sh"
    echo
  fi
fi

cat <<EOF

${GREEN}${BOLD}AON installed successfully.${RESET}

Author:
  pfix0

Version:
  ${AON_VERSION}

Start:
  aon new project

List sessions:
  aon list

Return:
  aon attach project

Inside AON:
  help
  help --
  help --keys

Keyboard:
  F4   Zoom / unzoom current pane
  F5   New window
  F6   Background / Detach
  F7   Previous window
  F8   Next window
  F9   Split left/right
  F10  Split top/bottom
  F11  Close pane
  F12  Close window

Open a new shell before first use, or run:
  source ~/.bashrc
or:
  source ~/.zshrc

EOF
