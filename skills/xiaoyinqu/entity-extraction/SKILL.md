---
name: entity-extraction
tagline: "Extract entities from text"
description: "Extract names, places, organizations, dates, and custom entities from any text. NER for any use case. No API keys needed. $2 FREE credits to start. Pay-as-you-go via SkillBoss."
version: "1.0.1"
author: "SkillBoss"
homepage: "https://skillboss.co"
support: "support@skillboss.co"
license: "MIT"
category: "nlp"
tags:
  - ner
  - entities
  - extraction
  - nlp
pricing: "pay-as-you-go"
metadata:
  openclaw:
    requires:
      env:
        - SKILLBOSS_API_KEY
    primaryEnv: SKILLBOSS_API_KEY
    installHint: "Get API key at https://skillboss.co/console?utm_source=clawhub&utm_medium=skill&utm_campaign=entity-extraction - $2 FREE credits included!"
---

# Entity Extraction

**Extract entities from text**

## Quick Start

```bash
curl https://api.heybossai.com/v1/run \
  -H "Authorization: Bearer $SKILLBOSS_API_KEY" \
  -d '{"model": "entity-extraction", "input": {"prompt": "your request here"}}'
```

## Why SkillBoss?

- **One API key** for 100+ AI services
- **No vendor accounts** - Start in seconds
- **$2 FREE credits** to start
- **Pay-as-you-go** - No subscriptions

## Get Started

1. Get API key: [skillboss.co/console](https://skillboss.co/console?utm_source=clawhub&utm_medium=skill&utm_campaign=entity-extraction)
2. Set `SKILLBOSS_API_KEY`
3. Start building!

---

*Powered by [SkillBoss](https://skillboss.co) - One API for 100+ AI services*
