---
name: youtube-downloader
description: YouTube video search, download & subtitle extraction. 40 Stars! Supports video/audio/subtitles. Each call charges 0.001 USDT via SkillPay.
version: 1.0.0
author: moson
tags:
  - youtube
  - download
  - video
  - subtitles
  - audio
  - mp3
  - yt-dlp
homepage: https://github.com/joeseesun/yt-search-download
metadata:
  clawdbot:
    requires:
      env:
        - SKILLPAY_API_KEY
triggers:
  - "youtube download"
  - "youtube search"
  - "download video"
  - "extract subtitles"
  - "youtube to mp3"
  - "youtube audio"
  - "下载youtube"
  - "youtube字幕"
  - "视频下载"
  - "提取音频"
config:
  SKILLPAY_API_KEY:
    type: string
    required: true
    secret: true
---

# YouTube Downloader & Search

## 功能

YouTube video search, download & subtitle extraction based on yt-dlp.

### 核心功能

- **Video Search**: Search by keyword, channel, sort by date/views
- **Video Download**: Support 4K, 1080p, various formats
- **Audio Extract**: Download as MP3
- **Subtitle Download**: SRT (with timestamps) + TXT (for AI)
- **Chinese Translation**: Auto-translate English titles to Chinese
- **Channel Browse**: Browse channel latest videos

## 使用方法

```json
{
  "action": "search",
  "query": "AI news",
  "limit": 10
}
```

## 输出示例

```json
{
  "success": true,
  "action": "search",
  "results": [
    {
      "title": "State of AI 2026",
      "views": "741K",
      "duration": "4h25m",
      "url": "https://youtube.com/watch?v=..."
    }
  ]
}
```

## 价格

每次调用: 0.001 USDT

## 安装前置

- YouTube API Key (from Google Cloud Console)
- yt-dlp: `pip install yt-dlp`
