# DingTalk Approval Skill

钉钉 OA 审批处理插件，支持查询待办任务和执行审批操作。

## 功能

- **查询待办**: 获取当前用户的 OA 审批待办列表
- **执行审批**: 对待办任务进行同意或拒绝操作

## 安装

```bash
clawhub install dingtalk-approval
```

## 配置

在 `~/.openclaw/config.json` 中添加以下配置：

```json
{
  "plugins": {
    "dingtalk-approval": {
      "dingtalkUserId": "你的钉钉用户ID",
      "appKey": "钉钉应用 AppKey",
      "appSecret": "钉钉应用 AppSecret"
    }
  }
}
```

### 获取配置信息

1. **钉钉用户ID**: 在钉钉管理后台 → 通讯录 → 找到用户 → 查看 UserID
2. **AppKey & AppSecret**: 在钉钉开放平台 → 应用详情页获取

## 使用示例

### 查询待办

```
查询我的钉钉待办审批
```

### 执行审批

```
同意任务 123456，备注：同意申请
```

或

```
拒绝任务 123456，理由：信息不完整
```

## 工具列表

| 工具名 | 描述 |
|--------|------|
| `get_pending_tasks` | 查询待办审批列表 |
| `execute_approval_task` | 执行审批（同意/拒绝） |

## 注意事项

- 确保钉钉应用已开通"OA审批"相关权限
- 执行审批需要应用具有相应的操作权限
- 审批操作会实际影响钉钉中的审批流程

## 版本历史

- **v1.1.0** - 支持配置化，可复用给多个用户
- **v1.0.0** - 初始版本，支持查询和执行审批

## License

MIT
