---
name: binance-coach
description: AI-powered crypto trading behavior coach for Binance users. Analyzes live portfolio health, detects emotional trading patterns (FOMO, panic selling, overtrading), provides smart DCA recommendations based on RSI + Fear & Greed index, and delivers personalized AI coaching via Claude. Use when a user asks to: analyze their crypto portfolio, get DCA advice, check market conditions (RSI, Fear & Greed, SMA200), review trading behavior/FOMO/panic sells, get AI coaching on their holdings, set price/RSI alerts, learn about crypto concepts (RSI, DCA, SMA200), start a Telegram trading coach bot, or ask anything about their Binance portfolio.
---

# BinanceCoach

AI-powered crypto trading behavior coach. Connects to the user's Binance account (read-only) and provides portfolio analysis, behavioral coaching, and smart DCA recommendations via Claude.

## How AI coaching works in OpenClaw mode

When used as an OpenClaw skill, **only a Binance API key is required**:

| | OpenClaw skill | Standalone bot |
|---|---|---|
| Binance API key | ✅ Required | ✅ Required |
| Anthropic API key | ❌ Not needed | ✅ Required |
| Telegram bot token | ❌ Not needed | ✅ Required |

OpenClaw is already Claude and already handles Telegram. BinanceCoach provides the Binance data layer — OpenClaw does the AI analysis and messaging natively.

The `bc.sh coach`, `bc.sh weekly`, `bc.sh ask`, and `bc.sh telegram` commands exist for standalone use only. In OpenClaw mode, just ask naturally — the data commands are all you need.

## Setup (run this first)

```bash
scripts/setup.sh
```

`setup.sh` fully automates first-time setup:
1. Clones `https://github.com/UnrealBNB/BinanceCoachAI.git` into `~/workspace/binance-coach/`
2. Installs all Python dependencies (`pip install -r requirements.txt`)
3. Interactively prompts for: Binance API keys, Anthropic API key, Telegram bot token (optional), language, risk profile, monthly DCA budget
4. Writes all answers to `.env` automatically
5. Verifies Binance + Anthropic connectivity

**When to run setup:**
- First time the skill is used on a new machine
- When a user says "set up BinanceCoach", "install the bot", "configure my keys"
- When `bc.sh <command>` returns "project not found" or API errors

**After setup**, all commands work immediately. No manual file editing needed.

## Running Commands

All commands run via the wrapper:

```bash
scripts/bc.sh <command> [args]
```

Or directly:

```bash
cd "$(scripts/bc.sh --path)" && python3 main.py
```

## Key Commands

| User asks about | Run |
|---|---|
| Portfolio health/score | `scripts/bc.sh portfolio` |
| DCA for BTC/ETH/BNB | `scripts/bc.sh dca` |
| DCA for specific coin | `scripts/bc.sh dca DOGEUSDT` |
| Fear & Greed index | `scripts/bc.sh fg` |
| Market data for a coin | `scripts/bc.sh market BTCUSDT` |
| Behavioral analysis | `scripts/bc.sh behavior` |
| Set price alert | `scripts/bc.sh alert BTCUSDT above 70000` |
| List alerts | `scripts/bc.sh alerts` |
| Educational lesson | `scripts/bc.sh learn rsi_oversold` |
| 12-month DCA projection | `scripts/bc.sh project BTCUSDT` |
| AI coaching summary | `scripts/bc.sh coach` |
| Weekly AI brief | `scripts/bc.sh weekly` |
| Ask Claude a question | `scripts/bc.sh ask "should I buy more DOGE?"` |
| Start Telegram bot | `scripts/bc.sh telegram` |

## Output Handling

- Commands print rich terminal output — relay key findings to the user
- For `coach`, `weekly`, `ask`: the AI response is the full answer; present it directly
- For `portfolio`: summarise score, grade, top holdings, and suggestions
- For `dca`: share the multiplier and weekly amount for each coin, plus the rationale
- For `behavior`: highlight FOMO score, overtrading label, and any panic sells detected

## Language

Set language via env: `LANGUAGE=en` (English) or `LANGUAGE=nl` (Nederlands).
Or per-session: `scripts/bc.sh --lang nl portfolio`

## Full Command Reference

See `references/commands.md` for all commands, flags, and output formats.
See `references/setup.md` for first-time configuration and API key setup.
