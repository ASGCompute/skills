#!/bin/bash
# OpenClaw 沙盒系统初始化脚本

set -e

echo "========================================"
echo "  🦞 OpenClaw 沙盒系统初始化"
echo "========================================"
echo ""

# 第 1 步：检查 Git
echo "📦 第 1 步：检查 Git 仓库..."
cd ~/.openclaw
if [ ! -d ".git" ]; then
    echo "   初始化 Git 仓库..."
    git init
    echo "   创建 .gitignore..."
    cat > .gitignore << 'EOF'
# 日志文件
logs/
*.log

# 沙盒环境
sandbox/
openclaw-sandbox/

# 备份文件
*.bak.*
openclaw.json.bak*

# 临时文件
tmp/
*.tmp
/tmp/

# 状态文件
state/
sessions/*.json.bak
EOF
    git add . 2>/dev/null || true
    git commit -m "Initial baseline - $(date +%Y%m%d)" || true
    echo "   ✅ Git 仓库初始化完成"
else
    echo "   ✅ Git 仓库已存在"
fi
echo ""

# 第 2 步：验证脚本
echo "🔍 第 2 步：验证脚本..."
if [ -f "skills/openclaw-sandbox/templates/safe-try.sh" ]; then
    echo "   ✅ safe-try.sh 存在"
else
    echo "   ❌ safe-try.sh 缺失"
    exit 1
fi

if [ -f "skills/openclaw-sandbox/templates/apply-config.sh" ]; then
    echo "   ✅ apply-config.sh 存在"
else
    echo "   ❌ apply-config.sh 缺失"
    exit 1
fi
echo ""

# 第 3 步：测试沙盒
echo "🧪 第 3 步：测试沙盒 (可选)..."
echo "   运行：~/.openclaw/skills/openclaw-sandbox/templates/safe-try.sh"
echo ""

# 完成
echo "========================================"
echo "  ✅ 初始化完成！"
echo "========================================"
echo ""
echo "📚 下一步："
echo "   1. 查看文档：cat skills/openclaw-sandbox/SKILL.md"
echo "   2. 沙盒测试：./skills/openclaw-sandbox/templates/safe-try.sh"
echo "   3. 应用配置：./skills/openclaw-sandbox/templates/apply-config.sh"
echo ""
