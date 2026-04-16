# Claude Code CLI 在 AutoDL 上的使用指南（aicanapi 版）

AutoDL 是国内 GPU 云平台，直连 Anthropic API 会超时。本方案通过 [aicanapi.com](https://aicanapi.com) 中转，并针对 AutoDL 环境做了专项优化，一键配置开箱即用。

---

## 为什么在 AutoDL 上配置 Claude Code 很麻烦？

直接在 AutoDL 上使用 Claude Code 会遇到以下几个连环问题：

**1. API 直连被封锁**
AutoDL 服务器在国内，`api.anthropic.com` 无法访问，Claude Code 启动就报 `ERR_BAD_REQUEST` 或 `ETIMEDOUT`，根本无法使用。

**2. Node.js 安装卡住**
Claude Code 需要 Node.js v18+，但 AutoDL 镜像预装的版本通常过低甚至没有。官方安装脚本（`nodesource`）需要访问境外源，在 AutoDL 上往往超时失败，手动安装步骤繁琐。

**3. npm 安装 Claude Code 极慢或失败**
默认 npm 源是 `registry.npmjs.org`，AutoDL 访问境外 npm 仓库速度极慢，安装 Claude Code 经常中途断掉。

**4. 环境变量配置容易出错**
需要同时正确设置 `ANTHROPIC_BASE_URL`（不能加 `/v1`）和 API Key，格式稍有偏差就会导致连接到官方地址或认证失败，排查成本高。

**5. 非必要后台请求干扰**
Claude Code 默认会发送遥测、检查更新等请求到境外地址，即便主要 API 走了中转，这些后台请求仍会报错，造成干扰。

本脚本针对以上每一个痛点都做了专项处理，一键解决。

---

## 前置条件

- AutoDL 实例已开机（Ubuntu 系统）
- 拥有 aicanapi 的 API Key（格式：`sk-...`）

---

## 第一步：获取配置脚本

SSH 登录到 AutoDL 实例后，通过 JupyterLab 上传 `setup_claude_autodl.sh`，或直接在服务器上创建：

```bash
# 通过 scp 上传（注意用 -P 指定端口）
scp -P <port> setup_claude_autodl.sh root@<autodl-ip>:~/
```

---

## 第二步：填入你的 API Key

用任意编辑器打开脚本，将 `ANTHROPIC_AUTH_TOKEN` 的值替换为你自己的 aicanapi Key：

```bash
nano setup_claude_autodl.sh
# 找到这一行，替换为你的 Key：
# "ANTHROPIC_AUTH_TOKEN": "sk-你的key"
```

---

## 第三步：运行一键配置脚本

```bash
bash setup_claude_autodl.sh
```

脚本会自动完成以下所有配置，无需手动操作：

| 步骤 | 说明 | 针对 AutoDL 的处理 |
|------|------|-------------------|
| 安装 Node.js v20 | Claude Code 的运行环境 | 使用阿里云镜像下载预编译包，绕过官方源超时问题 |
| 配置 npm 镜像 | 加速包安装 | 切换为淘宝源，避免访问境外 npm 仓库卡住 |
| 安装 Claude Code | 安装 CLI 本体 | 基于上述镜像，安装不会超时 |
| 写入 settings.json | 注入 Key 和中转地址 | `ANTHROPIC_BASE_URL` 指向 aicanapi，`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` 禁用遥测等会访问境外地址的后台请求 |
| 写入 settings.local.json | 预授权操作权限 | 允许 `Bash(ssh *)` 命令，省去 AutoDL 多节点场景下每次手动确认的麻烦 |

---

## 第四步：启动 Claude Code

进入你的项目目录，启动 Claude Code：

```bash
cd /root/你的项目目录
claude
```

首次启动会显示欢迎界面，直接开始对话即可。

---

## 常用命令

| 命令 | 说明 |
|------|------|
| `claude` | 在当前目录启动交互式会话 |
| `claude "帮我解释这段代码"` | 直接传入问题，非交互模式 |
| `claude --continue` | 继续上一次会话 |
| `claude --model claude-opus-4-6` | 指定使用的模型 |
| `/compact` | 压缩对话历史（节省 token） |
| `/clear` | 清空当前对话 |
| `/help` | 查看所有可用命令 |
| `Ctrl+C` | 中断当前响应 |
| `Ctrl+D` 或 `/exit` | 退出 Claude Code |

---

## 配置文件说明

**`~/.claude/settings.json`**
```json
{
  "hasCompletedOnboarding": true,
  "env": {
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "ANTHROPIC_AUTH_TOKEN": "你的aicanapi-key",
    "ANTHROPIC_BASE_URL": "https://aicanapi.com"
  },
  "includeCoAuthoredBy": false
}
```

- `ANTHROPIC_AUTH_TOKEN`：aicanapi 的 Key，Claude Code 启动时自动注入
- `ANTHROPIC_BASE_URL`：指向 aicanapi 中转地址，绕过国内网络限制
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`：禁用遥测、更新检查等会访问境外地址的后台请求，避免报错干扰正常使用

**`~/.claude/settings.local.json`**
```json
{
  "permissions": {
    "allow": [
      "Bash(ssh *)"
    ]
  }
}
```

- 预授权 SSH 命令，适用于 AutoDL 多节点操作场景

---

## 常见问题

### Q: 提示 `connect ETIMEDOUT` 或 `fetch failed`

aicanapi 连接失败，检查 Key 是否有效：

```bash
curl https://aicanapi.com/v1/models \
  -H "Authorization: Bearer 你的key"
```

### Q: 想更换 API Key

直接编辑 `~/.claude/settings.json`，修改 `ANTHROPIC_AUTH_TOKEN` 的值：

```bash
nano ~/.claude/settings.json
```

### Q: AutoDL 实例重启后配置丢失

AutoDL 的 `/root` 目录在关机后会保留，配置不会丢失。但如果是**重置镜像**，需要重新运行脚本。

---

## 更新 Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

---

## 文件结构

```
~/
├── setup_claude_autodl.sh     # 一键配置脚本
├── claude_autodl_guide.md     # 本文档
└── .claude/
    ├── settings.json          # 全局配置（Key、中转地址、遥测禁用）
    └── settings.local.json    # 本地权限配置（SSH 预授权）
```