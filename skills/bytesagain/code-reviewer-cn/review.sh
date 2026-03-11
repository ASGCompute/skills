#!/usr/bin/env bash
# Code Reviewer — code-reviewer skill
CMD="$1"; shift 2>/dev/null; INPUT="$*"
case "$CMD" in
  review) cat << 'PROMPT'
你是资深代码审查专家(10年经验)。审查这段代码：
1. 🐛 Bug风险（潜在错误、边界情况）
2. 🏗️ 架构（设计模式、职责分离）
3. ⚡ 性能（时间/空间复杂度、瓶颈）
4. 📖 可读性（命名、注释、格式）
5. 🔒 安全（注入、泄露、权限）
评分1-100，给出TOP3修改建议（标注原代码→修改后）。用中文。
代码：
PROMPT
    echo "$INPUT" ;;
  refactor) cat << 'PROMPT'
你是重构专家。对这段代码进行重构：1.识别代码坏味道 2.应用设计模式 3.输出重构后完整代码 4.解释每步改动。用中文。
代码：
PROMPT
    echo "$INPUT" ;;
  security) cat << 'PROMPT'
你是安全审计专家。检查代码安全漏洞：SQL注入、XSS、CSRF、敏感信息泄露、权限绕过、文件包含等。按OWASP Top 10分类，给出修复代码。用中文。
代码：
PROMPT
    echo "$INPUT" ;;
  naming) cat << 'PROMPT'
你是编码规范专家。检查代码命名：变量名、函数名、类名、常量名是否规范。给出改名建议，遵循各语言惯例(camelCase/snake_case/PascalCase)。用中文。
代码：
PROMPT
    echo "$INPUT" ;;
  complexity) cat << 'PROMPT'
你是算法专家。分析代码复杂度：1.时间复杂度(Big O) 2.空间复杂度 3.圈复杂度(McCabe) 4.认知复杂度 5.优化建议。用中文。
代码：
PROMPT
    echo "$INPUT" ;;
  document) cat << 'PROMPT'
你是技术文档专家。为代码生成文档：1.函数/类的JSDoc/Docstring注释 2.README使用说明 3.API文档(如果适用) 4.示例代码。用中文。
代码：
PROMPT
    echo "$INPUT" ;;
  *) cat << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔍 Code Reviewer — 使用指南
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  review [代码]     代码审查+评分(1-100)
  refactor [代码]   重构建议+完整代码
  security [代码]   安全漏洞检查(OWASP)
  naming [代码]     命名规范检查
  complexity [代码] 复杂度分析(Big O)
  document [代码]   自动生成文档/注释

  Powered by BytesAgain | bytesagain.com | hello@bytesagain.com
EOF
    ;;
esac
