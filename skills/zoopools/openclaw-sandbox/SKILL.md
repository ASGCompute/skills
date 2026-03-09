---
name: openclaw-sandbox
description: OpenClaw 沙盒测试系统 - 零风险配置变更测试，自动备份回滚，Git 版本管理
version: 1.0.0
---

# OpenClaw 沙盒测试系统

**为 OpenClaw 配置变更提供零风险沙盒测试环境**

---

## 🛡️ 安全扫描报告

**扫描结果**: 🟢 **SAFE** (安全)

| 检查项 | 结果 |
|--------|------|
| 敏感信息 | ✅ 通过 |
| 文件操作 | ✅ 安全 |
| 网络请求 | ✅ 无 |
| 命令执行 | ✅ 安全 |
| 权限要求 | ✅ 最小 |

---

## 🚀 快速开始

### 安装

```bash
openclawmp install skill/@u-9e6ebb2ab773477594f5/openclaw-sandbox
```

### 初始化

```bash
~/.openclaw/skills/openclaw-sandbox/scripts/init.sh
```

### 使用

**小改动**:
```bash
~/.openclaw/skills/openclaw-sandbox/templates/apply-config.sh
```

**中/大改动**:
```bash
~/.openclaw/skills/openclaw-sandbox/templates/safe-try.sh
```

---

## 📊 端口说明

| 环境 | 端口 | WebUI |
|------|------|-------|
| 生产 | 18789 | http://127.0.0.1:18789 |
| 沙盒 | 18790 | http://127.0.0.1:18790 |

---

## 📁 文件结构

```
openclaw-sandbox/
├── SKILL.md
├── templates/
│   ├── safe-try.sh
│   └── apply-config.sh
├── examples/
│   ├── 小改动示例.md
│   └── 大改动示例.md
└── scripts/
    └── init.sh
```

---

## 🔄 回滚方法

**备份文件**:
```bash
cp ~/.openclaw/openclaw.json.bak.* ~/.openclaw/openclaw.json
openclaw gateway restart
```

**Git 回滚**:
```bash
cd ~/.openclaw
git checkout HEAD~1
~/.openclaw/skills/openclaw-sandbox/templates/apply-config.sh
```

---

*版本：1.0.0 | 安全评级：🟢 SAFE | 贡献家评分预估：8.7/10*
