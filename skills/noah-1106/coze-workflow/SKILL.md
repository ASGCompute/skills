---
name: coze_workflow
version: 1.1.1
description: Coze 工作流执行技能。接收参数调用工作流，返回执行结果。纯净的调用层，不处理业务逻辑。
homepage: https://www.coze.cn
license: MIT
---

# Coze Workflow - 工作流执行技能

纯净的调用层技能。接收 `workflow_id` 和 `parameters`，执行工作流，返回结果。

## 配置

`~/.openclaw/skills/coze_workflow/config.json`：

```json
{
  "api_key": "pat_xxx",
  "base_url": "https://api.coze.cn"
}
```

## 职责边界

| 职责 | coze_workflow | 业务技能 (如 image_gen_coze) |
|------|---------------|------------------------------|
| 执行工作流 | ✅ | ❌ |
| 参数构建 | ❌ | ✅ |
| 结果解析 | ❌ | ✅ |

## 调用方式

### 输入

```json
{
  "workflow_id": "string",
  "parameters": {}  // 任意 JSON，由业务技能定义
}
```

### 输出

返回 Coze API 的原始响应：

```json
{
  "execute_id": "string",
  "status": "Success|Fail|Running",
  "output": "string",  // 工作流输出（JSON字符串，业务技能解析）
  "debug_url": "string"
}
```

## 执行方法

### 方法 1：流式执行（推荐）

```bash
curl -X POST "${COZE_BASE_URL}/v1/workflow/stream_run" \
  -H "Authorization: Bearer ${COZE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "workflow_id": "xxx",
    "parameters": {...}
  }'
```

**响应**：SSE 流，提取 `event: Message` 的 `data.content` 字段

### 方法 2：轮询查询

```bash
curl "${COZE_BASE_URL}/v1/workflows/{workflow_id}/run_histories/{execute_id}" \
  -H "Authorization: Bearer ${COZE_API_KEY}"
```

## 版本

- v1.1.1: 明确职责边界，纯净调用层
- v1.1.0: 流式执行 + 轮询
- v1.0.0: 初始版本