# GUM Architecture Guide

> 本文档面向新加入的开发者，帮助你快速理解 GUM 的整体设计、代码结构和核心实现逻辑。

## 概览

GUM (Git User Manager) 是一个纯 Bash 实现的 CLI 工具，用于管理和切换多个 Git 身份。核心思想：

```
用户身份 = Git Config (user.name + user.email) + SSH Key + SSH Config
```

GUM 将这三者绑定为一个 "Profile"，通过 `gum use <name>` 一键切换。

## 项目文件结构

```
gum/
├── gum.sh              # 主脚本，所有核心逻辑（~1350 行）
├── install.sh          # 安装脚本
├── uninstall.sh        # 卸载脚本
├── README.md           # 英文文档
├── README_CN.md        # 中文文档
├── LICENSE             # MIT 开源协议
├── CHANGELOG.md        # 版本变更记录
├── CONTRIBUTING.md     # 贡献指南
├── .gitignore          # Git 忽略规则
└── docs/
    └── architecture.md # 本文档（架构说明）
```

## 运行时文件结构

安装后，GUM 在用户 Home 目录下创建以下结构：

```
~/.gum/
├── bin/
│   └── gum            # 可执行文件（gum.sh 的拷贝）
├── config             # 用户自定义配置
├── profiles/          # 身份档案目录
│   ├── work.conf      # 每个身份一个文件
│   └── home.conf
└── current            # 纯文本，存储当前激活的档案名
```

## 代码架构

`gum.sh` 采用单文件架构，按功能分为以下模块：

```
┌────────────────────────────────────────────────────────┐
│                    Main Entry Point                      │
│               main() → 命令路由分发                       │
├────────────────────────────────────────────────────────┤
│                    Command Layer                         │
│  gum_init | gum_create | gum_use | gum_list | ...      │
├────────────────────────────────────────────────────────┤
│                   Service Layer                          │
│  gum_select()          交互式选择器                       │
│  gum_update_ssh_config()  SSH 配置管理                   │
│  gum_parse_existing_ssh_configs()  SSH 配置解析           │
├────────────────────────────────────────────────────────┤
│                   Utility Layer                          │
│  gum_echo/warn/error/info  输出格式化                     │
│  gum_profile_exists()     档案存在检查                    │
│  gum_read_profile()       读取档案字段                    │
│  gum_expand_path()        路径展开 (~)                   │
├────────────────────────────────────────────────────────┤
│                   Configuration                         │
│  颜色定义 | 路径常量 | 用户配置加载                         │
└────────────────────────────────────────────────────────┘
```

## 核心模块详解

### 1. Profile 管理

每个 Profile 是一个 `.conf` 文件，使用 `KEY="VALUE"` 格式：

```bash
# ~/.gum/profiles/work.conf
GUM_USER_NAME="zhangsan"
GUM_USER_EMAIL="zhangsan@tencent.com"
GUM_SSH_HOST="git.woa.com"
GUM_SSH_HOSTNAME="git.woa.com"
GUM_SSH_KEY="~/.ssh/id_rsa"
GUM_SSH_PORT=""
```

**为什么用这个格式？**
- 可以直接 `source` 加载
- 人类可读可编辑
- 无需额外依赖（不需要 jq、yq 等）

**读取方式：**
```bash
# 方式一：source 整个文件
source "$GUM_PROFILES_DIR/$name.conf"
echo "$GUM_USER_NAME"

# 方式二：读取单个字段（避免变量污染）
gum_read_profile "$name" "GUM_USER_NAME"
# 内部实现：grep + cut
```

### 2. SSH Config 管理

这是最复杂的模块。核心挑战：**修改 `~/.ssh/config` 但不能破坏用户已有的配置**。

**解决方案：标记注释（Marker Comments）**

```ssh-config
# 用户自己的配置（GUM 不动它）
Host myserver
    HostName 10.0.1.1
    User admin

# >>> gum managed: work >>>
Host git.woa.com
    HostName git.woa.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_rsa
    User git
# <<< gum managed: work <<<
```

**关键函数：**

| 函数 | 作用 |
|------|------|
| `gum_update_ssh_config()` | 移除旧块 → 追加新块 |
| `gum_remove_ssh_config()` | 通过 sed 删除标记间的内容 |
| `gum_parse_existing_ssh_configs()` | 解析非 GUM 管理的 Host 块 |

**SSH Config 解析状态机：**

```
                    ┌─────────────┐
         "Host x"  │             │  "# >>> gum"
    ┌──────────────▶  IN_BLOCK   │──────────────┐
    │              │             │              │
    │              └─────────────┘              ▼
    │                    │              ┌──────────────┐
    │             empty line            │  IN_GUM_BLOCK │
    │                    │              │  (skip all)   │
    │                    ▼              └──────────────┘
    │              ┌──────────┐               │
    │              │  FLUSH   │    "# <<< gum"│
    │              │  output  │◀──────────────┘
    │              └──────────┘
    │                    │
    └────────────────────┘
```

### 3. 交互式选择器 (`gum_select`)

提供类似 `fzf` 的方向键选择体验。

**核心原理：**
1. 隐藏光标 (`\033[?25l`)
2. 打印菜单，当前选中项高亮
3. 循环监听按键：
   - `\033[A` = ↑，`\033[B` = ↓
   - `j`/`k` = vim 风格上下
   - 数字 = 直接跳选
   - Enter = 确认
4. 每次按键后用 ANSI 转义码上移光标、清屏、重绘
5. 确认后恢复光标、清理菜单、显示最终选择

**兼容性处理：**
- 管道输入（`echo "1" | gum create ...`）→ 自动退化为数字输入
- macOS bash 3.2 → 不使用 `read -t 0.1`（仅支持整数超时）
- Ctrl+C → trap 恢复光标

```bash
# 检测是否交互式
if [[ ! -t 0 ]]; then
    # 非交互：打印选项，read 数字
else
    # 交互：方向键选择
fi
```

### 4. `gum use` 切换流程

```
gum use work
    │
    ▼
┌──────────────────────┐
│ 1. 读取 Profile 配置  │  source work.conf
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────────────────┐
│ 2. 更新 Git Config                    │
│    git config --global --replace-all  │
│    user.name "zhangsan"               │
│    user.email "zhangsan@tencent.com"  │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│ 3. 更新 SSH Config                    │
│    删除旧的 gum managed: work 块       │
│    追加新的块（IdentityFile 指向正确 key）│
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────┐
│ 4. 添加 SSH Key 到 ssh-agent  │  ssh-add ~/.ssh/id_rsa
└──────────┬───────────────────┘
           │
           ▼
┌──────────────────────────┐
│ 5. 记录当前 Profile       │  echo "work" > ~/.gum/current
└──────────────────────────┘
```

### 5. `gum use --local` 的区别

```bash
# --local 模式只做步骤 2，且用 --local 而不是 --global
git config --local --replace-all user.name "zhangsan"
git config --local --replace-all user.email "zhangsan@tencent.com"
# 不修改 SSH config，不修改 current 文件
```

这样某个仓库可以有独立身份，不影响全局。

## 设计决策

### 为什么用 Bash？

| 方案 | 优点 | 缺点 |
|------|------|------|
| **Bash** ✓ | 零依赖、macOS/Linux 原生支持、轻量 | 代码量大时维护性一般 |
| Node.js | 易维护、npm 生态 | 需要 Node 运行时 |
| Go | 编译为单文件、性能好 | 开发周期长、用户需下载二进制 |

对于一个配置切换工具，Bash 是最合适的选择——用户不需要安装任何额外依赖。

### 为什么用标记注释管理 SSH Config？

考虑过的方案：
1. ❌ 完全覆写 `~/.ssh/config` → 会丢失用户自定义配置
2. ❌ 用 `Include` 指令引入单独文件 → 需要用户手动配置 Include
3. ✅ 标记注释 → 非侵入式，用户配置和 GUM 配置共存

### 为什么 Profile 用 KEY=VALUE 而不是 JSON/YAML？

1. Bash 原生 `source` 即可加载
2. 用户可以直接用文本编辑器修改
3. 不依赖 `jq`、`yq` 等外部工具

## 命令流转图

```
用户输入: gum <command> [args]
            │
            ▼
        main()
            │
            ├── init     → gum_init()     → 多次调用 gum_select + 创建 profiles
            ├── create   → gum_create()   → gum_select + gum_update_ssh_config
            ├── list     → gum_list()     → 遍历 profiles/, 读取并展示
            ├── use      → gum_use()      → git config + ssh config + ssh-add
            ├── current  → gum_current()  → 读取 current 文件 + git config 验证
            ├── show     → gum_show()     → 读取并格式化展示 profile
            ├── delete   → gum_delete()   → 确认 + 删除文件 + 清理 ssh config
            ├── import   → gum_import()   → 读取当前 git config → 保存为 profile
            ├── config   → gum_config()   → 展示/编辑/重置 ~/.gum/config
            ├── help     → gum_help()     → 打印帮助
            └── version  → gum_version()  → 打印版本号
```

## 扩展指南

### 添加新命令

1. 在 `gum.sh` 中添加 `gum_<command>()` 函数
2. 在 `main()` 的 `case` 中添加路由
3. 在 `gum_help()` 中添加说明
4. 更新 README

### 添加新的 Profile 字段

1. 修改 `gum_create()` 中的 profile 写入部分
2. 修改 `gum_use()` 中读取并应用的逻辑
3. 修改 `gum_show()` 中的展示逻辑

### 支持新的 SSH Key 类型

修改 `gum_create()` 中的 `ssh-keygen` 调用：

```bash
# 当前
ssh-keygen -t ed25519 -C "$user_email" -f "$ssh_key_path"

# 如果要支持 RSA
ssh-keygen -t rsa -b 4096 -C "$user_email" -f "$ssh_key_path"
```

可以通过 `~/.gum/config` 中的 `GUM_SSH_KEY_TYPE` 来控制。

## 测试

由于是 Bash 脚本，测试通过管道输入模拟用户交互：

```bash
# 模拟创建 profile（选择第 3 个 SSH 配置）
printf "ziyi\nziyi@163.com\n3\n" | gum create home

# 验证
gum show home
git config --global user.name  # 切换后验证
```

交互式选择器在管道模式下自动降级为数字输入，确保可脚本化测试。
