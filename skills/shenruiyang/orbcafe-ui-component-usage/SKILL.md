---
name: orbcafe-ui-component-usage
description: Router skill for ORBCAFE UI. Use when the request is unclear or spans multiple modules, then classify the task and hand off to the most specific ORBCAFE skill (StdReport, Graph+Detail+Agent, Layout+Navigation, Pivot+AINav).
---

# ORBCAFE UI Router

## Purpose

Use this skill as the entry point when a request mentions ORBCAFE UI but does not clearly name the target module.

## Workflow

1. Classify the request using `references/skill-routing-map.md`.
2. Load only the matched module skill references.
3. Enforce public export boundaries from `references/public-export-index.md`.
4. Apply baseline integration checks from `references/integration-baseline.md`.
5. Return:
- Component decision
- Minimal runnable snippet
- Required data shape
- One optional upgrade path

## Trigger Heuristics

- Use this skill first when user asks for:
  - "用 ORBCAFE 组件做一个页面"
  - "不知道选哪个组件"
  - "把旧页面改成 ORBCAFE 风格"
- Do not stay in this skill if intent becomes specific. Switch to the matching module skill.

## Output Contract

Always provide:

1. `Decision`: which ORBCAFE module and why.
2. `Paste-ready code`: imports from `orbcafe-ui` only.
3. `Boundary checks`: 2-4 checks to avoid non-public API usage and hydration/i18n issues.
