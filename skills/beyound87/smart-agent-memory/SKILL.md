---
name: smart-agent-memory
version: 1.0.0
description: "跨平台 Agent 长期记忆系统。温度模型 + 结构化存储 + 自动归档 + 知识提炼。双层存储：Markdown（人可读，QMD 可搜索）+ JSON（结构化，快速查询）。纯 Node.js，零外部依赖。"
keywords: [memory, agent, openclaw, longterm, gc, archive, skill-extraction, temperature-model, cross-platform]
metadata:
  openclaw:
    emoji: "🧠"
    requires:
      bins: ["node"]
    trust: high
    permissions:
      - read: ~/.openclaw/workspace/memory
      - write: ~/.openclaw/workspace/memory
---

# Smart Agent Memory 🧠

**跨平台 Agent 长期记忆系统** — 融合温度模型 + 结构化存储 + 自动归档 + 知识提炼。

## Quick Start

```bash
# 记住一个事实
node scripts/memory-cli.js remember "老板喜欢简短汇报" --tags preference,communication

# 搜索记忆
node scripts/memory-cli.js recall "老板 汇报"

# 记录教训
node scripts/memory-cli.js learn --action "未做测试就部署" --context "生产部署" --outcome negative --insight "永远先跑测试"

# 追踪实体
node scripts/memory-cli.js entity "Alex" person --attr role=CTO --attr timezone=GMT+8

# 查看记忆健康
node scripts/memory-cli.js stats

# GC 归档
node scripts/memory-cli.js gc

# 全文搜索 Markdown 文件
node scripts/memory-cli.js search "部署"

# 温度报告
node scripts/memory-cli.js temperature

# 从教训提炼技能
node scripts/memory-cli.js extract <lesson-id> --skill-name deploy-checklist
```

## Core Features

1. **双层存储** — Markdown (人可读, QMD 兼容) + JSON/SQLite (结构化, 快速查询)
2. **智能后端** — 检测到 better-sqlite3 自动升级为 SQLite + FTS5，否则降级 JSON（零依赖也能用）
3. **温度模型** — 🔥热(<7天) / 🟡温(7-30天) / ❄️冷(>30天) 自动分类
4. **自动归档** — 冷数据移到 `.archive/YYYY-MM/`
5. **Fact/Lesson/Entity** — 三层结构化记忆
6. **全文搜索** — SQLite FTS5（精准）或内置轻量搜索（降级），兼容 OpenClaw memory_search
7. **知识提炼** — 从教训自动生成 SKILL.md 模板
8. **自动迁移** — 从 JSON 升级到 SQLite 时自动迁移数据
9. **夜间反思** — 生成健康报告

## OpenClaw Cron Integration

```bash
# 每周日 GC
openclaw cron add --name "memory-gc" --schedule "0 0 * * 0" --tz "Asia/Shanghai" \
  --agent main --message "运行记忆GC：node ~/.openclaw/skills/smart-agent-memory/scripts/memory-cli.js gc"

# 每晚反思
openclaw cron add --name "memory-reflect" --schedule "45 23 * * *" --tz "Asia/Shanghai" \
  --agent main --message "运行记忆反思：node ~/.openclaw/skills/smart-agent-memory/scripts/memory-cli.js reflect"
```

## Storage Layout

```
~/.openclaw/workspace/memory/
├── YYYY-MM-DD.md           ← 每日日志（热/温/冷）
├── lessons/                ← 教训 Markdown
├── decisions/              ← 实体/决策 Markdown
├── people/                 ← 人物档案 Markdown
├── reflections/            ← 反思记录
├── .data/                  ← JSON 结构化数据
│   ├── facts.json
│   ├── lessons.json
│   └── entities.json
├── .archive/               ← 归档冷数据
│   └── YYYY-MM/
└── .index.json             ← 温度索引 + 统计
```

See [README.md](README.md) for full documentation.
