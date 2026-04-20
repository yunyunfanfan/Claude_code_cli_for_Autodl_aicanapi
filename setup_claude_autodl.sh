#!/bin/bash
# Claude Code 一键配置脚本 - 适用于 AutoDL 环境
# 使用方法: bash setup_claude_autodl.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

echo "================================================"
echo "   Claude Code 一键配置脚本 (AutoDL 版)"
echo "================================================"
echo ""

# ── 1. 检查并安装 Node.js ──────────────────────────
install_node() {
    warn "未检测到 Node.js，正在安装..."
    # 使用阿里云镜像加速
    curl -fsSL https://mirrors.aliyun.com/nodejs-release/v20.18.0/node-v20.18.0-linux-x64.tar.xz -o /tmp/node.tar.xz
    tar -xf /tmp/node.tar.xz -C /usr/local --strip-components=1
    rm /tmp/node.tar.xz
    log "Node.js 安装完成: $(node -v)"
}

if command -v node &>/dev/null; then
    NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VER" -lt 18 ]; then
        warn "Node.js 版本过低 ($(node -v))，需要 v18+，重新安装..."
        install_node
    else
        log "Node.js 已安装: $(node -v)"
    fi
else
    install_node
fi

# ── 2. 配置 npm 使用国内镜像（仅用于普通包）──────
log "配置 npm 镜像为淘宝源..."
npm config set registry https://registry.npmmirror.com

# ── 3. 安装 Claude Code ───────────────────────────
# 注意：必须使用官方 npm 源安装 claude-code
# 淘宝源上的 @anthropic-ai/claude-code 是 Windows 版本，缺少 Linux 原生二进制
install_claude() {
    log "从官方 npm 源安装 Claude Code（淘宝源缺少 Linux 原生二进制）..."
    npm install -g @anthropic-ai/claude-code --registry https://registry.npmjs.org
    log "Claude Code 安装完成: $(claude --version 2>/dev/null || echo 'OK')"
}

if command -v claude &>/dev/null; then
    CURRENT_VER=$(claude --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
    log "Claude Code 已安装: $CURRENT_VER"
    warn "是否更新到最新版本？(y/N)"
    read -r UPDATE_CHOICE
    if [[ "$UPDATE_CHOICE" =~ ^[Yy]$ ]]; then
        install_claude
    fi
else
    install_claude
fi

# ── 4. 创建配置目录 ───────────────────────────────
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

# ── 5. 写入 settings.json ─────────────────────────
log "写入 Claude Code 全局配置..."
cat > "$CLAUDE_DIR/settings.json" << 'EOF'
{
  "hasCompletedOnboarding": true,
  "env": {
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "ANTHROPIC_AUTH_TOKEN": "your api key",
    "ANTHROPIC_BASE_URL": "https://aicanapi.com"
  },
  "includeCoAuthoredBy": false
}
EOF

# ── 6. 写入 settings.local.json（权限配置）────────
cat > "$CLAUDE_DIR/settings.local.json" << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(ssh *)"
    ]
  }
}
EOF
log "配置文件写入完成"

log "API Key 和 Base URL 已写入 settings.json，请编辑 ~/.claude/settings.json 填入真实 API Key"

# ── 7. 验证安装 ──────────────────────────────────
echo ""
echo "── 验证安装 ──────────────────────────────────"
log "Node.js: $(node -v)"
log "npm: $(npm -v)"
if command -v claude &>/dev/null; then
    log "Claude Code: $(claude --version 2>/dev/null || echo '已安装')"
else
    err "Claude Code 安装失败，请检查 npm 日志"
fi

echo ""
echo "================================================"
echo "  配置完成！"
echo "================================================"
echo ""
echo "使用前请先编辑 API Key:"
echo "  nano ~/.claude/settings.json"
echo ""
echo "然后启动:"
echo "  claude"
echo ""
