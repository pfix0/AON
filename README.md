<a id="readme-top"></a>

<div align="center">

  <img src="assets/410c765d-c1b3-46f7-b653-a129444db264.png" alt="AON Assistant" width="200">

  <h1>AON</h1>

  <p><strong>Persistent terminal sessions made simple.</strong></p>

</div>


  <h1>AON</h1>

  <p><strong>Persistent terminal sessions made simple.</strong></p>

  <p>
    A lightweight terminal session assistant built on top of
    <a href="https://github.com/tmux/tmux">tmux</a>.
  </p>

  <p>Created by <strong>pfix0</strong></p>

  <p>
    <img src="https://img.shields.io/badge/version-1.0.0-00ff00?style=for-the-badge" alt="Version">
    <img src="https://img.shields.io/badge/backend-tmux-1bb91f?style=for-the-badge" alt="tmux">
    <img src="https://img.shields.io/badge/shell-Bash%20%7C%20Zsh-111111?style=for-the-badge" alt="Shell">
    <img src="https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20WSL-111111?style=for-the-badge" alt="Platform">
  </p>

  <p>
    <a href="#getting-started"><strong>Get Started</strong></a>
    ·
    <a href="#usage">Usage</a>
    ·
    <a href="#keyboard-shortcuts">Shortcuts</a>
    ·
    <a href="#supported-systems">Supported Systems</a>
  </p>

</div>

---

## Table of Contents

- [About AON](#about-aon)
  - [Built With](#built-with)
  - [Why AON](#why-aon)
  - [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
  - [Commands](#commands)
  - [TAB Completion](#tab-completion)
  - [Keyboard Shortcuts](#keyboard-shortcuts)
  - [Zoom](#zoom)
  - [Mouse Navigation](#mouse-navigation)
  - [Splitting the Terminal](#splitting-the-terminal)
  - [Multiple Windows](#multiple-windows)
  - [Background / Detach](#background--detach)
  - [Built-in Help](#built-in-help)
- [Supported Systems](#supported-systems)
- [Health Check](#health-check)
- [Example Workflow](#example-workflow)
- [Project Structure](#project-structure)
- [Security](#security)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Author](#author)
- [Acknowledgments](#acknowledgments)

---

## About AON

**AON** is a lightweight command-line layer around `tmux` that makes persistent terminal work easier to create, manage, detach, restore, split, zoom, and navigate.

It is designed for long-running terminal workflows such as:

- Claude Code
- Codex
- Node.js development servers
- Python applications
- build jobs
- workers
- logs and monitoring
- SSH administration
- long-running scripts

The core workflow is simple:

```bash
aon new project
```

Start your work:

```bash
claude
```

Detach without stopping it:

```text
F6
```

Return later:

```bash
aon attach project
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With

AON keeps the stack intentionally small:

- [tmux](https://github.com/tmux/tmux)
- Bash
- Zsh
- OpenSSH
- Byobu integration when available

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Why AON

A normal remote terminal can disappear when:

- SSH disconnects
- your laptop sleeps
- the terminal closes
- Wi-Fi changes
- VPN reconnects
- the client machine restarts
- you intentionally disconnect from the server

AON keeps the actual work inside a persistent `tmux` session on the host.

Your terminal process is no longer tied to the lifetime of the SSH connection.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Features

#### Session Management

- Named persistent sessions
- Create, open, attach, rename, and stop sessions
- Detach without stopping processes
- List all sessions
- Show the current session
- Stop all sessions when required

#### Terminal Workflow

- Multiple windows
- Horizontal and vertical splits
- Full-screen pane zoom
- Keyboard pane navigation
- Mouse pane selection
- Mouse window switching from the bottom status bar
- Pane resizing
- Large scrollback history
- Mouse support enabled automatically

#### Shell Integration

- Bash support
- Zsh support
- TAB completion
- Session-name completion
- AON-specific `help` inside AON sessions
- Normal shell help outside AON remains unchanged

#### Diagnostics

- Built-in `aon doctor`
- tmux configuration validation
- automatic dependency checks

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Getting Started

### Prerequisites

The installer handles dependencies automatically on supported systems.

Core components include:

- `tmux`
- Bash
- Zsh integration
- OpenSSH client
- Git
- curl

On macOS, Homebrew is required.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Installation

Clone the repository:

```bash
git clone https://github.com/pfix0/AON.git
cd AON
```

Make the installer executable:

```bash
chmod +x install.sh
```

Run it:

```bash
./install.sh
```

On Linux you may also run:

```bash
sudo bash install.sh
```

The installer:

1. Detects the operating system.
2. Detects the target user.
3. Installs required packages.
4. Installs `/usr/local/bin/aon`.
5. Configures `tmux`.
6. Configures Byobu when available.
7. Adds Bash completion.
8. Adds Zsh completion.
9. Adds AON-aware shell help behavior.
10. Enables mouse support.
11. Configures AON shortcuts.
12. Validates the tmux configuration.
13. Runs `aon doctor`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Usage

Create a session:

```bash
aon new project
```

List sessions:

```bash
aon list
```

Detach without stopping work:

```text
F6
```

Return:

```bash
aon attach project
```

Open an existing session or create it automatically:

```bash
aon open project
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Commands

| Command | Description |
|---|---|
| `aon list` | List running sessions |
| `aon new <name>` | Create a new session |
| `aon open <name>` | Open an existing session or create it |
| `aon attach <name>` | Attach to an existing session |
| `aon detach` | Detach and keep work running |
| `aon bg` | Alias for detach |
| `aon background` | Alias for detach |
| `aon kill <name>` | Stop one session |
| `aon rename <old> <new>` | Rename a session |
| `aon current` | Show the current session |
| `aon kill-all` | Stop all sessions |
| `aon keys` | Show keyboard shortcuts |
| `aon doctor` | Check the AON installation |
| `aon version` | Show version and author |
| `aon help` | Show quick help |
| `aon help --` | Show full help |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### TAB Completion

AON can complete existing session names:

```bash
aon attach <TAB>
aon open <TAB>
aon kill <TAB>
aon rename <TAB>
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Keyboard Shortcuts

| Key | Action |
|---|---|
| `F4` | Zoom / unzoom the current pane |
| `F5` | Create a new window |
| `F6` | Background / detach |
| `F7` | Previous window |
| `F8` | Next window |
| `F9` | Split left / right |
| `F10` | Split top / bottom |
| `F11` | Close the current pane |
| `F12` | Close the current window |
| `Alt + 1..9` | Jump directly to a window |
| `Alt + Arrow` | Move between panes |
| `Shift + Arrow` | Resize the current pane |

Standard tmux fallbacks remain available:

| Shortcut | Action |
|---|---|
| `Ctrl+b`, then `c` | New window |
| `Ctrl+b`, then `d` | Detach |
| `Ctrl+b`, then `n` | Next window |
| `Ctrl+b`, then `p` | Previous window |
| `Ctrl+b`, then `%` | Split left / right |
| `Ctrl+b`, then `"` | Split top / bottom |
| `Ctrl+b`, then `x` | Close pane |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Zoom

If the terminal is split into multiple panes, focus the pane you want and press:

```text
F4
```

The selected pane becomes full-screen.

Press `F4` again to restore the previous split layout.

This is useful when a Claude Code or Codex conversation needs the entire terminal temporarily.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Mouse Navigation

Mouse support is enabled automatically.

#### Focus a pane

Click any pane.

#### Switch between windows or conversations

The bottom tmux status bar shows your windows.

From any pane, click a window name or number in the bottom bar to switch directly to it.

This works even while the screen is split.

#### Text Selection

AON intentionally does **not** use double-click for zoom.

This preserves normal terminal double-click text selection behavior.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Splitting the Terminal

#### Left / Right

Press:

```text
F9
```

```text
+----------------------+----------------------+
|                      |                      |
|      Terminal 1      |      Terminal 2      |
|                      |                      |
+----------------------+----------------------+
```

#### Top / Bottom

Press:

```text
F10
```

```text
+---------------------------------------------+
|                  Terminal 1                 |
+---------------------------------------------+
|                  Terminal 2                 |
+---------------------------------------------+
```

Move between panes with `Alt + Arrow` or click the pane with the mouse.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Multiple Windows

Create a new window: `F5`

Previous window: `F7`

Next window: `F8`

Direct access:

```text
Alt + 1
Alt + 2
Alt + 3
...
Alt + 9
```

You can also click the window in the bottom status bar.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Background / Detach

`F6` is the main AON shortcut.

It detaches the current client from the `tmux` session.

It does **not** stop the processes inside that session.

Examples that continue running:

- Claude Code
- Codex
- Node.js
- npm
- pnpm
- Python
- API servers
- development servers
- workers
- builds
- monitoring tools
- log viewers

Example:

```bash
aon new api
npm run dev
```

Press `F6`.

Later:

```bash
aon attach api
```

The same session is restored.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built-in Help

Inside an AON session:

```bash
help
```

shows AON quick help.

Full help:

```bash
help --
```

Other help pages:

```bash
help --keys
help --commands
help --mac
help --windows
help --linux
```

Outside AON, normal shell help remains unchanged.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Supported Systems

### Direct Host Support

The installer supports:

- Ubuntu
- Debian
- Linux Mint
- Pop!_OS
- Fedora
- RHEL
- CentOS
- Rocky Linux
- AlmaLinux
- Arch-based distributions using `pacman`
- openSUSE / SUSE systems using `zypper`
- macOS with Homebrew

### Windows

Native PowerShell and CMD are not the target AON runtime because AON depends on `tmux`.

Use WSL, WSL2, or a remote Linux host over SSH.

### SSH Client Support

You can access an AON host from macOS, Windows, Linux, ChromeOS, and other SSH-capable systems.

### Function Keys

On many MacBooks, use `Fn + F4` through `Fn + F12` unless standard function keys are enabled.

Windows and Linux laptops may also require `Fn`, depending on keyboard settings.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Health Check

Run:

```bash
aon doctor
```

Example:

```text
AON Doctor
==========
tmux               OK
bash               OK
zsh                OK
git                OK
curl               OK
ssh                OK
tmux config        OK
AON version        1.0.0
Author             pfix0
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Example Workflow

```bash
aon new root-ai
claude
```

Create another window with `F5`, split with `F9`, zoom with `F4`, and detach everything with `F6`.

Reconnect later:

```bash
ssh server
aon list
aon attach root-ai
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Project Structure

```text
AON/
├── install.sh
└── README.md
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Security

AON does not open a network port, run a public API, provide remote authentication, replace SSH authentication, or require a cloud account.

AON sessions run with the privileges of the user who starts them.

Avoid placing secrets in session names, shell history, or command-line arguments.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Updating

```bash
git pull
./install.sh
```

Existing tmux sessions are not intentionally deleted by the installer.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Uninstalling

```bash
sudo rm -f /usr/local/bin/aon
rm -rf ~/.aon
```

Remove AON-managed sections from `~/.tmux.conf`, `~/.bashrc`, and `~/.zshrc`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Roadmap

- [x] Persistent named sessions
- [x] F-key workflow
- [x] Pane splitting
- [x] Pane zoom
- [x] Mouse pane navigation
- [x] Mouse status-bar window switching
- [x] Bash completion
- [x] Zsh completion
- [x] Built-in doctor command
- [x] Linux support
- [x] macOS support
- [x] WSL workflow
- [ ] Automated release packaging
- [ ] Installer test matrix in CI
- [ ] Optional theme presets
- [ ] Additional terminal compatibility testing

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Contributing

Contributions are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Commit your changes.
4. Push the branch.
5. Open a Pull Request.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## License

No license file has been added yet.

Until a license is explicitly added to the repository, normal copyright restrictions apply.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Author

Created by **pfix0**.

Current version: **1.0.0**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Acknowledgments

README structure and presentation were inspired by the open-source [Best-README-Template](https://github.com/othneildrew/Best-README-Template).

AON is built on top of the excellent [tmux](https://github.com/tmux/tmux) terminal multiplexer.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

<div align="center">
  <p><strong>AON — persistent terminal work without losing your session.</strong></p>
  <p>Created by <strong>pfix0</strong></p>
</div>
