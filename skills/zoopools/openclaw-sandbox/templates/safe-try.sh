#!/bin/bash
# 墨墨的影子沙盒 - 融合豆包 + Gemini 精华
# 用途：在隔离环境中测试配置，不影响生产环境

SANDBOX_PORT=18790
SANDBOX_STATE="/tmp/openclaw-sandbox-state-$$"

echo "🧪 正在启动沙盒验证环境 (Port: $SANDBOX_PORT)..."
echo "⚠️  此环境仅用于验证配置，不修改生产数据"
echo ""

# 准备干净的临时状态目录（Gemini 的建议 - 防止数据库锁冲突）
rm -rf $SANDBOX_STATE && mkdir -p $SANDBOX_STATE

# 捕获退出信号，清理临时目录
trap "echo ''; echo '🧹 清理沙盒状态目录...'; rm -rf $SANDBOX_STATE; echo '✅ 沙盒已停止'" EXIT

# 启动沙盒网关（豆包的端口隔离 + Gemini 的状态隔离）
echo "📁 临时状态目录：$SANDBOX_STATE"
echo ""

OPENCLAW_STATE=$SANDBOX_STATE openclaw gateway start \
  --port $SANDBOX_PORT \
  --log-level info

echo ""
echo "📊 沙盒 WebUI: http://127.0.0.1:$SANDBOX_PORT"
echo "📊 生产 WebUI: http://127.0.0.1:18789 (不受影响)"
echo ""
echo "按 Ctrl+C 停止沙盒"
