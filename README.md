<div align="center">

<img src="website/assets/brand/logo-128.png" alt="gum logo" width="120">

# GUM - Git User Manager

**Switch Git identities in one command.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Shell-Bash-blue.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)](#installation)
[![Website](https://img.shields.io/badge/Website-ziyifast.github.io%2Fgum-purple.svg)](https://ziyifast.github.io/gum/)

[**Website**](https://ziyifast.github.io/gum/) | [English](README.md) | [中文](README_CN.md)

</div>

---

A lightweight CLI tool to manage and switch between multiple Git identities (user.name, user.email, SSH keys). Like `nvm` for Node.js versions, but for Git accounts.

## The Problem

```bash
# Every. Single. Day.
git config --global user.name "zhangsan"
git config --global user.email "zhangsan@company.com"
# ... edit ~/.ssh/config ...
# ... ssh-add the right key ...
# 😤
```

## The Solution

```bash
gum use work    # Done. All of it.
gum use home    # Back to personal. That's it.
```

## Demo

```
$ gum create work
  Git user.name: zhangsan
  Git user.email: zhangsan@tencent.com

  Select SSH config: (↑/↓ select, Enter confirm)
    ❯ git.woa.com (key: ~/.ssh/id_rsa)
      github.com (key: ~/.ssh/id_rsa_github)
      Configure manually

  ✓ Profile 'work' created!

$ gum use work
  ✓ Switched to 'work' (global)
    user.name  = zhangsan
    user.email = zhangsan@tencent.com
    ssh.host   = git.woa.com
```

## Features

- **One-command switching**: `gum use work` / `gum use home`
- **Quick setup**: `gum init` creates work & home profiles in one flow
- **Smart detection**: Auto-reads existing `~/.ssh/config` entries
- **Interactive UI**: Arrow key selection (↑/↓/j/k) for all menus
- **SSH key management**: Auto-generates ed25519 keys
- **Non-destructive**: SSH config managed via marker comments, your entries stay untouched
- **Scope control**: Global (`--global`) or per-repo (`--local`)
- **Customizable**: `~/.gum/config` for your own defaults
- **Zero dependencies**: Pure Bash, works on macOS and Linux

## Installation

Choose your preferred method:

### One-line install (curl | bash)

```bash
curl -fsSL https://raw.githubusercontent.com/ziyifast/gum/main/packaging/install-remote.sh | bash
```

### Homebrew (macOS / Linux)

One-liner:

```bash
brew install ziyifast/tap/gum
```

Or in two steps if you prefer:

```bash
brew tap ziyifast/tap
brew install gum
```

### apt-get (Debian / Ubuntu)

Download the `.deb` from [Releases](https://github.com/ziyifast/gum/releases):

```bash
wget https://github.com/ziyifast/gum/releases/latest/download/gum_1.1.0_all.deb
sudo dpkg -i gum_1.1.0_all.deb
```

### Scoop (Windows)

Requires [Git for Windows](https://git-scm.com/download/win) (provides Git Bash).

```powershell
scoop bucket add ziyifast https://github.com/ziyifast/gum
scoop install gum
```

### From source

```bash
git clone https://github.com/ziyifast/gum.git
cd gum
sudo make install     # System-wide (/usr/local/bin)
# OR
bash install.sh       # User-local (~/.gum/bin)
```

After installation, reload your shell:
```bash
source ~/.zshrc  # or ~/.bashrc
```

## Quick Start

### Setup

```bash
gum init          # Guided setup for work & home profiles
# or
gum create work   # Create profiles individually
gum create home
```

### Use

```bash
gum use work              # Switch globally
gum use home --local      # Switch for current repo only
gum current               # Check active profile
gum list                  # See all profiles
```

## Commands

| Command | Description |
|---------|-------------|
| `gum init` | Quick setup wizard (create work & home) |
| `gum create <name>` | Create a new identity profile |
| `gum list` | List all profiles (alias: `ls`) |
| `gum use <name>` | Switch globally |
| `gum use <name> --local` | Switch for current repo only |
| `gum current` | Show active profile |
| `gum show <name>` | Show profile details + public key |
| `gum delete <name>` | Delete a profile (alias: `rm`) |
| `gum import <name>` | Import current git config as profile |
| `gum config [show\|edit\|reset]` | Manage gum settings |
| `gum help` | Show help |

## How It Works

`gum use work` does all of this in one command:

1. Sets `git config --global user.name` and `user.email`
2. Updates the relevant SSH config block in `~/.ssh/config`
3. Adds the SSH key to `ssh-agent`
4. Records the active profile

SSH config is managed with marker comments — your own entries are never modified:

```ssh-config
# Your config (untouched)
Host myserver
    HostName 10.0.1.1
    User admin

# >>> gum managed: work >>>
Host git.woa.com
    HostName git.woa.com
    IdentityFile ~/.ssh/id_rsa
    User git
# <<< gum managed: work <<<
```

## Configuration

Customize defaults in `~/.gum/config`:

```bash
gum config edit
```

```bash
# Default profile names for 'gum init'
GUM_DEFAULT_PROFILES=("work" "home")

# Or customize for your workflow:
GUM_DEFAULT_PROFILES=("company" "personal" "freelance")
```

## Requirements

- bash 4.0+ or zsh
- git
- ssh-keygen & ssh-agent

## File Structure

```
~/.gum/
├── bin/gum          # Executable
├── config           # User settings
├── profiles/        # Identity profiles
│   ├── work.conf
│   └── home.conf
└── current          # Active profile name
```

## Documentation

- [Architecture Guide](docs/architecture.md) — Code structure and design decisions
- [Contributing](CONTRIBUTING.md) — How to contribute
- [Changelog](CHANGELOG.md) — Version history

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
