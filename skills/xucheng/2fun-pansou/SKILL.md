---
name: 2fun-pansou
description: "Search cloud-drive and pan-share resources through 2fun.live PanSou aggregation. Use when the user asks to find movie, TV, anime, software, or other downloadable resources on Aliyun Drive, Quark, Baidu, 115, PikPak, magnet, or similar sources. Triggers: 网盘搜索, 找资源, pan search, cloud drive links, 下载链接, 有没有XX资源."
---

# 2fun-pansou Skill

Search PanSou resources via 2fun.live.

## 使用方法

```bash
python3 ~/.openclaw/workspace/skills/2fun-pansou/scripts/search.py "关键词"
```

可通过环境变量覆盖默认入口：

```bash
API_URL=https://www.2fun.live python3 ~/.openclaw/workspace/skills/2fun-pansou/scripts/search.py "关键词"
```

## 支持的云盘类型

☁️ 阿里云盘 / ⚡ 夸克网盘 / 🔵 百度网盘 / 🔷 115网盘  
🟣 PikPak / UC网盘 / 迅雷云盘 / 123网盘 / 天翼云盘 / 移动云盘  
🧲 磁力链接 / 🔗 ED2K

## 常用示例

```bash
# 基本搜索
python3 search.py "流浪地球2"

# 限定云盘类型
python3 search.py "权游 第四季" --types aliyun quark

# 服务端分页（适合翻页/切换云盘）
API_URL=https://www.2fun.live python3 search.py "流浪地球2" --types aliyun --page 2 --page-size 10

# 指定每种类型显示更多结果
python3 search.py "复仇者联盟" --max 5

# 强制刷新缓存（跳过5分钟缓存）
python3 search.py "沙丘2" --refresh

# 原始 JSON 输出
python3 search.py "流浪地球2" --json
```

## API 说明

- 接口：`POST ${API_URL:-https://www.2fun.live}/api/pan/search`
- 请求体：
  - 聚合模式：`{ kw: "关键词", res: "merge" }`
  - 分页模式：`{ kw: "关键词", res: "results", page: 1, page_size: 10, cloud_types: ["aliyun"] }`
- 限速：10次/分钟（按 IP，公开访问无需登录）
- 缓存：服务端 Redis 缓存 5 分钟
- `API_URL` 可覆盖，便于灰度切换到其他 2fun 搜索入口
- 分页模式由服务端完成分页，避免每次翻页都重新拉整份 merge 结果

## 结果格式

```text
🔍 流浪地球2 — 共 42 条结果 (823ms)

☁️ 阿里云盘 (8 个)
  `https://www.aliyundrive.com/s/xxx`  密码: `abc1`

⚡ 夸克网盘 (5 个)
  `https://pan.quark.cn/s/xxx`

🌐 完整搜索：https://www.2fun.live/pan?kw=流浪地球2
```
