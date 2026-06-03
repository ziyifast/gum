<div align="center">

<img src="website/assets/brand/logo-128.png" alt="gum logo" width="120">

# GUM - Git 用户管理器

**一条命令切换 Git 身份。**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Shell-Bash-blue.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)](#安装方式)
[![Website](https://img.shields.io/badge/Website-ziyifast.github.io%2Fgum-purple.svg)](https://ziyifast.github.io/gum/)

[**官网**](https://ziyifast.github.io/gum/) | [English](README.md) | [中文](README_CN.md)

</div>

---

一个轻量级命令行工具，用于管理和切换多个 Git 身份（user.name、user.email、SSH 密钥）。类似于 `nvm` 切换 Node.js 版本，`gum` 让你一条命令切换 Git 账号。

## 痛点

```bash
# 每天重复的操作...
git config --global user.name "zhangsan"
git config --global user.email "zhangsan@company.com"
# 改 ~/.ssh/config...
# ssh-add 正确的 key...
```

## 解决方案

```bash
gum use work    # 搞定。
gum use home    # 切回个人。就这么简单。
```

## 演示

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

## 核心特性

- **一键切换**：`gum use work` / `gum use home`
- **快速初始化**：`gum init` 一次创建 work + home 两个档案
- **智能检测**：自动读取已有 `~/.ssh/config` 配置
- **交互式 UI**：方向键选择（↑/↓/j/k）所有菜单都支持
- **SSH 密钥管理**：自动生成 ed25519 密钥
- **非侵入式**：SSH config 用标记注释管理，你的配置不受影响
- **灵活作用域**：全局切换 或 仅当前仓库（`--local`）
- **可自定义**：通过 `~/.gum/config` 设置默认档案名
- **零依赖**：纯 Bash，macOS 和 Linux 原生支持

## 安装方式

任选其一：

### 一行命令安装（curl | bash）

```bash
curl -fsSL https://raw.githubusercontent.com/ziyifast/gum/main/packaging/install-remote.sh | bash
```

### Homebrew（macOS / Linux）

一条命令：

```bash
brew install ziyifast/tap/gum
```

或者分两步（更直观）：

```bash
brew tap ziyifast/tap
brew install gum
```

### apt-get（Debian / Ubuntu）

从 [Releases](https://github.com/ziyifast/gum/releases) 下载 `.deb` 文件：

```bash
wget https://github.com/ziyifast/gum/releases/latest/download/gum_1.1.0_all.deb
sudo dpkg -i gum_1.1.0_all.deb
```

### Scoop（Windows）

需要先安装 [Git for Windows](https://git-scm.com/download/win)（自带 Git Bash）。

```powershell
scoop bucket add ziyifast https://github.com/ziyifast/gum
scoop install gum
```

### 源码安装

```bash
git clone https://github.com/ziyifast/gum.git
cd gum
sudo make install     # 系统级安装 (/usr/local/bin)
# 或
bash install.sh       # 用户级安装 (~/.gum/bin)
```

安装后重新加载 shell：
```bash
source ~/.zshrc  # 或 ~/.bashrc
```

## 快速上手

### 初始化

```bash
gum init          # 引导创建 work + home 档案
# 或
gum create work   # 单独创建
gum create home
```

### 使用

```bash
gum use work              # 全局切换
gum use home --local      # 仅当前仓库生效
gum current               # 查看当前身份
gum list                  # 查看所有档案
```

## 命令一览

| 命令 | 说明 |
|------|------|
| `gum init` | 快速初始化向导（创建 work + home） |
| `gum create <name>` | 创建新身份档案 |
| `gum list` | 列出所有档案（别名：`ls`） |
| `gum use <name>` | 全局切换 |
| `gum use <name> --local` | 仅当前仓库生效 |
| `gum current` | 显示当前激活的档案 |
| `gum show <name>` | 显示档案详情 + 公钥 |
| `gum delete <name>` | 删除档案（别名：`rm`） |
| `gum import <name>` | 将当前 git config 导入为新档案 |
| `gum config [show\|edit\|reset]` | 管理配置 |
| `gum help` | 显示帮助 |

## 工作原理

`gum use work` 一条命令背后做了这些事：

1. 设置 `git config --global user.name` 和 `user.email`
2. 更新 `~/.ssh/config` 中对应的 SSH 配置块
3. 将 SSH 密钥添加到 `ssh-agent`
4. 记录当前激活的档案

SSH config 通过标记注释管理——**绝不修改你自己的配置**：

```ssh-config
# 你的配置（完全不动）
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

## 自定义配置

通过 `~/.gum/config` 自定义默认值：

```bash
gum config edit
```

```bash
# gum init 时使用的默认档案名
GUM_DEFAULT_PROFILES=("work" "home")

# 也可以自定义：
GUM_DEFAULT_PROFILES=("company" "personal" "freelance")
```

## 使用场景

### 日常工作流

```bash
# 早上上班
gum use work

# 下班回家
gum use home
```

### 某个仓库使用不同身份

```bash
cd ~/projects/my-oss-lib
gum use home --local
# 这个仓库用个人身份，全局仍然是 work
```

### 创建后添加公钥

```bash
# macOS
cat ~/.ssh/gum_work_id_ed25519.pub | pbcopy
# 然后粘贴到 GitHub/GitLab 的 SSH Keys 设置页
```

## 环境要求

- bash 4.0+ 或 zsh
- git
- ssh-keygen & ssh-agent

## 文件结构

```
~/.gum/
├── bin/gum          # 可执行文件
├── config           # 用户设置
├── profiles/        # 身份档案
│   ├── work.conf
│   └── home.conf
└── current          # 当前激活的档案名
```

## 文档

- [架构说明](docs/architecture.md) — 代码结构和设计决策（适合新人阅读）
- [贡献指南](CONTRIBUTING.md) — 如何参与贡献
- [变更记录](CHANGELOG.md) — 版本历史

## 卸载

```bash
cd gum
bash uninstall.sh
```

## 参与贡献

欢迎贡献！详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 开源协议

[MIT](LICENSE)
