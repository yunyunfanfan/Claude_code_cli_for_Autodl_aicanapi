# Claude Code CLI 在 AutoDL 上的使用指南（aicanapi 版）

AutoDL 是国内 GPU 云平台，直连 Anthropic API 会超时。本方案通过 [aicanapi.com](https://aicanapi.com) 中转，开箱即用。

---

## 前置条件

- AutoDL 实例已开机（Ubuntu 系统）
- 拥有 aicanapi 的 API Key（格式：`sk-...`）

---

## 第一步：获取配置脚本

SSH 登录到 AutoDL 实例后，下载或创建配置脚本。

**方式 A：从本地上传**

```bash
scp setup_claude_autodl.sh root@<autodl-ip>:<port>:~/
```

**方式 B：直接在服务器上创建**

将 `setup_claude_autodl.sh` 的内容粘贴到服务器，或通过 JupyterLab 上传。

---

## 第二步：运行一键配置脚本

脚本已内置 aicanapi 的 Key 和 Base URL，直接运行即可，无需任何交互：

```bash
bash setup_claude_autodl.sh
```

---

## 第三步：验证配置

```bash
claude --version
```

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

脚本会自动写入以下配置：

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
- `ANTHROPIC_AUTH_TOKEN`: aicanapi 的 Key，Claude Code 启动时自动注入
- `ANTHROPIC_BASE_URL`: 指向 aicanapi 中转地址，绕过国内网络限制
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`: 禁用遥测等非必要请求

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
- 允许 Claude Code 执行 SSH 命令，无需每次手动确认

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
    ├── settings.json          # 全局配置
    └── settings.local.json    # 本地权限配置
```
