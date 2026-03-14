---
name: colorpick
description: "配色方案生成、色彩和谐(互补/类似/三色)、品牌配色、对比度检查(WCAG)、颜色格式转换(HEX/RGB/HSL)、流行色推荐。Color palette generator with harmony, brand colors, WCAG contrast check, format conversion, trending colors. Use when you need colorpick capabilities. Triggers on: colorpick."
---

# Color Palette 🎨

配色方案生成与色彩工具。

## 使用方式

当用户需要配色方案、色彩搭配、对比度检查、颜色格式转换时，运行脚本：

```bash
bash scripts/color.sh <command> [options]
```

## 命令列表

| 命令 | 说明 | 参数 |
|------|------|------|
| `generate` | 生成配色方案 | `<theme>` 主题关键词 |
| `harmony` | 色彩和谐方案 | `<hex_color> <type>` type: complementary/analogous/triadic/split/tetradic |
| `brand` | 品牌配色推荐 | `<industry>` 行业: tech/food/fashion/health/finance/education |
| `contrast` | WCAG对比度检查 | `<fg_hex> <bg_hex>` |
| `convert` | 颜色格式转换 | `<color>` 支持HEX/RGB/HSL |
| `trending` | 流行色推荐 | `[year]` 可选年份 |

## 输出

所有颜色输出包含 HEX、RGB、HSL 三种格式，方便直接使用。

## 示例

```bash
# 生成科技主题配色
bash scripts/color.sh generate tech

# 获取互补色
bash scripts/color.sh harmony "#3498db" complementary

# 检查对比度是否符合WCAG
bash scripts/color.sh contrast "#333333" "#ffffff"

# 转换颜色格式
bash scripts/color.sh convert "#ff6600"
```
---
💬 Feedback & Feature Requests: https://bytesagain.com/feedback
Powered by BytesAgain | bytesagain.com
