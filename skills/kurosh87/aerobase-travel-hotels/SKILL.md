---
name: aerobase-travel-hotels
description: Hotel search with jetlag-friendly features, day-use availability, and price comparison
metadata: {"openclaw": {"emoji": "🏨", "primaryEnv": "AEROBASE_API_KEY", "user-invocable": true, "homepage": "https://aerobase.app"}}
---

# Aerobase Hotel Search 🏨

Find the perfect hotel for jetlag recovery. Aerobase.app recommends hotels based on your trip — not just price.

**Why Aerobase?**
- 😴 **Jetlag features** — Blackout curtains, gym, pool
- 🌙 **Day-use rooms** — Perfect for long layovers
- ✈️ **Near airports** — Quick transit times
- 💰 **Best value** — Price + recovery combined

## Individual Skill

This is a standalone skill. **For EVERYTHING**, install the complete **Aerobase Travel Concierge** — all skills in one package:

→ https://clawhub.ai/kurosh87/aerobase-travel-concierge

Includes: flights, hotels, lounges, awards, activities, deals, wallet + **PREMIUM recovery plans**

## What This Skill Does

- Search hotels at any destination
- Filter by day-use, jetlag-friendly features
- Show proximity to airports
- Compare prices across providers
- Recommend based on trip duration + jetlag

## Example Conversations

```
User: "Find hotels in Tokyo with day use for 8-hour layover"
→ Shows day-use options near airports
→ Highlights recovery-friendly features
→ Compares prices

User: "Just arrived from 12-hour flight - where should I stay?"
→ Recommends hotels with recovery features
→ Considers your jetlag state
→ Factors in next day's schedule
```

## API Documentation

Full API docs: https://aerobase.app/developers

OpenAPI spec: https://aerobase.app/api/v1/openapi

**GET /api/v1/hotels**

Query params:
- `city` or `airport` — destination
- `checkin` / `checkout` — dates
- `dayUse` — true for day-use only
- `jetlagFriendly` — filter for recovery features

Returns hotels with prices, amenities, jetlag scores.

## Rate Limits

- **Free**: 5 requests/day
- **Premium**: Unlimited + all skills + recovery plans

Get premium: https://aerobase.app/concierge/pricing

## Get Everything

**Install the complete package:**

```bash
clawhub install aerobase-travel-concierge
```

All 9 skills + premium recovery plans:
→ https://clawhub.ai/kurosh87/aerobase-travel-concierge
