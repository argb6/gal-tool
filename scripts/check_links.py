import re, sys, time, json, os
from concurrent.futures import ThreadPoolExecutor, as_completed
import httpx

DIRS = ["simulators/README.md", "websites/README.md", "tools/README.md"]
GITHUB_BASE = "https://github.com/argb6/gal-tool/blob/main"
TIMEOUT = 15
MAX_WORKERS = 10

def extract_links(filepath):
    links = []
    try:
        with open(filepath, encoding="utf-8") as f:
            for lineno, line in enumerate(f, 1):
                m = re.match(r'^\s*-\s*\[(.+?)\]\((.+?)\)\s*(.*)', line)
                if not m:
                    continue
                name, url, desc = m[1], m[2], m[3].strip().lstrip("-–— ")
                if url.startswith("./") or url.startswith("../"):
                    url = GITHUB_BASE + "/" + filepath.rsplit("/", 1)[0] + "/" + url.lstrip("./")
                elif not url.startswith("http"):
                    url = GITHUB_BASE + "/" + filepath.rsplit("/", 1)[0] + "/" + url
                cat = filepath.split("/")[0]
                links.append({"name": name, "url": url, "cat": cat, "desc": desc, "file": filepath, "line": lineno})
    except Exception as e:
        print(f"读取 {filepath} 失败: {e}", file=sys.stderr)
    return links

def check_url(entry):
    url = entry["url"]
    try:
        with httpx.Client(timeout=TIMEOUT, follow_redirects=True) as client:
            resp = client.head(url, headers={"User-Agent": "LinkChecker/1.0"})
            code = resp.status_code
    except Exception:
        code = -1
    return entry, code

def main():
    all_links = []
    for d in DIRS:
        all_links.extend(extract_links(d))

    total = len(all_links)
    print(f"共发现 {total} 个链接，开始检查...")

    ok, dead, error = [], [], []
    url_status = {}
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
        futures = {pool.submit(check_url, e): e for e in all_links}
        for i, f in enumerate(as_completed(futures), 1):
            e, s = f.result()
            url_status[e["url"]] = s
            if 200 <= s < 400:
                ok.append(e)
            elif s >= 400:
                dead.append(e)
            else:
                error.append(e)
            print(f"[{i}/{total}] {e['name']} -> {s}")

    print(f"\n{'='*60}")
    print(f"正常 {len(ok)} | 失效 {len(dead)} | 异常 {len(error)}")

    report = {
        "checked_at": time.strftime("%Y-%m-%d %H:%M UTC"),
        "total": total,
        "alive": len(ok),
        "dead": len(dead),
        "error": len(error),
        "status": url_status
    }
    os.makedirs("docs", exist_ok=True)
    with open("docs/link-status.json", "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False)

    # 有失效链接时生成 Issue 文件，但不退出
    if dead or error:
        dead_names = ", ".join([e["name"] for e in dead + error])
        body = f"## 以下链接已失效\n\n**检查时间**：{report['checked_at']}\n\n"
        if dead:
            body += "### ❌ HTTP 失效\n\n"
            for e in dead:
                body += f"- [{e['cat']}] [{e['name']}]({e['url']}) — HTTP {e['status']}\n"
            body += "\n"
        if error:
            body += "### ⚠️ 无法连接\n\n"
            for e in error:
                body += f"- [{e['cat']}] [{e['name']}]({e['url']}) — 连接失败\n"
        with open("issue_body.txt", "w", encoding="utf-8") as f:
            f.write(body)
        with open("dead_names.txt", "w", encoding="utf-8") as f:
            f.write(dead_names)

        # 写入环境变量文件供 workflow 使用
        with open(os.environ.get("GITHUB_ENV", "/dev/null"), "a") as f:
            f.write("HAS_DEAD=true\n")

        for e in dead:
            print(f"  ❌ [{e['cat']}] {e['name']} | HTTP {e['status']} | {e['url']}")
        for e in error:
            print(f"  ⚠️ [{e['cat']}] {e['name']} | 无法连接 | {e['url']}")
    else:
        print("所有链接正常")

if __name__ == "__main__":
    main()
