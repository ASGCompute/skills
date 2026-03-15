--
name: asgcard
description: Virtual MasterCards for AI agents - crypto payments, USDC wallet, create and manage virtual payment cards autonomously via x402 protocol on Stellar blockchain.
version: 0.2.0
emoji: card
homepage: https://asgcard.dev
metadata:
  openclaw:
      requires:
            env:
                    - ASG_CARD_WALLET_SECRET
                          bins: []
                              primaryEnv: ASG_CARD_WALLET_SECRET
                                  os: ["macos", "linux", "windows"]
                                  ---

                                  # Agent Card - Payment Skill

                                  Give your AI agent a virtual MasterCard. Agent Card lets agents autonomously create, fund, and manage virtual MasterCard cards by paying in USDC on the Stellar blockchain.

                                  ## What It Does

                                  - Create cards - Issue virtual MasterCards with per-card spend limits
                                  - Fund cards - Top up existing cards with USDC
                                  - Manage cards - List, freeze, unfreeze, and inspect card details
                                  - On-chain payments - Every transaction uses the x402 protocol on Stellar with verifiable on-chain proof

                                  ## Setup

                                  ```bash
                                  npx @asgcard/cli onboard -y
                                  ```

                                  ## MCP Tools (9 available)

                                  | Tool | Description |
                                  |------|-------------|
                                  | get_wallet_status | Wallet address, USDC balance, readiness |
                                  | create_card | Create virtual MasterCard (x402 payment) |
                                  | fund_card | Top up existing card |
                                  | list_cards | List all wallet cards |
                                  | get_card | Card summary |
                                  | get_card_details | PAN, CVV, expiry (nonce-protected) |
                                  | freeze_card | Freeze a card |
                                  | unfreeze_card | Re-enable a card |
                                  | get_pricing | Current tier pricing |

                                  ## Links

                                  - [Documentation](https://asgcard.dev/docs)
                                  - [npm SDK](https://npmjs.com/package/@asgcard/sdk)
                                  - [GitHub](https://github.com/ASGCompute/asgcard-public)
                                  
