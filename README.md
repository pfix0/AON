<a id="readme-top"></a>

<div align="center">

  <img src="assets/Aon logo.png" alt="AON" width="180">

  <h1>AON</h1>

  <p><strong>Persistent terminal sessions made simple.</strong></p>

  <p>
    Keep AI tools, servers, scripts, builds, and SSH work running safely in the background.
  </p>

  <p>
    <img src="https://img.shields.io/badge/version-1.0.0-00C853?style=flat-square" alt="Version">
    <img src="https://img.shields.io/badge/tmux-powered-00ACC1?style=flat-square" alt="tmux">
    <img src="https://img.shields.io/badge/Linux-supported-7E57C2?style=flat-square" alt="Linux">
    <img src="https://img.shields.io/badge/macOS-supported-FFB300?style=flat-square" alt="macOS">
    <img src="https://img.shields.io/badge/WSL-supported-EF5350?style=flat-square" alt="WSL">
  </p>

  <p>
    <img src="https://img.shields.io/badge/CORE-READY-00C853?style=flat-square" alt="Core Ready">
    <img src="https://img.shields.io/badge/AI-OPTIONAL-7E57C2?style=flat-square" alt="AI Optional">
    <img src="https://img.shields.io/badge/TELEGRAM-OPTIONAL-229ED9?style=flat-square" alt="Telegram Optional">
  </p>

  <p>
    <a href="#quick-start"><strong>Quick Start</strong></a>
    ·
    <a href="#shortcuts"><strong>Shortcuts</strong></a>
    ·
    <a href="#optional-tools"><strong>Optional Tools</strong></a>
    ·
    <a href="#telegram"><strong>Telegram</strong></a>
  </p>

</div>

---

## ⚡ ${\\color{green}AON\\ in\\ 20\\ seconds}$

AON is a simple wrapper around `tmux`.

It lets you:

- keep terminal work alive after SSH disconnects
- detach with `F6` without stopping anything
- return to the same session later
- split the terminal into panes
- zoom one pane to full-screen
- switch windows and panes with keyboard or mouse
- install optional AI and server tools
- send completion notifications to Telegram

> [!TIP]
> Start work once, detach with `F6`, and return later without stopping the session.

---

## 🚀 ${\\color{lightblue}Quick\\ Start}$

### 1. Install

```bash
git clone https://github.com/pfix0/AON.git
cd AON
chmod +x install.sh
./install.sh
```

### 2. Create a session

```bash
aon new project
```

### 3. Run your work

```bash
claude
```

or:

```bash
codex
```

or any normal terminal command.

### 4. Leave it running

Press:

```text
F6
```

> [!IMPORTANT]
> `F6` detaches from AON. It does **not** stop Claude Code, Codex, servers, scripts, builds, or other processes running inside the session.

### 5. Return later

```bash
aon attach project
```

---

## ⌨️ ${\\color{yellow}Shortcuts}$

**Legend:** 🟢 Core · 🔵 Navigation · 🟡 Layout · 🔴 Close

> [!NOTE]
> macOS uses the **Option ⌥** key where Windows/Linux instructions say **Alt**.

| Key | Action |
|---|---|
| `F4` | 🟡 Zoom / unzoom current pane |
| `Alt + Z` | 🟡 Universal zoom / unzoom fallback |
| `Option ⌥ + Z` | 🟡 macOS zoom / unzoom fallback |
| `F5` | 🟢 New window |
| `F6` | 🟢 Detach and keep everything running |
| `F7` | 🔵 Previous window |
| `F8` | 🔵 Next window |
| `F9` | 🟡 Split left / right |
| `F10` | 🟡 Split top / bottom |
| `F11` | 🔴 Close pane |
| `F12` | 🔴 Close window |
| `Alt + 1..9` | Jump to a window |
| `Option ⌥ + 1..9` | macOS: jump to a window |
| `Alt + Arrow` | Move between panes |
| `Option ⌥ + Arrow` | macOS: move between panes |
| `Shift + Arrow` | Resize pane |

### 🖱️ Mouse

> [!NOTE]
> Mouse support is enabled automatically by AON.

- click a pane to focus it
- click a window in the bottom bar to switch to it
- normal text selection remains available
- double-click is not used for zoom

---

## 🧩 ${\\color{green}Core\\ Commands}$

| Command | Purpose |
|---|---|
| `aon new <name>` | Create a session |
| `aon open <name>` | Open or create a session |
| `aon attach <name>` | Re-enter a session |
| `aon list` | List sessions |
| `aon kill <name>` | Stop one session |
| `aon rename <old> <new>` | Rename a session |
| `aon current` | Show current session |
| `aon doctor` | Check AON installation |
| `aon keys` | Show shortcuts |
| `aon version` | Show version |

TAB completion works with session names:

```bash
aon attach <TAB>
```

---

## 🆘 ${\\color{lightblue}Built-in\\ Help}$

Inside an AON session:

```bash
help
```

More help:

```bash
help --
help --keys
help --commands
help --mac
help --windows
help --linux
```

Outside AON, your normal shell help stays unchanged.

---

## 🧰 ${\\color{orange}Optional\\ Tools}$

> [!NOTE]
> AON core installs first. Everything in this section is optional.

The installer can then show a second setup menu:

| Profile | What it installs |
|---|---|
| **Minimal** | AON only |
| **AI Builder** | CLI tools, GitHub CLI, Node.js, Python, Claude Code, Codex, Kimi |
| **Server Developer** | AI Builder + NGINX, PM2, UFW, Fail2ban |
| **Custom** | Pick tools individually |

Optional components include:

```text
Common CLI tools
GitHub CLI
Node.js + npm
Python + pip
Claude Code
OpenAI Codex
Kimi Code CLI
Telegram notifications
NGINX
PM2
UFW
Fail2ban
Docker Engine
```

Run the optional setup again later:

```bash
bash scripts/bootstrap.sh
```

---

## 📬 ${\\color{lightblue}Telegram}$

> [!TIP]
> Telegram notifications are optional and can wrap any command, not only AI tools.

Configure it:

```bash
aon-notify setup
```

Run any command and get notified when it exits:

```bash
aon-notify run codex
```

```bash
aon-notify run claude
```

```bash
aon-notify run npm run build
```

Manual message:

```bash
aon-notify send "Deployment finished"
```

Other commands:

```bash
aon-notify test
aon-notify status
aon-notify disable
```

Telegram config is stored locally in:

```text
~/.config/aon/telegram.env
```

---

## 🖥️ ${\\color{yellow}Supported\\ Systems}$

### AON host

- Ubuntu
- Debian
- Linux Mint
- Pop!_OS
- Fedora
- RHEL
- CentOS
- Rocky Linux
- AlmaLinux
- Arch-based Linux
- openSUSE / SUSE
- macOS with Homebrew
- Windows through WSL / WSL2

### SSH client

You can connect from:

- macOS
- Windows
- Linux
- ChromeOS
- any normal SSH-capable terminal

### Function keys

> [!NOTE]
> On laptops, the operating system may require the `Fn` key to send F-keys.

On macOS, the key commonly called **Alt** on other systems is labeled **Option ⌥**.

Examples:

```text
Windows / Linux: Alt + Z
macOS:           Option ⌥ + Z

Windows / Linux: Alt + 1..9
macOS:           Option ⌥ + 1..9

Windows / Linux: Alt + Arrow
macOS:           Option ⌥ + Arrow
```

You may need:

```text
Fn + F4
Fn + F5
Fn + F6
...
Fn + F12
```

---

## 🪟 ${\\color{green}Example\\ Layout}$

Split left / right with `F9`:

```text
┌──────────────────────┬──────────────────────┐
│                      │                      │
│       Terminal       │       Terminal       │
│                      │                      │
└──────────────────────┴──────────────────────┘
```

Zoom the active side with `F4`.

Press `F4` again to restore the split.

### F4 does not work

Some laptops or terminal applications intercept the F4 key before it reaches SSH/tmux.

Use the universal AON shortcut instead:

**Windows / Linux**

```text
Alt + Z
```

**macOS**

```text
Option ⌥ + Z
```

Or use the standard tmux fallback:

```text
Ctrl+b
z
```

If `Ctrl+b` then `z` works but `F4` does not, AON is working correctly and the local computer or terminal is intercepting F4.

---

<details>
<summary><strong>⚙️ Advanced commands</strong></summary>

### Standard tmux fallbacks

| Shortcut | Action |
|---|---|
| `Ctrl+b`, then `c` | New window |
| `Ctrl+b`, then `d` | Detach |
| `Ctrl+b`, then `n` | Next window |
| `Ctrl+b`, then `p` | Previous window |
| `Ctrl+b`, then `%` | Split left / right |
| `Ctrl+b`, then `"` | Split top / bottom |
| `Ctrl+b`, then `x` | Close pane |

### Update

```bash
git pull
./install.sh
```

### Uninstall

```bash
sudo rm -f /usr/local/bin/aon
rm -rf ~/.aon
```

Remove AON-managed sections from:

```text
~/.tmux.conf
~/.bashrc
~/.zshrc
```

</details>

---

<details>
<summary><strong>📁 Project structure</strong></summary>

```text
AON/
├── scripts/
│   ├── aon-notify.sh
│   └── bootstrap.sh
├── install.sh
└── README.md
```

</details>

---

<details>
<summary><strong>🔐 Security notes</strong></summary>

> [!CAUTION]
> Do not store secrets in session names, shell history, or command-line arguments.

AON does not open a network port or replace SSH authentication.

AON sessions run with the permissions of the user who starts them.

</details>

---

## 👤 ${\\color{lightblue}Author}$

Created by **pfix0**

Version **1.0.0**

Built on [tmux](https://github.com/tmux/tmux).

<div align="center">

  <img src="https://img.shields.io/badge/AON-leave%20the%20terminal%2C%20not%20the%20work-00C853?style=for-the-badge" alt="AON">

</div>
