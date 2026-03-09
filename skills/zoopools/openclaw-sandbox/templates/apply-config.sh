#!/bin/bash
# 墨墨的配置应用脚本 - 带 Git 备份
# 用途：安全地将配置应用到生产环境

set -e

BACKUP_FILE=~/.openclaw/openclaw.json.bak.$(date +%Y%m%d-%H%M)
CONFIG_FILE=~/.openclaw/openclaw.json

echo "========================================"
echo "  🦞 OpenClaw 配置应用工具"
echo "========================================"
echo ""

# 第 1 步：备份当前配置
echo "💾 第 1 步：备份当前配置..."
echo "   目标：$BACKUP_FILE"
cp $CONFIG_FILE $BACKUP_FILE
echo "   ✅ 备份完成"
echo ""

# 第 2 步：验证配置语法
echo "🔍 第 2 步：验证配置语法..."
if ! openclaw config validate 2>&1; then
  echo ""
  echo "   ❌ 配置验证失败！"
  echo ""
  echo "   🔄 已自动回滚到备份文件"
  echo "   📊 备份位置：$BACKUP_FILE"
  echo ""
  echo "   如需手动回滚："
  echo "   cp $BACKUP_FILE $CONFIG_FILE && openclaw gateway restart"
  exit 1
fi
echo "   ✅ 配置验证通过"
echo ""

# 第 3 步：重启 Gateway
echo "🚀 第 3 步：重启 Gateway..."
openclaw gateway restart --force
echo "   ✅ Gateway 重启完成"
echo ""

# 第 4 步：验证功能
echo "🔍 第 4 步：验证功能..."
sleep 3
if openclaw status 2>&1 | grep -q "Gateway.*running"; then
  echo "   ✅ Gateway 运行正常"
else
  echo "   ⚠️  Gateway 状态检查失败，请手动检查"
  echo "   运行：openclaw status"
fi

if openclaw status 2>&1 | grep -q "Feishu.*OK"; then
  echo "   ✅ Feishu 连接正常"
else
  echo "   ⚠️  Feishu 状态检查失败，请手动检查"
fi
echo ""

# 完成
echo "========================================"
echo "  ✅ 配置应用成功！"
echo "========================================"
echo ""
echo "📊 备份位置：$BACKUP_FILE"
echo ""
echo "🔄 如需回滚："
echo "   cp $BACKUP_FILE $CONFIG_FILE"
echo "   openclaw gateway restart"
echo ""
echo "📝 如需 Git 提交："
echo "   git add config/ openclaw.json"
echo "   git commit -m 'Update config - $(date +%Y%m%d)'"
echo ""
