# DingTalk Approval

钉钉 OA 审批处理插件，支持查询待办任务和执行审批操作。

## Description

This skill provides tools to interact with DingTalk (钉钉) OA approval system:
- Query pending approval tasks
- Execute approval actions (approve/reject)

## Tools

### get_pending_tasks
Query the list of pending OA approval tasks for the current user.

**Parameters:** None

**Returns:** List of pending tasks with task_id, title, and other details.

### execute_approval_task
Execute an approval action (agree or refuse) on a specific task.

**Parameters:**
- `task_id` (string, required): The unique ID of the task
- `action` (string, required): Either "AGREE" or "REFUSE"
- `remark` (string, optional): Approval comment/reason

**Returns:** Success or failure message with details.

## Configuration

Add the following to your OpenClaw config:

```json
{
  "plugins": {
    "dingtalk-approval": {
      "dingtalkUserId": "your-dingtalk-user-id",
      "appKey": "your-app-key",
      "appSecret": "your-app-secret"
    }
  }
}
```

## Requirements

- DingTalk application with OA approval permissions
- Valid AppKey and AppSecret from DingTalk Open Platform

## Author

Yang

## License

MIT
