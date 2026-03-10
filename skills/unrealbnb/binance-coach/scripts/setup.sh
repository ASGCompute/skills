#!/usr/bin/env bash
# setup.sh — BinanceCoach first-time setup
# Clones the project, installs deps, and interactively collects API keys

set -euo pipefail

INSTALL_DIR="${BINANCE_COACH_PATH:-$HOME/workspace/binance-coach}"

echo ""
echo "🤖 BinanceCoach — First-Time Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Clone repo if not present ─────────────────────────────────────────────────
if [[ ! -f "$INSTALL_DIR/main.py" ]]; then
    echo "📥 Cloning BinanceCoach from GitHub..."
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone https://github.com/UnrealBNB/BinanceCoachAI.git "$INSTALL_DIR"
    echo "✅ Cloned to $INSTALL_DIR"
else
    echo "✅ Project already at $INSTALL_DIR"
fi

# ── Python dependencies ───────────────────────────────────────────────────────
echo ""
echo "📦 Installing Python dependencies..."
cd "$INSTALL_DIR"
python3 -m pip install -r requirements.txt -q 2>&1 || \
    pip3 install -r requirements.txt --break-system-packages -q 2>&1
echo "✅ Dependencies installed"

# ── Load existing .env if present ────────────────────────────────────────────
ENV_FILE="$INSTALL_DIR/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    cp "$INSTALL_DIR/config.example.env" "$ENV_FILE"
fi

# Helper: read current value from .env
get_env() {
    grep -E "^${1}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2- || echo ""
}

# Helper: set value in .env
set_env() {
    local key="$1" val="$2"
    if grep -qE "^${key}=" "$ENV_FILE" 2>/dev/null; then
        sed -i '' "s|^${key}=.*|${key}=${val}|" "$ENV_FILE"
    else
        echo "${key}=${val}" >> "$ENV_FILE"
    fi
}

# Helper: prompt with current value shown
prompt_key() {
    local key="$1" prompt="$2" current
    current="$(get_env "$key")"
    if [[ -n "$current" && "$current" != *"your_"* && "$current" != *"here"* ]]; then
        read -rp "  $prompt [current: ${current:0:12}...] (Enter to keep): " val
        [[ -z "$val" ]] && val="$current"
    else
        read -rp "  $prompt: " val
    fi
    echo "$val"
}

echo ""
echo "🔑 API Key Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Binance API ───────────────────────────────────────────────────────────────
echo ""
echo "1️⃣  Binance API Keys (read-only)"
echo "   → binance.com → Account → API Management → Create API (enable Read Only)"
echo ""
BINANCE_KEY="$(prompt_key "BINANCE_API_KEY" "Binance API Key")"
BINANCE_SECRET="$(prompt_key "BINANCE_API_SECRET" "Binance API Secret")"
set_env "BINANCE_API_KEY" "$BINANCE_KEY"
set_env "BINANCE_API_SECRET" "$BINANCE_SECRET"

# ── Anthropic API ─────────────────────────────────────────────────────────────
echo ""
echo "2️⃣  Anthropic API Key"
echo "   ℹ️  If you're using BinanceCoach via OpenClaw (plugin mode),"
echo "      you can SKIP this — OpenClaw already has Claude built in."
echo "      Only needed for the standalone Telegram bot or CLI."
echo ""
read -rp "  Set up Anthropic API key? [y/N]: " setup_anthropic
if [[ "${setup_anthropic,,}" == "y" ]]; then
    echo "   → console.anthropic.com → API Keys → Create Key"
    echo ""
    ANTHROPIC_KEY="$(prompt_key "ANTHROPIC_API_KEY" "Anthropic API Key")"
    set_env "ANTHROPIC_API_KEY" "$ANTHROPIC_KEY"
else
    echo "   ⏭️  Skipped — OpenClaw will handle AI analysis natively."
fi

# ── Telegram (optional) ───────────────────────────────────────────────────────
echo ""
echo "3️⃣  Telegram Bot"
echo "   ℹ️  If you're using BinanceCoach via OpenClaw, skip this too."
echo "      OpenClaw already handles Telegram — no separate bot needed."
echo "      Only needed if you want a dedicated @BinanceCoachAIBot"
echo "      running independently of OpenClaw."
echo ""
read -rp "  Set up standalone Telegram bot? [y/N]: " setup_tg
if [[ "${setup_tg,,}" == "y" ]]; then
    echo "   → Telegram: message @BotFather → /newbot → copy token"
    echo "   → Your Telegram user ID: message @userinfobot"
    echo ""
    TG_TOKEN="$(prompt_key "TELEGRAM_BOT_TOKEN" "Bot Token")"
    TG_UID="$(prompt_key "TELEGRAM_USER_ID" "Your Telegram User ID")"
    set_env "TELEGRAM_BOT_TOKEN" "$TG_TOKEN"
    set_env "TELEGRAM_USER_ID" "$TG_UID"
else
    echo "   ⏭️  Skipped — OpenClaw handles Telegram natively."
fi

# ── Language ──────────────────────────────────────────────────────────────────
echo ""
read -rp "4️⃣  Preferred language [en/nl] (default: en): " lang_choice
lang_choice="${lang_choice:-en}"
[[ "$lang_choice" != "nl" ]] && lang_choice="en"
set_env "LANGUAGE" "$lang_choice"

# ── Risk profile ──────────────────────────────────────────────────────────────
echo ""
read -rp "5️⃣  Risk profile [conservative/moderate/aggressive] (default: moderate): " risk_choice
risk_choice="${risk_choice:-moderate}"
set_env "RISK_PROFILE" "$risk_choice"

# ── Monthly DCA budget ────────────────────────────────────────────────────────
echo ""
read -rp "6️⃣  Monthly DCA budget in USD (default: 500): " budget_choice
budget_choice="${budget_choice:-500}"
set_env "DCA_BUDGET_MONTHLY" "$budget_choice"

# ── Data dir ─────────────────────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR/data"

# ── Verify Binance connectivity ───────────────────────────────────────────────
echo ""
echo "🔍 Verifying Binance connection..."
if python3 - <<PYEOF 2>/dev/null
import sys, os
sys.path.insert(0, "$INSTALL_DIR")
from dotenv import load_dotenv
load_dotenv("$ENV_FILE")
from binance.spot import Spot
client = Spot(os.getenv("BINANCE_API_KEY"), os.getenv("BINANCE_API_SECRET"))
client.account()
print("ok")
PYEOF
then
    echo "✅ Binance API connected successfully"
else
    echo "⚠️  Could not verify Binance API (check your keys or network)"
fi

# ── Verify Anthropic connectivity ────────────────────────────────────────────
echo ""
echo "🔍 Verifying Anthropic connection..."
if python3 - <<PYEOF 2>/dev/null
import os
from dotenv import load_dotenv
load_dotenv("$ENV_FILE")
import anthropic
client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY",""))
client.models.list()
print("ok")
PYEOF
then
    echo "✅ Anthropic API connected successfully"
else
    echo "⚠️  Could not verify Anthropic API (check your key)"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅  BinanceCoach setup complete!"
echo ""
echo "   Try it now:"
echo "   • Portfolio analysis:    scripts/bc.sh portfolio"
echo "   • DCA recommendations:   scripts/bc.sh dca"
echo "   • AI coaching:           scripts/bc.sh coach"
echo "   • Demo (no keys):        scripts/bc.sh demo"
if [[ "${setup_tg,,}" == "y" ]]; then
    echo "   • Start Telegram bot:    scripts/bc.sh telegram"
fi
echo ""
