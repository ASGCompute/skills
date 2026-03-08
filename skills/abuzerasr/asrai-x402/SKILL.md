---
name: asrai-x402
description: Crypto market analysis using Asrai API. Covers technical analysis, screeners, sentiment, forecasting, smart money, Elliott Wave, cashflow, DEX data, and AI-powered insights. Each API call costs $0.005 USDC from your own wallet on Base mainnet via x402.
license: MIT
metadata: {"openclaw":{"emoji":"📈","requires":{"env":["ASRAI_PRIVATE_KEY"]}},"clawdbot":{"emoji":"📈","requires":{"env":["ASRAI_PRIVATE_KEY"]}}}
---

# Asrai — Crypto Analysis via x402

Use Asrai tools when the user asks about crypto prices, market analysis, trading signals, sentiment, or investment advice.

## When to use

- Crypto price / chart / technical analysis → use asrai tools
- Market sentiment, CBBI, fear/greed → use asrai tools
- "What should I buy?" / portfolio advice → use `portfolio` tool
- Elliott Wave, smart money, order blocks → use asrai tools
- DEX data, low-cap tokens → use asrai tools
- General knowledge you already know well → answer directly (costs $0.005 per call)

## How to call

### If asrai MCP tools are available (Cursor, Cline, Claude Desktop)

Call the appropriate MCP tool directly:
```
technical_analysis(symbol, timeframe)
sentiment()
forecast(symbol)
market_overview()
ask_ai(question)
...
```

### If no MCP tool — use bash (OpenClaw and other agents)

Use the same tool names via bash:
```bash
npx -y -p asrai-mcp asrai <tool> [args...]
```

Examples:
```bash
npx -y -p asrai-mcp asrai ask_ai "What is the outlook for BTC today?"
npx -y -p asrai-mcp asrai technical_analysis BTC 4h
npx -y -p asrai-mcp asrai sentiment
npx -y -p asrai-mcp asrai forecast ETH
npx -y -p asrai-mcp asrai market_overview
npx -y -p asrai-mcp asrai coin_info SOL
npx -y -p asrai-mcp asrai portfolio
npx -y -p asrai-mcp asrai indicator_guide ALSAT
```

Requires `ASRAI_PRIVATE_KEY` set in `~/.env` or environment. Payment is signed automatically.

## MCP tools

| Tool | What it does | Cost |
|---|---|---|
| `market_overview` | Trending, gainers/losers, RSI, sentiment, screeners | $0.095 |
| `technical_analysis(symbol, timeframe)` | Signals, ALSAT, SuperALSAT, Elliott Wave, Ichimoku | $0.06 |
| `sentiment` | CBBI, CMC sentiment, AI insights | $0.015 |
| `forecast(symbol)` | AI price forecast | $0.005 |
| `screener(type)` | Find coins by criteria | $0.005 |
| `smart_money(symbol, timeframe)` | Order blocks, FVGs, support/resistance | $0.01 |
| `elliott_wave(symbol, timeframe)` | Elliott Wave analysis | $0.005 |
| `ichimoku(symbol, timeframe)` | Ichimoku cloud | $0.005 |
| `cashflow(mode, symbol)` | Capital flow | $0.005 |
| `coin_info(symbol)` | Stats, price, CMC AI, DEX data | $0.025–$0.03 |
| `dexscreener(contract)` | DEX data | $0.005 |
| `chain_tokens(chain, max_mcap)` | Low-cap tokens on chain | $0.005 |
| `portfolio` | Abu's curated model portfolio | $0.005 |
| `channel_summary` | Latest narratives | $0.005 |
| `ask_ai(question)` | AI analyst answer | $0.01 |
| `indicator_guide(name)` | Guide for custom indicators | FREE |

## Output rules

- Write like an experienced trader explaining to a friend — conversational, confident, direct
- Think like both a trader AND a long-term investor. Default to investor mode. Switch to trader mode only when user asks for entries
- Keep responses 200–400 words. Short lines, breathing room between sections
- Never list raw indicator values — synthesize into plain language verdict
- End with 1 clear action bias: accumulate / wait / avoid — and why
- Never mention tool names, API calls, or payment details in responses

## Cost

$0.005 USDC per call (most tools), $0.01 for `ask_ai`, FREE for `indicator_guide`. Signed from the user's own wallet on Base mainnet. Tell the user if they ask.

## Install

```bash
npx -y -p asrai-mcp install-skill
```

Auto-detects OpenClaw, Cursor, Cline, and other agents. Then set your key:

```
ASRAI_PRIVATE_KEY=0x<your_private_key>  # add to ~/.env
```

For MCP agents (Cursor, Cline, Claude Desktop) also add to config:

```json
{
  "mcpServers": {
    "asrai": { "command": "npx", "args": ["-y", "asrai-mcp"] }
  }
}
```
