import smtplib
import json
import os
import sys
from email.mime.text import MIMEText
from email.utils import formataddr

user = os.environ["EMAIL_USER"]
password = os.environ["EMAIL_PASS"]

# 根据邮箱域名自动选择 SMTP
domain = user.rsplit("@", 1)[-1].lower()
smtp_map = {
    "qq.com":      ("smtp.qq.com", 587),
    "163.com":     ("smtp.163.com", 465),
    "126.com":     ("smtp.126.com", 465),
    "gmail.com":   ("smtp.gmail.com", 587),
    "outlook.com": ("smtp-mail.outlook.com", 587),
    "hotmail.com": ("smtp-mail.outlook.com", 587),
    "live.com":    ("smtp-mail.outlook.com", 587),
    "foxmail.com": ("smtp.qq.com", 587),
    "yeah.net":    ("smtp.yeah.net", 465),
    "sina.com":    ("smtp.sina.com", 465),
}
smtp_server, smtp_port = smtp_map.get(domain, (None, None))
if not smtp_server:
    print(f"不支持的邮箱域名: {domain}", file=sys.stderr)
    print("支持: QQ/163/126/Gmail/Outlook/Foxmail 等", file=sys.stderr)
    sys.exit(1)

has_dead = os.environ.get("HAS_DEAD", "false") == "true"

# 读取报告
try:
    with open("docs/link-status.json", encoding="utf-8") as f:
        r = json.load(f)
    total, alive, dead, error = r["total"], r["alive"], r["dead"], r["error"]
except Exception:
    total = alive = dead = error = "?"

subject = "[链接检查] {} - {} 个链接".format(
    "✅ 全部正常" if not has_dead else "⚠️ 发现死链",
    total
)

html = (
    "<h2>每日链接检查报告</h2>"
    "<table border='1' cellpadding='8' cellspacing='0' style='border-collapse:collapse'>"
    "<tr><td>总计</td><td>{}</td></tr>"
    "<tr><td>正常</td><td style='color:green'>{}</td></tr>"
    "<tr><td>失效</td><td style='color:red'>{}</td></tr>"
    "<tr><td>异常</td><td style='color:orange'>{}</td></tr>"
    "</table>"
    "<p><a href='https://github.com/argb6/gal-navigation/actions'>查看运行记录</a></p>"
).format(total, alive, dead, error)

msg = MIMEText(html, "html", "utf-8")
msg["Subject"] = subject
msg["From"] = formataddr(["链接检查机器人", user])
msg["To"] = user

if smtp_port == 465:
    server = smtplib.SMTP_SSL(smtp_server, smtp_port, timeout=15)
else:
    server = smtplib.SMTP(smtp_server, smtp_port, timeout=15)
    server.starttls()
server.login(user, password)
server.sendmail(user, user, msg.as_string())
server.quit()
print("邮件已发送")