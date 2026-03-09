#!/usr/bin/env bash
# email.sh — 邮件写作助手（中英双语）
set -euo pipefail

DATE=$(date '+%Y-%m-%d')

show_help() {
    cat <<'EOF'
邮件写作助手 - email.sh

用法：
  email.sh business "收件人" "主题"              商务邮件
  email.sh followup "主题"                       跟进邮件
  email.sh cold     "公司" "目的"                冷启动邮件
  email.sh apology  "原因"                       道歉邮件
  email.sh reply    "原文摘要" [--tone formal|friendly]  回复邮件
  email.sh help                                  显示本帮助

示例：
  email.sh business "王总" "合作方案"
  email.sh followup "上周会议跟进"
  email.sh cold "字节跳动" "技术合作"
  email.sh apology "发货延迟"
  email.sh reply "对方询问报价" --tone formal
EOF
}

cmd_business() {
    local recipient="$1"
    local subject="$2"
    python3 -c "
import sys

date = '${DATE}'
recipient = sys.argv[1]
subject = sys.argv[2]

print('=' * 60)
print('商务邮件模板'.center(60))
print('=' * 60)
print('')
print('【中文版】')
print('')
print('收件人：{}'.format(recipient))
print('主题：关于{} — 合作洽谈'.format(subject))
print('')
print('{}，您好！'.format(recipient))
print('')
print('感谢您百忙之中阅读此邮件。')
print('')
print('我是______（公司名）的______（职位），')
print('就{}事宜，希望与您进一步沟通：'.format(subject))
print('')
print('1. （要点一）')
print('2. （要点二）')
print('3. （要点三）')
print('')
print('如方便，希望能安排一次会议详细讨论。')
print('以下时间我都可以：')
print('  - ')
print('  - ')
print('')
print('期待您的回复。')
print('')
print('此致')
print('敬礼')
print('')
print('______（署名）')
print('______（职位）')
print('______（联系方式）')
print('')
print('-' * 60)
print('')
print('【English Version】')
print('')
print('To: {}'.format(recipient))
print('Subject: Re: {} — Business Proposal'.format(subject))
print('')
print('Dear {},'.format(recipient))
print('')
print('Thank you for taking the time to read this email.')
print('')
print('I am writing to discuss {} and explore potential'.format(subject))
print('collaboration opportunities:')
print('')
print('1. (Key point 1)')
print('2. (Key point 2)')
print('3. (Key point 3)')
print('')
print('Would you be available for a meeting to discuss further?')
print('I am available at the following times:')
print('  - ')
print('  - ')
print('')
print('Looking forward to your reply.')
print('')
print('Best regards,')
print('______')
print('______（Title）')
print('______（Contact）')
print('=' * 60)
" "$recipient" "$subject"
}

cmd_followup() {
    local subject="$1"
    python3 -c "
import sys

date = '${DATE}'
subject = sys.argv[1]

print('=' * 60)
print('跟进邮件模板'.center(60))
print('=' * 60)
print('')
print('【中文版】')
print('')
print('主题：跟进：{}'.format(subject))
print('')
print('您好，')
print('')
print('上次就「{}」的沟通，想跟您确认一下进展：'.format(subject))
print('')
print('1. 上次我们讨论了______')
print('2. 您提到会______')
print('3. 目前的状态是______')
print('')
print('请问是否有更新？如需我这边提供补充材料，')
print('随时告知。')
print('')
print('谢谢！')
print('______')
print('')
print('-' * 60)
print('')
print('【English Version】')
print('')
print('Subject: Follow-up: {}'.format(subject))
print('')
print('Hi,')
print('')
print('I wanted to follow up on our previous discussion')
print('regarding \"{}\".'.format(subject))
print('')
print('1. We discussed ______')
print('2. You mentioned ______')
print('3. Current status: ______')
print('')
print('Any updates on your end? Please let me know if you')
print('need any additional materials from us.')
print('')
print('Thanks,')
print('______')
print('=' * 60)
" "$subject"
}

cmd_cold() {
    local company="$1"
    local purpose="$2"
    python3 -c "
import sys

date = '${DATE}'
company = sys.argv[1]
purpose = sys.argv[2]

print('=' * 60)
print('冷启动邮件模板'.center(60))
print('=' * 60)
print('')
print('【中文版】')
print('')
print('主题：{}方面的合作机会 | ______（你的公司）x {}'.format(purpose, company))
print('')
print('您好，')
print('')
print('冒昧打扰，我是______（你的公司/职位）。')
print('')
print('关注到{}在______领域的出色表现，'.format(company))
print('特别是______方面。')
print('')
print('我们专注于{}，'.format(purpose))
print('相信在以下方面可以产生协同：')
print('')
print('  ✦ （价值点1 — 对对方的好处）')
print('  ✦ （价值点2 — 具体数据/案例）')
print('  ✦ （价值点3 — 差异化优势）')
print('')
print('是否方便用15分钟简单聊聊？')
print('')
print('附上我们的简介供参考：______')
print('')
print('期待交流！')
print('______')
print('')
print('-' * 60)
print('')
print('【English Version】')
print('')
print('Subject: {} Opportunity | ______ x {}'.format(purpose, company))
print('')
print('Hi,')
print('')
print('I hope this email finds you well. My name is ______')
print('from ______ (company).')
print('')
print('I have been following {}\\'s impressive work in ______,'.format(company))
print('particularly in ______ area.')
print('')
print('We specialize in {}, and I believe there are'.format(purpose))
print('synergies in the following areas:')
print('')
print('  - (Value proposition 1)')
print('  - (Value proposition 2)')
print('  - (Value proposition 3)')
print('')
print('Would you have 15 minutes for a quick chat?')
print('')
print('Best,')
print('______')
print('=' * 60)
" "$company" "$purpose"
}

cmd_apology() {
    local reason="$1"
    python3 -c "
import sys

date = '${DATE}'
reason = sys.argv[1]

print('=' * 60)
print('道歉邮件模板'.center(60))
print('=' * 60)
print('')
print('【中文版】')
print('')
print('主题：关于{}的致歉及解决方案'.format(reason))
print('')
print('尊敬的______：')
print('')
print('就「{}」一事，我们深表歉意。'.format(reason))
print('')
print('【事情经过】')
print('  ______（简要说明发生了什么）')
print('')
print('【原因分析】')
print('  ______（坦诚说明原因，不找借口）')
print('')
print('【解决方案】')
print('  1. 立即措施：______')
print('  2. 补偿方案：______')
print('  3. 防止复发：______')
print('')
print('【改进承诺】')
print('  我们已______，确保类似情况不再发生。')
print('')
print('再次为给您带来的不便表示诚挚歉意。')
print('如有任何疑问，请随时联系我。')
print('')
print('此致')
print('敬礼')
print('______')
print('')
print('-' * 60)
print('')
print('【English Version】')
print('')
print('Subject: Our Sincere Apology Regarding {} & Resolution Plan'.format(reason))
print('')
print('Dear ______,')
print('')
print('We sincerely apologize for the issue regarding')
print('\"{}\".'.format(reason))
print('')
print('[What Happened]')
print('  ______ (brief explanation)')
print('')
print('[Root Cause]')
print('  ______ (honest explanation)')
print('')
print('[Resolution]')
print('  1. Immediate action: ______')
print('  2. Compensation: ______')
print('  3. Prevention: ______')
print('')
print('We have taken steps to ensure this does not happen again.')
print('Please do not hesitate to reach out with any concerns.')
print('')
print('Sincerely,')
print('______')
print('=' * 60)
" "$reason"
}

cmd_reply() {
    local original="$1"
    shift
    local tone="formal"
    while [ $# -gt 0 ]; do
        case "$1" in
            --tone) tone="${2:-formal}"; shift 2 ;;
            *) shift ;;
        esac
    done
    python3 -c "
import sys

date = '${DATE}'
original = sys.argv[1]
tone = sys.argv[2]

print('=' * 60)
print('回复邮件模板（{}语气）'.format('正式' if tone == 'formal' else '友好'))
print('=' * 60)
print('')
print('原文摘要：{}'.format(original))
print('')

if tone == 'formal':
    print('【中文版 — 正式】')
    print('')
    print('______，您好！')
    print('')
    print('感谢您的来信。就您提到的「{}」，'.format(original))
    print('回复如下：')
    print('')
    print('1. （针对对方的第一个问题/要点）')
    print('2. （针对对方的第二个问题/要点）')
    print('3. （你的建议/方案）')
    print('')
    print('如有其他问题，欢迎随时沟通。')
    print('')
    print('此致')
    print('敬礼')
    print('______')
else:
    print('【中文版 — 友好】')
    print('')
    print('Hi ______，')
    print('')
    print('收到，关于「{}」：'.format(original))
    print('')
    print('1. （回应要点一）')
    print('2. （回应要点二）')
    print('')
    print('有什么问题随时找我哈～')
    print('')
    print('Best,')
    print('______')

print('')
print('-' * 60)
print('')

if tone == 'formal':
    print('【English — Formal】')
    print('')
    print('Dear ______,')
    print('')
    print('Thank you for your email regarding \"{}\".'.format(original))
    print('Please find my response below:')
    print('')
    print('1. (Response to point 1)')
    print('2. (Response to point 2)')
    print('3. (Your suggestion/proposal)')
    print('')
    print('Please do not hesitate to reach out if you have')
    print('further questions.')
    print('')
    print('Best regards,')
    print('______')
else:
    print('【English — Friendly】')
    print('')
    print('Hi ______,')
    print('')
    print('Thanks for reaching out! Regarding \"{}\": '.format(original))
    print('')
    print('1. (Response to point 1)')
    print('2. (Response to point 2)')
    print('')
    print('Let me know if you have any other questions!')
    print('')
    print('Cheers,')
    print('______')

print('=' * 60)
" "$original" "$tone"
}

# Main dispatch
case "${1:-help}" in
    business)
        [ $# -lt 3 ] && { echo "用法: email.sh business \"收件人\" \"主题\""; exit 1; }
        cmd_business "$2" "$3"
        ;;
    followup)
        [ $# -lt 2 ] && { echo "用法: email.sh followup \"主题\""; exit 1; }
        cmd_followup "$2"
        ;;
    cold)
        [ $# -lt 3 ] && { echo "用法: email.sh cold \"公司\" \"目的\""; exit 1; }
        cmd_cold "$2" "$3"
        ;;
    apology)
        [ $# -lt 2 ] && { echo "用法: email.sh apology \"原因\""; exit 1; }
        cmd_apology "$2"
        ;;
    reply)
        [ $# -lt 2 ] && { echo "用法: email.sh reply \"原文摘要\" [--tone formal|friendly]"; exit 1; }
        original="$2"
        shift 2
        cmd_reply "$original" "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "未知命令: $1"
        show_help
        exit 1
        ;;
esac
