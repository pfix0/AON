#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_USER="$USER"
TARGET_HOME="$HOME"
HOST_OS="$(uname -s)"

if [ -t 1 ]; then
  RESET=
else
  RESET=''; BOLD=''; DIM=''; GREEN=''; YELLOW=''; CYAN=''; MAGENTA=''; RED=''
fi

line()    { printf '%b\n' "$DIM------------------------------------------------------------$RESET"; }
title()   { printf '\n%b\n' "$BOLD$MAGENTA$*$RESET"; line; }
info()    { printf '%b\n' "$CYAN›$RESET $*"; }
ok()      { printf '%b\n' "$GREEN✓$RESET $*"; }
warn()    { printf '%b\n' "$YELLOW!$RESET $*"; }
die()     { printf '%b\n' "$RED✗$RESET $*" >&2; exit 1; }

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "sudo is required for this component."
  fi
}

if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
  TARGET_USER="$SUDO_USER"
  TARGET_HOME="$(eval echo "~$TARGET_USER")"
fi

run_user() {
  if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
    sudo -H -u "$TARGET_USER" "$@"
  else
    "$@"
  fi
}

pkg_install() {
  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    run_root dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    run_root yum install -y "$@"
  elif command -v pacman >/dev/null 2>&1; then
    run_root pacman -S --noconfirm --needed "$@"
  elif command -v zypper >/dev/null 2>&1; then
    run_root zypper --non-interactive install "$@"
  elif command -v brew >/dev/null 2>&1; then
    brew install "$@"
  else
    return 1
  fi
}

install_common_tools() {
  title "Common CLI Tools"

  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get update -y
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync build-essential
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync base-devel
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v brew >/dev/null 2>&1; then
    brew install jq ripgrep fzf htop btop tree coreutils || true
  fi

  ok "Common CLI tools are ready."
}

install_github_cli() {
  title "GitHub CLI"

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI is already installed."
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install gh
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install github-cli || true
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install gh || true
  fi

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI installed."
    info "Connect your GitHub account later with: gh auth login"
  else
    warn "GitHub CLI was not available from the current package source."
    info "Official site: https://cli.github.com/"
  fi
}

install_node() {
  title "Node.js + npm"

  if command -v node >/dev/null 2>&1; then
    ok "Node.js is already installed: $(node --version)"
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install node
  else
    pkg_install nodejs npm
  fi

  command -v node >/dev/null 2>&1 && ok "Node.js installed: $(node --version)"
}

install_python() {
  title "Python"

  if command -v brew >/dev/null 2>&1; then
    brew install python
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install python3 python3-pip python3-venv
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install python python-pip
  else
    pkg_install python3 python3-pip
  fi

  if command -v python3 >/dev/null 2>&1; then
    ok "Python installed: $(python3 --version)"
  elif command -v python >/dev/null 2>&1; then
    ok "Python installed: $(python --version)"
  fi
}

install_claude() {
  title "Claude Code"

  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://claude.ai/install.sh | bash'
  ok "Claude Code installer completed."
  info "Open a new shell and run: claude"
}

install_codex() {
  title "OpenAI Codex"

  if command -v codex >/dev/null 2>&1; then
    ok "Codex is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://chatgpt.com/codex/install.sh | sh'
  ok "Codex installer completed."
  info "Open a new shell and run: codex"
}

install_kimi() {
  title "Kimi Code CLI"

  if command -v kimi >/dev/null 2>&1; then
    ok "Kimi is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash'
  ok "Kimi Code CLI installer completed."
  info "Open a new shell and run: kimi"
}

install_nginx() {
  title "NGINX"
  pkg_install nginx
  ok "NGINX installed."
}

install_pm2() {
  title "PM2"
  command -v npm >/dev/null 2>&1 || install_node
  run_root npm install -g pm2
  ok "PM2 installed."
}

install_ufw() {
  title "UFW"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "UFW is Linux-only."
    return
  fi

  pkg_install ufw || warn "UFW is not available from this package source."
}

install_fail2ban() {
  title "Fail2ban"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "Fail2ban is intended for Linux servers."
    return
  fi

  pkg_install fail2ban || warn "Fail2ban is not available from this package source."
}

install_docker() {
  title "Docker Engine"

  if [ "$HOST_OS" != "Linux" ]; then
    warn "This Docker Engine bootstrap is Linux-only."
    info "Use Docker Desktop on macOS."
    return
  fi

  if command -v docker >/dev/null 2>&1; then
    ok "Docker is already installed."
    return
  fi

  curl -fsSL https://get.docker.com -o /tmp/aon-get-docker.sh
  run_root sh /tmp/aon-get-docker.sh
  rm -f /tmp/aon-get-docker.sh
  ok "Docker Engine installed."
}

install_notify_bridge() {
  title "AON Telegram Notifications"

  local source_file="$REPO_ROOT/scripts/aon-notify.sh"

  if [ ! -f "$source_file" ]; then
    source_file="/tmp/aon-notify.sh"
    curl -fsSL https://raw.githubusercontent.com/pfix0/AON/main/scripts/aon-notify.sh -o "$source_file"
  fi

  run_root install -m 0755 "$source_file" /usr/local/bin/aon-notify
  ok "aon-notify installed."

  read -r -p "Configure Telegram Bot Token and Chat ID now? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    run_user /usr/local/bin/aon-notify setup
  else
    info "Configure later with: aon-notify setup"
  fi
}

selection_has() {
  local needle="$1"
  case ",$SELECTION," in
    *",$needle,"*) return 0 ;;
    *) return 1 ;;
  esac
}

run_custom() {
  selection_has 1 && install_common_tools
  selection_has 2 && install_github_cli
  selection_has 3 && install_node
  selection_has 4 && install_python
  selection_has 5 && install_claude
  selection_has 6 && install_codex
  selection_has 7 && install_kimi
  selection_has 8 && install_notify_bridge
  selection_has 9 && install_nginx
  selection_has 10 && install_pm2
  selection_has 11 && install_ufw
  selection_has 12 && install_fail2ban
  selection_has 13 && install_docker
}

printf '\n%b\n' "$BOLD$GREEN AON Optional Server Setup $RESET"
line
printf '%b\n' "$DIM AON core is already installed. Everything here is optional. $RESET"
echo

cat <<MENU
$GREEN 1) Minimal $RESET
    AON only. Install nothing else.

$CYAN 2) AI Builder $RESET
    Common CLI tools
    GitHub CLI
    Node.js + npm
    Python + pip
    Claude Code
    OpenAI Codex
    Kimi Code CLI
    Optional Telegram notifications

$MAGENTA 3) Server Developer $RESET
    Everything in AI Builder
    NGINX
    PM2
    UFW
    Fail2ban
    Optional Docker
    Optional Telegram notifications

$YELLOW 4) Custom $RESET
    Choose components individually.
MENU

read -r -p "Profile [1-4, default 1]: " PROFILE
[ -n "$PROFILE" ] || PROFILE=1

case "$PROFILE" in
  1)
    ok "Minimal selected. No optional tools installed."
    ;;

  2)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  3)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi
    install_nginx
    install_pm2
    install_ufw
    install_fail2ban

    read -r -p "Install Docker Engine? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_docker || true

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  4)
    cat <<CUSTOM

Choose comma-separated component numbers:

  1  Common CLI tools       8  Telegram notifications
  2  GitHub CLI             9  NGINX
  3  Node.js + npm         10  PM2
  4  Python + pip          11  UFW
  5  Claude Code           12  Fail2ban
  6  OpenAI Codex          13  Docker Engine
  7  Kimi Code CLI

Example:
  1,2,3,4,5,6,7,8

CUSTOM

    read -r -p "Selection: " SELECTION
    SELECTION="$(printf '%s' "$SELECTION" | tr -d ' ')"
    run_custom
    ;;

  *)
    warn "Unknown profile. Nothing optional was installed."
    ;;
esac

echo
line
ok "Optional server setup finished."
\033[0m'
  BOLD=
else
  RESET=''; BOLD=''; DIM=''; GREEN=''; YELLOW=''; CYAN=''; MAGENTA=''; RED=''
fi

line()    { printf '%b\n' "$DIM------------------------------------------------------------$RESET"; }
title()   { printf '\n%b\n' "$BOLD$MAGENTA$*$RESET"; line; }
info()    { printf '%b\n' "$CYAN›$RESET $*"; }
ok()      { printf '%b\n' "$GREEN✓$RESET $*"; }
warn()    { printf '%b\n' "$YELLOW!$RESET $*"; }
die()     { printf '%b\n' "$RED✗$RESET $*" >&2; exit 1; }

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "sudo is required for this component."
  fi
}

if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
  TARGET_USER="$SUDO_USER"
  TARGET_HOME="$(eval echo "~$TARGET_USER")"
fi

run_user() {
  if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
    sudo -H -u "$TARGET_USER" "$@"
  else
    "$@"
  fi
}

pkg_install() {
  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    run_root dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    run_root yum install -y "$@"
  elif command -v pacman >/dev/null 2>&1; then
    run_root pacman -S --noconfirm --needed "$@"
  elif command -v zypper >/dev/null 2>&1; then
    run_root zypper --non-interactive install "$@"
  elif command -v brew >/dev/null 2>&1; then
    brew install "$@"
  else
    return 1
  fi
}

install_common_tools() {
  title "Common CLI Tools"

  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get update -y
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync build-essential
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync base-devel
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v brew >/dev/null 2>&1; then
    brew install jq ripgrep fzf htop btop tree coreutils || true
  fi

  ok "Common CLI tools are ready."
}

install_github_cli() {
  title "GitHub CLI"

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI is already installed."
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install gh
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install github-cli || true
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install gh || true
  fi

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI installed."
    info "Connect your GitHub account later with: gh auth login"
  else
    warn "GitHub CLI was not available from the current package source."
    info "Official site: https://cli.github.com/"
  fi
}

install_node() {
  title "Node.js + npm"

  if command -v node >/dev/null 2>&1; then
    ok "Node.js is already installed: $(node --version)"
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install node
  else
    pkg_install nodejs npm
  fi

  command -v node >/dev/null 2>&1 && ok "Node.js installed: $(node --version)"
}

install_python() {
  title "Python"

  if command -v brew >/dev/null 2>&1; then
    brew install python
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install python3 python3-pip python3-venv
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install python python-pip
  else
    pkg_install python3 python3-pip
  fi

  if command -v python3 >/dev/null 2>&1; then
    ok "Python installed: $(python3 --version)"
  elif command -v python >/dev/null 2>&1; then
    ok "Python installed: $(python --version)"
  fi
}

install_claude() {
  title "Claude Code"

  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://claude.ai/install.sh | bash'
  ok "Claude Code installer completed."
  info "Open a new shell and run: claude"
}

install_codex() {
  title "OpenAI Codex"

  if command -v codex >/dev/null 2>&1; then
    ok "Codex is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://chatgpt.com/codex/install.sh | sh'
  ok "Codex installer completed."
  info "Open a new shell and run: codex"
}

install_kimi() {
  title "Kimi Code CLI"

  if command -v kimi >/dev/null 2>&1; then
    ok "Kimi is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash'
  ok "Kimi Code CLI installer completed."
  info "Open a new shell and run: kimi"
}

install_nginx() {
  title "NGINX"
  pkg_install nginx
  ok "NGINX installed."
}

install_pm2() {
  title "PM2"
  command -v npm >/dev/null 2>&1 || install_node
  run_root npm install -g pm2
  ok "PM2 installed."
}

install_ufw() {
  title "UFW"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "UFW is Linux-only."
    return
  fi

  pkg_install ufw || warn "UFW is not available from this package source."
}

install_fail2ban() {
  title "Fail2ban"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "Fail2ban is intended for Linux servers."
    return
  fi

  pkg_install fail2ban || warn "Fail2ban is not available from this package source."
}

install_docker() {
  title "Docker Engine"

  if [ "$HOST_OS" != "Linux" ]; then
    warn "This Docker Engine bootstrap is Linux-only."
    info "Use Docker Desktop on macOS."
    return
  fi

  if command -v docker >/dev/null 2>&1; then
    ok "Docker is already installed."
    return
  fi

  curl -fsSL https://get.docker.com -o /tmp/aon-get-docker.sh
  run_root sh /tmp/aon-get-docker.sh
  rm -f /tmp/aon-get-docker.sh
  ok "Docker Engine installed."
}

install_notify_bridge() {
  title "AON Telegram Notifications"

  local source_file="$REPO_ROOT/scripts/aon-notify.sh"

  if [ ! -f "$source_file" ]; then
    source_file="/tmp/aon-notify.sh"
    curl -fsSL https://raw.githubusercontent.com/pfix0/AON/main/scripts/aon-notify.sh -o "$source_file"
  fi

  run_root install -m 0755 "$source_file" /usr/local/bin/aon-notify
  ok "aon-notify installed."

  read -r -p "Configure Telegram Bot Token and Chat ID now? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    run_user /usr/local/bin/aon-notify setup
  else
    info "Configure later with: aon-notify setup"
  fi
}

selection_has() {
  local needle="$1"
  case ",$SELECTION," in
    *",$needle,"*) return 0 ;;
    *) return 1 ;;
  esac
}

run_custom() {
  selection_has 1 && install_common_tools
  selection_has 2 && install_github_cli
  selection_has 3 && install_node
  selection_has 4 && install_python
  selection_has 5 && install_claude
  selection_has 6 && install_codex
  selection_has 7 && install_kimi
  selection_has 8 && install_notify_bridge
  selection_has 9 && install_nginx
  selection_has 10 && install_pm2
  selection_has 11 && install_ufw
  selection_has 12 && install_fail2ban
  selection_has 13 && install_docker
}

printf '\n%b\n' "$BOLD$GREEN AON Optional Server Setup $RESET"
line
printf '%b\n' "$DIM AON core is already installed. Everything here is optional. $RESET"
echo

cat <<MENU
$GREEN 1) Minimal $RESET
    AON only. Install nothing else.

$CYAN 2) AI Builder $RESET
    Common CLI tools
    GitHub CLI
    Node.js + npm
    Python + pip
    Claude Code
    OpenAI Codex
    Kimi Code CLI
    Optional Telegram notifications

$MAGENTA 3) Server Developer $RESET
    Everything in AI Builder
    NGINX
    PM2
    UFW
    Fail2ban
    Optional Docker
    Optional Telegram notifications

$YELLOW 4) Custom $RESET
    Choose components individually.
MENU

read -r -p "Profile [1-4, default 1]: " PROFILE
[ -n "$PROFILE" ] || PROFILE=1

case "$PROFILE" in
  1)
    ok "Minimal selected. No optional tools installed."
    ;;

  2)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  3)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi
    install_nginx
    install_pm2
    install_ufw
    install_fail2ban

    read -r -p "Install Docker Engine? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_docker || true

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  4)
    cat <<CUSTOM

Choose comma-separated component numbers:

  1  Common CLI tools       8  Telegram notifications
  2  GitHub CLI             9  NGINX
  3  Node.js + npm         10  PM2
  4  Python + pip          11  UFW
  5  Claude Code           12  Fail2ban
  6  OpenAI Codex          13  Docker Engine
  7  Kimi Code CLI

Example:
  1,2,3,4,5,6,7,8

CUSTOM

    read -r -p "Selection: " SELECTION
    SELECTION="$(printf '%s' "$SELECTION" | tr -d ' ')"
    run_custom
    ;;

  *)
    warn "Unknown profile. Nothing optional was installed."
    ;;
esac

echo
line
ok "Optional server setup finished."
\033[1m'
  DIM=
else
  RESET=''; BOLD=''; DIM=''; GREEN=''; YELLOW=''; CYAN=''; MAGENTA=''; RED=''
fi

line()    { printf '%b\n' "$DIM------------------------------------------------------------$RESET"; }
title()   { printf '\n%b\n' "$BOLD$MAGENTA$*$RESET"; line; }
info()    { printf '%b\n' "$CYAN›$RESET $*"; }
ok()      { printf '%b\n' "$GREEN✓$RESET $*"; }
warn()    { printf '%b\n' "$YELLOW!$RESET $*"; }
die()     { printf '%b\n' "$RED✗$RESET $*" >&2; exit 1; }

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "sudo is required for this component."
  fi
}

if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
  TARGET_USER="$SUDO_USER"
  TARGET_HOME="$(eval echo "~$TARGET_USER")"
fi

run_user() {
  if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
    sudo -H -u "$TARGET_USER" "$@"
  else
    "$@"
  fi
}

pkg_install() {
  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    run_root dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    run_root yum install -y "$@"
  elif command -v pacman >/dev/null 2>&1; then
    run_root pacman -S --noconfirm --needed "$@"
  elif command -v zypper >/dev/null 2>&1; then
    run_root zypper --non-interactive install "$@"
  elif command -v brew >/dev/null 2>&1; then
    brew install "$@"
  else
    return 1
  fi
}

install_common_tools() {
  title "Common CLI Tools"

  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get update -y
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync build-essential
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync base-devel
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v brew >/dev/null 2>&1; then
    brew install jq ripgrep fzf htop btop tree coreutils || true
  fi

  ok "Common CLI tools are ready."
}

install_github_cli() {
  title "GitHub CLI"

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI is already installed."
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install gh
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install github-cli || true
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install gh || true
  fi

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI installed."
    info "Connect your GitHub account later with: gh auth login"
  else
    warn "GitHub CLI was not available from the current package source."
    info "Official site: https://cli.github.com/"
  fi
}

install_node() {
  title "Node.js + npm"

  if command -v node >/dev/null 2>&1; then
    ok "Node.js is already installed: $(node --version)"
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install node
  else
    pkg_install nodejs npm
  fi

  command -v node >/dev/null 2>&1 && ok "Node.js installed: $(node --version)"
}

install_python() {
  title "Python"

  if command -v brew >/dev/null 2>&1; then
    brew install python
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install python3 python3-pip python3-venv
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install python python-pip
  else
    pkg_install python3 python3-pip
  fi

  if command -v python3 >/dev/null 2>&1; then
    ok "Python installed: $(python3 --version)"
  elif command -v python >/dev/null 2>&1; then
    ok "Python installed: $(python --version)"
  fi
}

install_claude() {
  title "Claude Code"

  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://claude.ai/install.sh | bash'
  ok "Claude Code installer completed."
  info "Open a new shell and run: claude"
}

install_codex() {
  title "OpenAI Codex"

  if command -v codex >/dev/null 2>&1; then
    ok "Codex is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://chatgpt.com/codex/install.sh | sh'
  ok "Codex installer completed."
  info "Open a new shell and run: codex"
}

install_kimi() {
  title "Kimi Code CLI"

  if command -v kimi >/dev/null 2>&1; then
    ok "Kimi is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash'
  ok "Kimi Code CLI installer completed."
  info "Open a new shell and run: kimi"
}

install_nginx() {
  title "NGINX"
  pkg_install nginx
  ok "NGINX installed."
}

install_pm2() {
  title "PM2"
  command -v npm >/dev/null 2>&1 || install_node
  run_root npm install -g pm2
  ok "PM2 installed."
}

install_ufw() {
  title "UFW"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "UFW is Linux-only."
    return
  fi

  pkg_install ufw || warn "UFW is not available from this package source."
}

install_fail2ban() {
  title "Fail2ban"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "Fail2ban is intended for Linux servers."
    return
  fi

  pkg_install fail2ban || warn "Fail2ban is not available from this package source."
}

install_docker() {
  title "Docker Engine"

  if [ "$HOST_OS" != "Linux" ]; then
    warn "This Docker Engine bootstrap is Linux-only."
    info "Use Docker Desktop on macOS."
    return
  fi

  if command -v docker >/dev/null 2>&1; then
    ok "Docker is already installed."
    return
  fi

  curl -fsSL https://get.docker.com -o /tmp/aon-get-docker.sh
  run_root sh /tmp/aon-get-docker.sh
  rm -f /tmp/aon-get-docker.sh
  ok "Docker Engine installed."
}

install_notify_bridge() {
  title "AON Telegram Notifications"

  local source_file="$REPO_ROOT/scripts/aon-notify.sh"

  if [ ! -f "$source_file" ]; then
    source_file="/tmp/aon-notify.sh"
    curl -fsSL https://raw.githubusercontent.com/pfix0/AON/main/scripts/aon-notify.sh -o "$source_file"
  fi

  run_root install -m 0755 "$source_file" /usr/local/bin/aon-notify
  ok "aon-notify installed."

  read -r -p "Configure Telegram Bot Token and Chat ID now? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    run_user /usr/local/bin/aon-notify setup
  else
    info "Configure later with: aon-notify setup"
  fi
}

selection_has() {
  local needle="$1"
  case ",$SELECTION," in
    *",$needle,"*) return 0 ;;
    *) return 1 ;;
  esac
}

run_custom() {
  selection_has 1 && install_common_tools
  selection_has 2 && install_github_cli
  selection_has 3 && install_node
  selection_has 4 && install_python
  selection_has 5 && install_claude
  selection_has 6 && install_codex
  selection_has 7 && install_kimi
  selection_has 8 && install_notify_bridge
  selection_has 9 && install_nginx
  selection_has 10 && install_pm2
  selection_has 11 && install_ufw
  selection_has 12 && install_fail2ban
  selection_has 13 && install_docker
}

printf '\n%b\n' "$BOLD$GREEN AON Optional Server Setup $RESET"
line
printf '%b\n' "$DIM AON core is already installed. Everything here is optional. $RESET"
echo

cat <<MENU
$GREEN 1) Minimal $RESET
    AON only. Install nothing else.

$CYAN 2) AI Builder $RESET
    Common CLI tools
    GitHub CLI
    Node.js + npm
    Python + pip
    Claude Code
    OpenAI Codex
    Kimi Code CLI
    Optional Telegram notifications

$MAGENTA 3) Server Developer $RESET
    Everything in AI Builder
    NGINX
    PM2
    UFW
    Fail2ban
    Optional Docker
    Optional Telegram notifications

$YELLOW 4) Custom $RESET
    Choose components individually.
MENU

read -r -p "Profile [1-4, default 1]: " PROFILE
[ -n "$PROFILE" ] || PROFILE=1

case "$PROFILE" in
  1)
    ok "Minimal selected. No optional tools installed."
    ;;

  2)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  3)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi
    install_nginx
    install_pm2
    install_ufw
    install_fail2ban

    read -r -p "Install Docker Engine? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_docker || true

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  4)
    cat <<CUSTOM

Choose comma-separated component numbers:

  1  Common CLI tools       8  Telegram notifications
  2  GitHub CLI             9  NGINX
  3  Node.js + npm         10  PM2
  4  Python + pip          11  UFW
  5  Claude Code           12  Fail2ban
  6  OpenAI Codex          13  Docker Engine
  7  Kimi Code CLI

Example:
  1,2,3,4,5,6,7,8

CUSTOM

    read -r -p "Selection: " SELECTION
    SELECTION="$(printf '%s' "$SELECTION" | tr -d ' ')"
    run_custom
    ;;

  *)
    warn "Unknown profile. Nothing optional was installed."
    ;;
esac

echo
line
ok "Optional server setup finished."
\033[2m'
  GREEN=
else
  RESET=''; BOLD=''; DIM=''; GREEN=''; YELLOW=''; CYAN=''; MAGENTA=''; RED=''
fi

line()    { printf '%b\n' "$DIM------------------------------------------------------------$RESET"; }
title()   { printf '\n%b\n' "$BOLD$MAGENTA$*$RESET"; line; }
info()    { printf '%b\n' "$CYAN›$RESET $*"; }
ok()      { printf '%b\n' "$GREEN✓$RESET $*"; }
warn()    { printf '%b\n' "$YELLOW!$RESET $*"; }
die()     { printf '%b\n' "$RED✗$RESET $*" >&2; exit 1; }

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "sudo is required for this component."
  fi
}

if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
  TARGET_USER="$SUDO_USER"
  TARGET_HOME="$(eval echo "~$TARGET_USER")"
fi

run_user() {
  if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
    sudo -H -u "$TARGET_USER" "$@"
  else
    "$@"
  fi
}

pkg_install() {
  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    run_root dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    run_root yum install -y "$@"
  elif command -v pacman >/dev/null 2>&1; then
    run_root pacman -S --noconfirm --needed "$@"
  elif command -v zypper >/dev/null 2>&1; then
    run_root zypper --non-interactive install "$@"
  elif command -v brew >/dev/null 2>&1; then
    brew install "$@"
  else
    return 1
  fi
}

install_common_tools() {
  title "Common CLI Tools"

  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get update -y
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync build-essential
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync base-devel
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v brew >/dev/null 2>&1; then
    brew install jq ripgrep fzf htop btop tree coreutils || true
  fi

  ok "Common CLI tools are ready."
}

install_github_cli() {
  title "GitHub CLI"

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI is already installed."
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install gh
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install github-cli || true
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install gh || true
  fi

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI installed."
    info "Connect your GitHub account later with: gh auth login"
  else
    warn "GitHub CLI was not available from the current package source."
    info "Official site: https://cli.github.com/"
  fi
}

install_node() {
  title "Node.js + npm"

  if command -v node >/dev/null 2>&1; then
    ok "Node.js is already installed: $(node --version)"
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install node
  else
    pkg_install nodejs npm
  fi

  command -v node >/dev/null 2>&1 && ok "Node.js installed: $(node --version)"
}

install_python() {
  title "Python"

  if command -v brew >/dev/null 2>&1; then
    brew install python
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install python3 python3-pip python3-venv
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install python python-pip
  else
    pkg_install python3 python3-pip
  fi

  if command -v python3 >/dev/null 2>&1; then
    ok "Python installed: $(python3 --version)"
  elif command -v python >/dev/null 2>&1; then
    ok "Python installed: $(python --version)"
  fi
}

install_claude() {
  title "Claude Code"

  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://claude.ai/install.sh | bash'
  ok "Claude Code installer completed."
  info "Open a new shell and run: claude"
}

install_codex() {
  title "OpenAI Codex"

  if command -v codex >/dev/null 2>&1; then
    ok "Codex is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://chatgpt.com/codex/install.sh | sh'
  ok "Codex installer completed."
  info "Open a new shell and run: codex"
}

install_kimi() {
  title "Kimi Code CLI"

  if command -v kimi >/dev/null 2>&1; then
    ok "Kimi is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash'
  ok "Kimi Code CLI installer completed."
  info "Open a new shell and run: kimi"
}

install_nginx() {
  title "NGINX"
  pkg_install nginx
  ok "NGINX installed."
}

install_pm2() {
  title "PM2"
  command -v npm >/dev/null 2>&1 || install_node
  run_root npm install -g pm2
  ok "PM2 installed."
}

install_ufw() {
  title "UFW"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "UFW is Linux-only."
    return
  fi

  pkg_install ufw || warn "UFW is not available from this package source."
}

install_fail2ban() {
  title "Fail2ban"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "Fail2ban is intended for Linux servers."
    return
  fi

  pkg_install fail2ban || warn "Fail2ban is not available from this package source."
}

install_docker() {
  title "Docker Engine"

  if [ "$HOST_OS" != "Linux" ]; then
    warn "This Docker Engine bootstrap is Linux-only."
    info "Use Docker Desktop on macOS."
    return
  fi

  if command -v docker >/dev/null 2>&1; then
    ok "Docker is already installed."
    return
  fi

  curl -fsSL https://get.docker.com -o /tmp/aon-get-docker.sh
  run_root sh /tmp/aon-get-docker.sh
  rm -f /tmp/aon-get-docker.sh
  ok "Docker Engine installed."
}

install_notify_bridge() {
  title "AON Telegram Notifications"

  local source_file="$REPO_ROOT/scripts/aon-notify.sh"

  if [ ! -f "$source_file" ]; then
    source_file="/tmp/aon-notify.sh"
    curl -fsSL https://raw.githubusercontent.com/pfix0/AON/main/scripts/aon-notify.sh -o "$source_file"
  fi

  run_root install -m 0755 "$source_file" /usr/local/bin/aon-notify
  ok "aon-notify installed."

  read -r -p "Configure Telegram Bot Token and Chat ID now? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    run_user /usr/local/bin/aon-notify setup
  else
    info "Configure later with: aon-notify setup"
  fi
}

selection_has() {
  local needle="$1"
  case ",$SELECTION," in
    *",$needle,"*) return 0 ;;
    *) return 1 ;;
  esac
}

run_custom() {
  selection_has 1 && install_common_tools
  selection_has 2 && install_github_cli
  selection_has 3 && install_node
  selection_has 4 && install_python
  selection_has 5 && install_claude
  selection_has 6 && install_codex
  selection_has 7 && install_kimi
  selection_has 8 && install_notify_bridge
  selection_has 9 && install_nginx
  selection_has 10 && install_pm2
  selection_has 11 && install_ufw
  selection_has 12 && install_fail2ban
  selection_has 13 && install_docker
}

printf '\n%b\n' "$BOLD$GREEN AON Optional Server Setup $RESET"
line
printf '%b\n' "$DIM AON core is already installed. Everything here is optional. $RESET"
echo

cat <<MENU
$GREEN 1) Minimal $RESET
    AON only. Install nothing else.

$CYAN 2) AI Builder $RESET
    Common CLI tools
    GitHub CLI
    Node.js + npm
    Python + pip
    Claude Code
    OpenAI Codex
    Kimi Code CLI
    Optional Telegram notifications

$MAGENTA 3) Server Developer $RESET
    Everything in AI Builder
    NGINX
    PM2
    UFW
    Fail2ban
    Optional Docker
    Optional Telegram notifications

$YELLOW 4) Custom $RESET
    Choose components individually.
MENU

read -r -p "Profile [1-4, default 1]: " PROFILE
[ -n "$PROFILE" ] || PROFILE=1

case "$PROFILE" in
  1)
    ok "Minimal selected. No optional tools installed."
    ;;

  2)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  3)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi
    install_nginx
    install_pm2
    install_ufw
    install_fail2ban

    read -r -p "Install Docker Engine? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_docker || true

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  4)
    cat <<CUSTOM

Choose comma-separated component numbers:

  1  Common CLI tools       8  Telegram notifications
  2  GitHub CLI             9  NGINX
  3  Node.js + npm         10  PM2
  4  Python + pip          11  UFW
  5  Claude Code           12  Fail2ban
  6  OpenAI Codex          13  Docker Engine
  7  Kimi Code CLI

Example:
  1,2,3,4,5,6,7,8

CUSTOM

    read -r -p "Selection: " SELECTION
    SELECTION="$(printf '%s' "$SELECTION" | tr -d ' ')"
    run_custom
    ;;

  *)
    warn "Unknown profile. Nothing optional was installed."
    ;;
esac

echo
line
ok "Optional server setup finished."
\033[32m'
  YELLOW=
else
  RESET=''; BOLD=''; DIM=''; GREEN=''; YELLOW=''; CYAN=''; MAGENTA=''; RED=''
fi

line()    { printf '%b\n' "$DIM------------------------------------------------------------$RESET"; }
title()   { printf '\n%b\n' "$BOLD$MAGENTA$*$RESET"; line; }
info()    { printf '%b\n' "$CYAN›$RESET $*"; }
ok()      { printf '%b\n' "$GREEN✓$RESET $*"; }
warn()    { printf '%b\n' "$YELLOW!$RESET $*"; }
die()     { printf '%b\n' "$RED✗$RESET $*" >&2; exit 1; }

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "sudo is required for this component."
  fi
}

if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
  TARGET_USER="$SUDO_USER"
  TARGET_HOME="$(eval echo "~$TARGET_USER")"
fi

run_user() {
  if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
    sudo -H -u "$TARGET_USER" "$@"
  else
    "$@"
  fi
}

pkg_install() {
  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    run_root dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    run_root yum install -y "$@"
  elif command -v pacman >/dev/null 2>&1; then
    run_root pacman -S --noconfirm --needed "$@"
  elif command -v zypper >/dev/null 2>&1; then
    run_root zypper --non-interactive install "$@"
  elif command -v brew >/dev/null 2>&1; then
    brew install "$@"
  else
    return 1
  fi
}

install_common_tools() {
  title "Common CLI Tools"

  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get update -y
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync build-essential
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync base-devel
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v brew >/dev/null 2>&1; then
    brew install jq ripgrep fzf htop btop tree coreutils || true
  fi

  ok "Common CLI tools are ready."
}

install_github_cli() {
  title "GitHub CLI"

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI is already installed."
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install gh
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install github-cli || true
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install gh || true
  fi

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI installed."
    info "Connect your GitHub account later with: gh auth login"
  else
    warn "GitHub CLI was not available from the current package source."
    info "Official site: https://cli.github.com/"
  fi
}

install_node() {
  title "Node.js + npm"

  if command -v node >/dev/null 2>&1; then
    ok "Node.js is already installed: $(node --version)"
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install node
  else
    pkg_install nodejs npm
  fi

  command -v node >/dev/null 2>&1 && ok "Node.js installed: $(node --version)"
}

install_python() {
  title "Python"

  if command -v brew >/dev/null 2>&1; then
    brew install python
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install python3 python3-pip python3-venv
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install python python-pip
  else
    pkg_install python3 python3-pip
  fi

  if command -v python3 >/dev/null 2>&1; then
    ok "Python installed: $(python3 --version)"
  elif command -v python >/dev/null 2>&1; then
    ok "Python installed: $(python --version)"
  fi
}

install_claude() {
  title "Claude Code"

  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://claude.ai/install.sh | bash'
  ok "Claude Code installer completed."
  info "Open a new shell and run: claude"
}

install_codex() {
  title "OpenAI Codex"

  if command -v codex >/dev/null 2>&1; then
    ok "Codex is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://chatgpt.com/codex/install.sh | sh'
  ok "Codex installer completed."
  info "Open a new shell and run: codex"
}

install_kimi() {
  title "Kimi Code CLI"

  if command -v kimi >/dev/null 2>&1; then
    ok "Kimi is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash'
  ok "Kimi Code CLI installer completed."
  info "Open a new shell and run: kimi"
}

install_nginx() {
  title "NGINX"
  pkg_install nginx
  ok "NGINX installed."
}

install_pm2() {
  title "PM2"
  command -v npm >/dev/null 2>&1 || install_node
  run_root npm install -g pm2
  ok "PM2 installed."
}

install_ufw() {
  title "UFW"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "UFW is Linux-only."
    return
  fi

  pkg_install ufw || warn "UFW is not available from this package source."
}

install_fail2ban() {
  title "Fail2ban"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "Fail2ban is intended for Linux servers."
    return
  fi

  pkg_install fail2ban || warn "Fail2ban is not available from this package source."
}

install_docker() {
  title "Docker Engine"

  if [ "$HOST_OS" != "Linux" ]; then
    warn "This Docker Engine bootstrap is Linux-only."
    info "Use Docker Desktop on macOS."
    return
  fi

  if command -v docker >/dev/null 2>&1; then
    ok "Docker is already installed."
    return
  fi

  curl -fsSL https://get.docker.com -o /tmp/aon-get-docker.sh
  run_root sh /tmp/aon-get-docker.sh
  rm -f /tmp/aon-get-docker.sh
  ok "Docker Engine installed."
}

install_notify_bridge() {
  title "AON Telegram Notifications"

  local source_file="$REPO_ROOT/scripts/aon-notify.sh"

  if [ ! -f "$source_file" ]; then
    source_file="/tmp/aon-notify.sh"
    curl -fsSL https://raw.githubusercontent.com/pfix0/AON/main/scripts/aon-notify.sh -o "$source_file"
  fi

  run_root install -m 0755 "$source_file" /usr/local/bin/aon-notify
  ok "aon-notify installed."

  read -r -p "Configure Telegram Bot Token and Chat ID now? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    run_user /usr/local/bin/aon-notify setup
  else
    info "Configure later with: aon-notify setup"
  fi
}

selection_has() {
  local needle="$1"
  case ",$SELECTION," in
    *",$needle,"*) return 0 ;;
    *) return 1 ;;
  esac
}

run_custom() {
  selection_has 1 && install_common_tools
  selection_has 2 && install_github_cli
  selection_has 3 && install_node
  selection_has 4 && install_python
  selection_has 5 && install_claude
  selection_has 6 && install_codex
  selection_has 7 && install_kimi
  selection_has 8 && install_notify_bridge
  selection_has 9 && install_nginx
  selection_has 10 && install_pm2
  selection_has 11 && install_ufw
  selection_has 12 && install_fail2ban
  selection_has 13 && install_docker
}

printf '\n%b\n' "$BOLD$GREEN AON Optional Server Setup $RESET"
line
printf '%b\n' "$DIM AON core is already installed. Everything here is optional. $RESET"
echo

cat <<MENU
$GREEN 1) Minimal $RESET
    AON only. Install nothing else.

$CYAN 2) AI Builder $RESET
    Common CLI tools
    GitHub CLI
    Node.js + npm
    Python + pip
    Claude Code
    OpenAI Codex
    Kimi Code CLI
    Optional Telegram notifications

$MAGENTA 3) Server Developer $RESET
    Everything in AI Builder
    NGINX
    PM2
    UFW
    Fail2ban
    Optional Docker
    Optional Telegram notifications

$YELLOW 4) Custom $RESET
    Choose components individually.
MENU

read -r -p "Profile [1-4, default 1]: " PROFILE
[ -n "$PROFILE" ] || PROFILE=1

case "$PROFILE" in
  1)
    ok "Minimal selected. No optional tools installed."
    ;;

  2)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  3)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi
    install_nginx
    install_pm2
    install_ufw
    install_fail2ban

    read -r -p "Install Docker Engine? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_docker || true

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  4)
    cat <<CUSTOM

Choose comma-separated component numbers:

  1  Common CLI tools       8  Telegram notifications
  2  GitHub CLI             9  NGINX
  3  Node.js + npm         10  PM2
  4  Python + pip          11  UFW
  5  Claude Code           12  Fail2ban
  6  OpenAI Codex          13  Docker Engine
  7  Kimi Code CLI

Example:
  1,2,3,4,5,6,7,8

CUSTOM

    read -r -p "Selection: " SELECTION
    SELECTION="$(printf '%s' "$SELECTION" | tr -d ' ')"
    run_custom
    ;;

  *)
    warn "Unknown profile. Nothing optional was installed."
    ;;
esac

echo
line
ok "Optional server setup finished."
\033[33m'
  CYAN=
else
  RESET=''; BOLD=''; DIM=''; GREEN=''; YELLOW=''; CYAN=''; MAGENTA=''; RED=''
fi

line()    { printf '%b\n' "$DIM------------------------------------------------------------$RESET"; }
title()   { printf '\n%b\n' "$BOLD$MAGENTA$*$RESET"; line; }
info()    { printf '%b\n' "$CYAN›$RESET $*"; }
ok()      { printf '%b\n' "$GREEN✓$RESET $*"; }
warn()    { printf '%b\n' "$YELLOW!$RESET $*"; }
die()     { printf '%b\n' "$RED✗$RESET $*" >&2; exit 1; }

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "sudo is required for this component."
  fi
}

if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
  TARGET_USER="$SUDO_USER"
  TARGET_HOME="$(eval echo "~$TARGET_USER")"
fi

run_user() {
  if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
    sudo -H -u "$TARGET_USER" "$@"
  else
    "$@"
  fi
}

pkg_install() {
  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    run_root dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    run_root yum install -y "$@"
  elif command -v pacman >/dev/null 2>&1; then
    run_root pacman -S --noconfirm --needed "$@"
  elif command -v zypper >/dev/null 2>&1; then
    run_root zypper --non-interactive install "$@"
  elif command -v brew >/dev/null 2>&1; then
    brew install "$@"
  else
    return 1
  fi
}

install_common_tools() {
  title "Common CLI Tools"

  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get update -y
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync build-essential
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync base-devel
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v brew >/dev/null 2>&1; then
    brew install jq ripgrep fzf htop btop tree coreutils || true
  fi

  ok "Common CLI tools are ready."
}

install_github_cli() {
  title "GitHub CLI"

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI is already installed."
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install gh
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install github-cli || true
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install gh || true
  fi

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI installed."
    info "Connect your GitHub account later with: gh auth login"
  else
    warn "GitHub CLI was not available from the current package source."
    info "Official site: https://cli.github.com/"
  fi
}

install_node() {
  title "Node.js + npm"

  if command -v node >/dev/null 2>&1; then
    ok "Node.js is already installed: $(node --version)"
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install node
  else
    pkg_install nodejs npm
  fi

  command -v node >/dev/null 2>&1 && ok "Node.js installed: $(node --version)"
}

install_python() {
  title "Python"

  if command -v brew >/dev/null 2>&1; then
    brew install python
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install python3 python3-pip python3-venv
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install python python-pip
  else
    pkg_install python3 python3-pip
  fi

  if command -v python3 >/dev/null 2>&1; then
    ok "Python installed: $(python3 --version)"
  elif command -v python >/dev/null 2>&1; then
    ok "Python installed: $(python --version)"
  fi
}

install_claude() {
  title "Claude Code"

  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://claude.ai/install.sh | bash'
  ok "Claude Code installer completed."
  info "Open a new shell and run: claude"
}

install_codex() {
  title "OpenAI Codex"

  if command -v codex >/dev/null 2>&1; then
    ok "Codex is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://chatgpt.com/codex/install.sh | sh'
  ok "Codex installer completed."
  info "Open a new shell and run: codex"
}

install_kimi() {
  title "Kimi Code CLI"

  if command -v kimi >/dev/null 2>&1; then
    ok "Kimi is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash'
  ok "Kimi Code CLI installer completed."
  info "Open a new shell and run: kimi"
}

install_nginx() {
  title "NGINX"
  pkg_install nginx
  ok "NGINX installed."
}

install_pm2() {
  title "PM2"
  command -v npm >/dev/null 2>&1 || install_node
  run_root npm install -g pm2
  ok "PM2 installed."
}

install_ufw() {
  title "UFW"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "UFW is Linux-only."
    return
  fi

  pkg_install ufw || warn "UFW is not available from this package source."
}

install_fail2ban() {
  title "Fail2ban"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "Fail2ban is intended for Linux servers."
    return
  fi

  pkg_install fail2ban || warn "Fail2ban is not available from this package source."
}

install_docker() {
  title "Docker Engine"

  if [ "$HOST_OS" != "Linux" ]; then
    warn "This Docker Engine bootstrap is Linux-only."
    info "Use Docker Desktop on macOS."
    return
  fi

  if command -v docker >/dev/null 2>&1; then
    ok "Docker is already installed."
    return
  fi

  curl -fsSL https://get.docker.com -o /tmp/aon-get-docker.sh
  run_root sh /tmp/aon-get-docker.sh
  rm -f /tmp/aon-get-docker.sh
  ok "Docker Engine installed."
}

install_notify_bridge() {
  title "AON Telegram Notifications"

  local source_file="$REPO_ROOT/scripts/aon-notify.sh"

  if [ ! -f "$source_file" ]; then
    source_file="/tmp/aon-notify.sh"
    curl -fsSL https://raw.githubusercontent.com/pfix0/AON/main/scripts/aon-notify.sh -o "$source_file"
  fi

  run_root install -m 0755 "$source_file" /usr/local/bin/aon-notify
  ok "aon-notify installed."

  read -r -p "Configure Telegram Bot Token and Chat ID now? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    run_user /usr/local/bin/aon-notify setup
  else
    info "Configure later with: aon-notify setup"
  fi
}

selection_has() {
  local needle="$1"
  case ",$SELECTION," in
    *",$needle,"*) return 0 ;;
    *) return 1 ;;
  esac
}

run_custom() {
  selection_has 1 && install_common_tools
  selection_has 2 && install_github_cli
  selection_has 3 && install_node
  selection_has 4 && install_python
  selection_has 5 && install_claude
  selection_has 6 && install_codex
  selection_has 7 && install_kimi
  selection_has 8 && install_notify_bridge
  selection_has 9 && install_nginx
  selection_has 10 && install_pm2
  selection_has 11 && install_ufw
  selection_has 12 && install_fail2ban
  selection_has 13 && install_docker
}

printf '\n%b\n' "$BOLD$GREEN AON Optional Server Setup $RESET"
line
printf '%b\n' "$DIM AON core is already installed. Everything here is optional. $RESET"
echo

cat <<MENU
$GREEN 1) Minimal $RESET
    AON only. Install nothing else.

$CYAN 2) AI Builder $RESET
    Common CLI tools
    GitHub CLI
    Node.js + npm
    Python + pip
    Claude Code
    OpenAI Codex
    Kimi Code CLI
    Optional Telegram notifications

$MAGENTA 3) Server Developer $RESET
    Everything in AI Builder
    NGINX
    PM2
    UFW
    Fail2ban
    Optional Docker
    Optional Telegram notifications

$YELLOW 4) Custom $RESET
    Choose components individually.
MENU

read -r -p "Profile [1-4, default 1]: " PROFILE
[ -n "$PROFILE" ] || PROFILE=1

case "$PROFILE" in
  1)
    ok "Minimal selected. No optional tools installed."
    ;;

  2)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  3)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi
    install_nginx
    install_pm2
    install_ufw
    install_fail2ban

    read -r -p "Install Docker Engine? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_docker || true

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  4)
    cat <<CUSTOM

Choose comma-separated component numbers:

  1  Common CLI tools       8  Telegram notifications
  2  GitHub CLI             9  NGINX
  3  Node.js + npm         10  PM2
  4  Python + pip          11  UFW
  5  Claude Code           12  Fail2ban
  6  OpenAI Codex          13  Docker Engine
  7  Kimi Code CLI

Example:
  1,2,3,4,5,6,7,8

CUSTOM

    read -r -p "Selection: " SELECTION
    SELECTION="$(printf '%s' "$SELECTION" | tr -d ' ')"
    run_custom
    ;;

  *)
    warn "Unknown profile. Nothing optional was installed."
    ;;
esac

echo
line
ok "Optional server setup finished."
\033[36m'
  MAGENTA=
else
  RESET=''; BOLD=''; DIM=''; GREEN=''; YELLOW=''; CYAN=''; MAGENTA=''; RED=''
fi

line()    { printf '%b\n' "$DIM------------------------------------------------------------$RESET"; }
title()   { printf '\n%b\n' "$BOLD$MAGENTA$*$RESET"; line; }
info()    { printf '%b\n' "$CYAN›$RESET $*"; }
ok()      { printf '%b\n' "$GREEN✓$RESET $*"; }
warn()    { printf '%b\n' "$YELLOW!$RESET $*"; }
die()     { printf '%b\n' "$RED✗$RESET $*" >&2; exit 1; }

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "sudo is required for this component."
  fi
}

if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
  TARGET_USER="$SUDO_USER"
  TARGET_HOME="$(eval echo "~$TARGET_USER")"
fi

run_user() {
  if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
    sudo -H -u "$TARGET_USER" "$@"
  else
    "$@"
  fi
}

pkg_install() {
  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    run_root dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    run_root yum install -y "$@"
  elif command -v pacman >/dev/null 2>&1; then
    run_root pacman -S --noconfirm --needed "$@"
  elif command -v zypper >/dev/null 2>&1; then
    run_root zypper --non-interactive install "$@"
  elif command -v brew >/dev/null 2>&1; then
    brew install "$@"
  else
    return 1
  fi
}

install_common_tools() {
  title "Common CLI Tools"

  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get update -y
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync build-essential
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync base-devel
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v brew >/dev/null 2>&1; then
    brew install jq ripgrep fzf htop btop tree coreutils || true
  fi

  ok "Common CLI tools are ready."
}

install_github_cli() {
  title "GitHub CLI"

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI is already installed."
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install gh
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install github-cli || true
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install gh || true
  fi

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI installed."
    info "Connect your GitHub account later with: gh auth login"
  else
    warn "GitHub CLI was not available from the current package source."
    info "Official site: https://cli.github.com/"
  fi
}

install_node() {
  title "Node.js + npm"

  if command -v node >/dev/null 2>&1; then
    ok "Node.js is already installed: $(node --version)"
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install node
  else
    pkg_install nodejs npm
  fi

  command -v node >/dev/null 2>&1 && ok "Node.js installed: $(node --version)"
}

install_python() {
  title "Python"

  if command -v brew >/dev/null 2>&1; then
    brew install python
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install python3 python3-pip python3-venv
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install python python-pip
  else
    pkg_install python3 python3-pip
  fi

  if command -v python3 >/dev/null 2>&1; then
    ok "Python installed: $(python3 --version)"
  elif command -v python >/dev/null 2>&1; then
    ok "Python installed: $(python --version)"
  fi
}

install_claude() {
  title "Claude Code"

  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://claude.ai/install.sh | bash'
  ok "Claude Code installer completed."
  info "Open a new shell and run: claude"
}

install_codex() {
  title "OpenAI Codex"

  if command -v codex >/dev/null 2>&1; then
    ok "Codex is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://chatgpt.com/codex/install.sh | sh'
  ok "Codex installer completed."
  info "Open a new shell and run: codex"
}

install_kimi() {
  title "Kimi Code CLI"

  if command -v kimi >/dev/null 2>&1; then
    ok "Kimi is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash'
  ok "Kimi Code CLI installer completed."
  info "Open a new shell and run: kimi"
}

install_nginx() {
  title "NGINX"
  pkg_install nginx
  ok "NGINX installed."
}

install_pm2() {
  title "PM2"
  command -v npm >/dev/null 2>&1 || install_node
  run_root npm install -g pm2
  ok "PM2 installed."
}

install_ufw() {
  title "UFW"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "UFW is Linux-only."
    return
  fi

  pkg_install ufw || warn "UFW is not available from this package source."
}

install_fail2ban() {
  title "Fail2ban"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "Fail2ban is intended for Linux servers."
    return
  fi

  pkg_install fail2ban || warn "Fail2ban is not available from this package source."
}

install_docker() {
  title "Docker Engine"

  if [ "$HOST_OS" != "Linux" ]; then
    warn "This Docker Engine bootstrap is Linux-only."
    info "Use Docker Desktop on macOS."
    return
  fi

  if command -v docker >/dev/null 2>&1; then
    ok "Docker is already installed."
    return
  fi

  curl -fsSL https://get.docker.com -o /tmp/aon-get-docker.sh
  run_root sh /tmp/aon-get-docker.sh
  rm -f /tmp/aon-get-docker.sh
  ok "Docker Engine installed."
}

install_notify_bridge() {
  title "AON Telegram Notifications"

  local source_file="$REPO_ROOT/scripts/aon-notify.sh"

  if [ ! -f "$source_file" ]; then
    source_file="/tmp/aon-notify.sh"
    curl -fsSL https://raw.githubusercontent.com/pfix0/AON/main/scripts/aon-notify.sh -o "$source_file"
  fi

  run_root install -m 0755 "$source_file" /usr/local/bin/aon-notify
  ok "aon-notify installed."

  read -r -p "Configure Telegram Bot Token and Chat ID now? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    run_user /usr/local/bin/aon-notify setup
  else
    info "Configure later with: aon-notify setup"
  fi
}

selection_has() {
  local needle="$1"
  case ",$SELECTION," in
    *",$needle,"*) return 0 ;;
    *) return 1 ;;
  esac
}

run_custom() {
  selection_has 1 && install_common_tools
  selection_has 2 && install_github_cli
  selection_has 3 && install_node
  selection_has 4 && install_python
  selection_has 5 && install_claude
  selection_has 6 && install_codex
  selection_has 7 && install_kimi
  selection_has 8 && install_notify_bridge
  selection_has 9 && install_nginx
  selection_has 10 && install_pm2
  selection_has 11 && install_ufw
  selection_has 12 && install_fail2ban
  selection_has 13 && install_docker
}

printf '\n%b\n' "$BOLD$GREEN AON Optional Server Setup $RESET"
line
printf '%b\n' "$DIM AON core is already installed. Everything here is optional. $RESET"
echo

cat <<MENU
$GREEN 1) Minimal $RESET
    AON only. Install nothing else.

$CYAN 2) AI Builder $RESET
    Common CLI tools
    GitHub CLI
    Node.js + npm
    Python + pip
    Claude Code
    OpenAI Codex
    Kimi Code CLI
    Optional Telegram notifications

$MAGENTA 3) Server Developer $RESET
    Everything in AI Builder
    NGINX
    PM2
    UFW
    Fail2ban
    Optional Docker
    Optional Telegram notifications

$YELLOW 4) Custom $RESET
    Choose components individually.
MENU

read -r -p "Profile [1-4, default 1]: " PROFILE
[ -n "$PROFILE" ] || PROFILE=1

case "$PROFILE" in
  1)
    ok "Minimal selected. No optional tools installed."
    ;;

  2)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  3)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi
    install_nginx
    install_pm2
    install_ufw
    install_fail2ban

    read -r -p "Install Docker Engine? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_docker || true

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  4)
    cat <<CUSTOM

Choose comma-separated component numbers:

  1  Common CLI tools       8  Telegram notifications
  2  GitHub CLI             9  NGINX
  3  Node.js + npm         10  PM2
  4  Python + pip          11  UFW
  5  Claude Code           12  Fail2ban
  6  OpenAI Codex          13  Docker Engine
  7  Kimi Code CLI

Example:
  1,2,3,4,5,6,7,8

CUSTOM

    read -r -p "Selection: " SELECTION
    SELECTION="$(printf '%s' "$SELECTION" | tr -d ' ')"
    run_custom
    ;;

  *)
    warn "Unknown profile. Nothing optional was installed."
    ;;
esac

echo
line
ok "Optional server setup finished."
\033[35m'
  RED=
else
  RESET=''; BOLD=''; DIM=''; GREEN=''; YELLOW=''; CYAN=''; MAGENTA=''; RED=''
fi

line()    { printf '%b\n' "$DIM------------------------------------------------------------$RESET"; }
title()   { printf '\n%b\n' "$BOLD$MAGENTA$*$RESET"; line; }
info()    { printf '%b\n' "$CYAN›$RESET $*"; }
ok()      { printf '%b\n' "$GREEN✓$RESET $*"; }
warn()    { printf '%b\n' "$YELLOW!$RESET $*"; }
die()     { printf '%b\n' "$RED✗$RESET $*" >&2; exit 1; }

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "sudo is required for this component."
  fi
}

if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
  TARGET_USER="$SUDO_USER"
  TARGET_HOME="$(eval echo "~$TARGET_USER")"
fi

run_user() {
  if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
    sudo -H -u "$TARGET_USER" "$@"
  else
    "$@"
  fi
}

pkg_install() {
  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    run_root dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    run_root yum install -y "$@"
  elif command -v pacman >/dev/null 2>&1; then
    run_root pacman -S --noconfirm --needed "$@"
  elif command -v zypper >/dev/null 2>&1; then
    run_root zypper --non-interactive install "$@"
  elif command -v brew >/dev/null 2>&1; then
    brew install "$@"
  else
    return 1
  fi
}

install_common_tools() {
  title "Common CLI Tools"

  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get update -y
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync build-essential
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync base-devel
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v brew >/dev/null 2>&1; then
    brew install jq ripgrep fzf htop btop tree coreutils || true
  fi

  ok "Common CLI tools are ready."
}

install_github_cli() {
  title "GitHub CLI"

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI is already installed."
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install gh
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install github-cli || true
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install gh || true
  fi

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI installed."
    info "Connect your GitHub account later with: gh auth login"
  else
    warn "GitHub CLI was not available from the current package source."
    info "Official site: https://cli.github.com/"
  fi
}

install_node() {
  title "Node.js + npm"

  if command -v node >/dev/null 2>&1; then
    ok "Node.js is already installed: $(node --version)"
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install node
  else
    pkg_install nodejs npm
  fi

  command -v node >/dev/null 2>&1 && ok "Node.js installed: $(node --version)"
}

install_python() {
  title "Python"

  if command -v brew >/dev/null 2>&1; then
    brew install python
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install python3 python3-pip python3-venv
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install python python-pip
  else
    pkg_install python3 python3-pip
  fi

  if command -v python3 >/dev/null 2>&1; then
    ok "Python installed: $(python3 --version)"
  elif command -v python >/dev/null 2>&1; then
    ok "Python installed: $(python --version)"
  fi
}

install_claude() {
  title "Claude Code"

  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://claude.ai/install.sh | bash'
  ok "Claude Code installer completed."
  info "Open a new shell and run: claude"
}

install_codex() {
  title "OpenAI Codex"

  if command -v codex >/dev/null 2>&1; then
    ok "Codex is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://chatgpt.com/codex/install.sh | sh'
  ok "Codex installer completed."
  info "Open a new shell and run: codex"
}

install_kimi() {
  title "Kimi Code CLI"

  if command -v kimi >/dev/null 2>&1; then
    ok "Kimi is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash'
  ok "Kimi Code CLI installer completed."
  info "Open a new shell and run: kimi"
}

install_nginx() {
  title "NGINX"
  pkg_install nginx
  ok "NGINX installed."
}

install_pm2() {
  title "PM2"
  command -v npm >/dev/null 2>&1 || install_node
  run_root npm install -g pm2
  ok "PM2 installed."
}

install_ufw() {
  title "UFW"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "UFW is Linux-only."
    return
  fi

  pkg_install ufw || warn "UFW is not available from this package source."
}

install_fail2ban() {
  title "Fail2ban"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "Fail2ban is intended for Linux servers."
    return
  fi

  pkg_install fail2ban || warn "Fail2ban is not available from this package source."
}

install_docker() {
  title "Docker Engine"

  if [ "$HOST_OS" != "Linux" ]; then
    warn "This Docker Engine bootstrap is Linux-only."
    info "Use Docker Desktop on macOS."
    return
  fi

  if command -v docker >/dev/null 2>&1; then
    ok "Docker is already installed."
    return
  fi

  curl -fsSL https://get.docker.com -o /tmp/aon-get-docker.sh
  run_root sh /tmp/aon-get-docker.sh
  rm -f /tmp/aon-get-docker.sh
  ok "Docker Engine installed."
}

install_notify_bridge() {
  title "AON Telegram Notifications"

  local source_file="$REPO_ROOT/scripts/aon-notify.sh"

  if [ ! -f "$source_file" ]; then
    source_file="/tmp/aon-notify.sh"
    curl -fsSL https://raw.githubusercontent.com/pfix0/AON/main/scripts/aon-notify.sh -o "$source_file"
  fi

  run_root install -m 0755 "$source_file" /usr/local/bin/aon-notify
  ok "aon-notify installed."

  read -r -p "Configure Telegram Bot Token and Chat ID now? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    run_user /usr/local/bin/aon-notify setup
  else
    info "Configure later with: aon-notify setup"
  fi
}

selection_has() {
  local needle="$1"
  case ",$SELECTION," in
    *",$needle,"*) return 0 ;;
    *) return 1 ;;
  esac
}

run_custom() {
  selection_has 1 && install_common_tools
  selection_has 2 && install_github_cli
  selection_has 3 && install_node
  selection_has 4 && install_python
  selection_has 5 && install_claude
  selection_has 6 && install_codex
  selection_has 7 && install_kimi
  selection_has 8 && install_notify_bridge
  selection_has 9 && install_nginx
  selection_has 10 && install_pm2
  selection_has 11 && install_ufw
  selection_has 12 && install_fail2ban
  selection_has 13 && install_docker
}

printf '\n%b\n' "$BOLD$GREEN AON Optional Server Setup $RESET"
line
printf '%b\n' "$DIM AON core is already installed. Everything here is optional. $RESET"
echo

cat <<MENU
$GREEN 1) Minimal $RESET
    AON only. Install nothing else.

$CYAN 2) AI Builder $RESET
    Common CLI tools
    GitHub CLI
    Node.js + npm
    Python + pip
    Claude Code
    OpenAI Codex
    Kimi Code CLI
    Optional Telegram notifications

$MAGENTA 3) Server Developer $RESET
    Everything in AI Builder
    NGINX
    PM2
    UFW
    Fail2ban
    Optional Docker
    Optional Telegram notifications

$YELLOW 4) Custom $RESET
    Choose components individually.
MENU

read -r -p "Profile [1-4, default 1]: " PROFILE
[ -n "$PROFILE" ] || PROFILE=1

case "$PROFILE" in
  1)
    ok "Minimal selected. No optional tools installed."
    ;;

  2)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  3)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi
    install_nginx
    install_pm2
    install_ufw
    install_fail2ban

    read -r -p "Install Docker Engine? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_docker || true

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  4)
    cat <<CUSTOM

Choose comma-separated component numbers:

  1  Common CLI tools       8  Telegram notifications
  2  GitHub CLI             9  NGINX
  3  Node.js + npm         10  PM2
  4  Python + pip          11  UFW
  5  Claude Code           12  Fail2ban
  6  OpenAI Codex          13  Docker Engine
  7  Kimi Code CLI

Example:
  1,2,3,4,5,6,7,8

CUSTOM

    read -r -p "Selection: " SELECTION
    SELECTION="$(printf '%s' "$SELECTION" | tr -d ' ')"
    run_custom
    ;;

  *)
    warn "Unknown profile. Nothing optional was installed."
    ;;
esac

echo
line
ok "Optional server setup finished."
\033[31m'
else
  RESET=''; BOLD=''; DIM=''; GREEN=''; YELLOW=''; CYAN=''; MAGENTA=''; RED=''
fi

line()    { printf '%b\n' "$DIM------------------------------------------------------------$RESET"; }
title()   { printf '\n%b\n' "$BOLD$MAGENTA$*$RESET"; line; }
info()    { printf '%b\n' "$CYAN›$RESET $*"; }
ok()      { printf '%b\n' "$GREEN✓$RESET $*"; }
warn()    { printf '%b\n' "$YELLOW!$RESET $*"; }
die()     { printf '%b\n' "$RED✗$RESET $*" >&2; exit 1; }

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "sudo is required for this component."
  fi
}

if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
  TARGET_USER="$SUDO_USER"
  TARGET_HOME="$(eval echo "~$TARGET_USER")"
fi

run_user() {
  if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
    sudo -H -u "$TARGET_USER" "$@"
  else
    "$@"
  fi
}

pkg_install() {
  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    run_root dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    run_root yum install -y "$@"
  elif command -v pacman >/dev/null 2>&1; then
    run_root pacman -S --noconfirm --needed "$@"
  elif command -v zypper >/dev/null 2>&1; then
    run_root zypper --non-interactive install "$@"
  elif command -v brew >/dev/null 2>&1; then
    brew install "$@"
  else
    return 1
  fi
}

install_common_tools() {
  title "Common CLI Tools"

  if command -v apt-get >/dev/null 2>&1; then
    run_root env DEBIAN_FRONTEND=noninteractive apt-get update -y
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync build-essential
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop btop tree unzip zip rsync base-devel
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install jq ripgrep fzf htop tree unzip zip rsync gcc gcc-c++ make || true
    pkg_install btop || true
  elif command -v brew >/dev/null 2>&1; then
    brew install jq ripgrep fzf htop btop tree coreutils || true
  fi

  ok "Common CLI tools are ready."
}

install_github_cli() {
  title "GitHub CLI"

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI is already installed."
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install gh
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v dnf >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v yum >/dev/null 2>&1; then
    pkg_install gh || true
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install github-cli || true
  elif command -v zypper >/dev/null 2>&1; then
    pkg_install gh || true
  fi

  if command -v gh >/dev/null 2>&1; then
    ok "GitHub CLI installed."
    info "Connect your GitHub account later with: gh auth login"
  else
    warn "GitHub CLI was not available from the current package source."
    info "Official site: https://cli.github.com/"
  fi
}

install_node() {
  title "Node.js + npm"

  if command -v node >/dev/null 2>&1; then
    ok "Node.js is already installed: $(node --version)"
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install node
  else
    pkg_install nodejs npm
  fi

  command -v node >/dev/null 2>&1 && ok "Node.js installed: $(node --version)"
}

install_python() {
  title "Python"

  if command -v brew >/dev/null 2>&1; then
    brew install python
  elif command -v apt-get >/dev/null 2>&1; then
    pkg_install python3 python3-pip python3-venv
  elif command -v pacman >/dev/null 2>&1; then
    pkg_install python python-pip
  else
    pkg_install python3 python3-pip
  fi

  if command -v python3 >/dev/null 2>&1; then
    ok "Python installed: $(python3 --version)"
  elif command -v python >/dev/null 2>&1; then
    ok "Python installed: $(python --version)"
  fi
}

install_claude() {
  title "Claude Code"

  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://claude.ai/install.sh | bash'
  ok "Claude Code installer completed."
  info "Open a new shell and run: claude"
}

install_codex() {
  title "OpenAI Codex"

  if command -v codex >/dev/null 2>&1; then
    ok "Codex is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://chatgpt.com/codex/install.sh | sh'
  ok "Codex installer completed."
  info "Open a new shell and run: codex"
}

install_kimi() {
  title "Kimi Code CLI"

  if command -v kimi >/dev/null 2>&1; then
    ok "Kimi is already installed."
    return
  fi

  run_user bash -lc 'curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash'
  ok "Kimi Code CLI installer completed."
  info "Open a new shell and run: kimi"
}

install_nginx() {
  title "NGINX"
  pkg_install nginx
  ok "NGINX installed."
}

install_pm2() {
  title "PM2"
  command -v npm >/dev/null 2>&1 || install_node
  run_root npm install -g pm2
  ok "PM2 installed."
}

install_ufw() {
  title "UFW"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "UFW is Linux-only."
    return
  fi

  pkg_install ufw || warn "UFW is not available from this package source."
}

install_fail2ban() {
  title "Fail2ban"

  if [ "$HOST_OS" = "Darwin" ]; then
    warn "Fail2ban is intended for Linux servers."
    return
  fi

  pkg_install fail2ban || warn "Fail2ban is not available from this package source."
}

install_docker() {
  title "Docker Engine"

  if [ "$HOST_OS" != "Linux" ]; then
    warn "This Docker Engine bootstrap is Linux-only."
    info "Use Docker Desktop on macOS."
    return
  fi

  if command -v docker >/dev/null 2>&1; then
    ok "Docker is already installed."
    return
  fi

  curl -fsSL https://get.docker.com -o /tmp/aon-get-docker.sh
  run_root sh /tmp/aon-get-docker.sh
  rm -f /tmp/aon-get-docker.sh
  ok "Docker Engine installed."
}

install_notify_bridge() {
  title "AON Telegram Notifications"

  local source_file="$REPO_ROOT/scripts/aon-notify.sh"

  if [ ! -f "$source_file" ]; then
    source_file="/tmp/aon-notify.sh"
    curl -fsSL https://raw.githubusercontent.com/pfix0/AON/main/scripts/aon-notify.sh -o "$source_file"
  fi

  run_root install -m 0755 "$source_file" /usr/local/bin/aon-notify
  ok "aon-notify installed."

  read -r -p "Configure Telegram Bot Token and Chat ID now? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    run_user /usr/local/bin/aon-notify setup
  else
    info "Configure later with: aon-notify setup"
  fi
}

selection_has() {
  local needle="$1"
  case ",$SELECTION," in
    *",$needle,"*) return 0 ;;
    *) return 1 ;;
  esac
}

run_custom() {
  selection_has 1 && install_common_tools
  selection_has 2 && install_github_cli
  selection_has 3 && install_node
  selection_has 4 && install_python
  selection_has 5 && install_claude
  selection_has 6 && install_codex
  selection_has 7 && install_kimi
  selection_has 8 && install_notify_bridge
  selection_has 9 && install_nginx
  selection_has 10 && install_pm2
  selection_has 11 && install_ufw
  selection_has 12 && install_fail2ban
  selection_has 13 && install_docker
}

printf '\n%b\n' "$BOLD$GREEN AON Optional Server Setup $RESET"
line
printf '%b\n' "$DIM AON core is already installed. Everything here is optional. $RESET"
echo

cat <<MENU
$GREEN 1) Minimal $RESET
    AON only. Install nothing else.

$CYAN 2) AI Builder $RESET
    Common CLI tools
    GitHub CLI
    Node.js + npm
    Python + pip
    Claude Code
    OpenAI Codex
    Kimi Code CLI
    Optional Telegram notifications

$MAGENTA 3) Server Developer $RESET
    Everything in AI Builder
    NGINX
    PM2
    UFW
    Fail2ban
    Optional Docker
    Optional Telegram notifications

$YELLOW 4) Custom $RESET
    Choose components individually.
MENU

read -r -p "Profile [1-4, default 1]: " PROFILE
[ -n "$PROFILE" ] || PROFILE=1

case "$PROFILE" in
  1)
    ok "Minimal selected. No optional tools installed."
    ;;

  2)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  3)
    install_common_tools
    install_github_cli
    install_node
    install_python
    install_claude
    install_codex
    install_kimi
    install_nginx
    install_pm2
    install_ufw
    install_fail2ban

    read -r -p "Install Docker Engine? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_docker || true

    read -r -p "Install AON Telegram notifications? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] && install_notify_bridge || true
    ;;

  4)
    cat <<CUSTOM

Choose comma-separated component numbers:

  1  Common CLI tools       8  Telegram notifications
  2  GitHub CLI             9  NGINX
  3  Node.js + npm         10  PM2
  4  Python + pip          11  UFW
  5  Claude Code           12  Fail2ban
  6  OpenAI Codex          13  Docker Engine
  7  Kimi Code CLI

Example:
  1,2,3,4,5,6,7,8

CUSTOM

    read -r -p "Selection: " SELECTION
    SELECTION="$(printf '%s' "$SELECTION" | tr -d ' ')"
    run_custom
    ;;

  *)
    warn "Unknown profile. Nothing optional was installed."
    ;;
esac

echo
line
ok "Optional server setup finished."
