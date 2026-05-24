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
            for line in f:
                m = re.match(r'^\s*-\s*\[(.+?)\]\((.+?)\)\s*(.*)', line)
                if not m:
                    continue
                name, url, desc = m[1], m[2], m[3].strip().lstrip("-–— ")
                if url.startswith("./") or url.startswith("../"):
                    url = GITHUB_BASE + "/" + filepath.rsplit("/", 1)[0] + "/" + url.lstrip("./")
                elif not url.startswith("http"):
                    url = GITHUB_BASE + "/" + filepath.rsplit("/", 1)[0] + "/" + url
                cat = filepath.split("/")[0]
                links.append({"name": name, "url": url, "cat": cat, "desc": desc})
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
    return {"name": entry["name"], "url": url, "cat": entry["cat"], "desc": entry["desc"], "status": code}

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
            r = f.result()
            s = r["status"]
            url_status[r["url"]] = s
            if 200 <= s < 400:
                ok.append(r)
            elif s >= 400:
                dead.append(r)
            else:
                error.append(r)
            print(f"[{i}/{total}] {r['name']} -> {s}")

    print(f"\n{'='*60}")
    print(f"正常 {len(ok)} | 失效 {len(dead)} | 异常 {len(error)}")

    if dead or error:
        for r in dead:
            print(f"  ❌ [{r['cat']}] {r['name']} | HTTP {r['status']} | {r['url']}")
        for r in error:
            print(f"  ⚠️ [{r['cat']}] {r['name']} | 无法连接 | {r['url']}")

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

    if dead or error:
        body = f"## 链接检查报告\n\n**检查时间**：{report['checked_at']}\n\n**总计** {total} 个链接，{len(ok)} 正常\n\n"
        if dead:
            body += f"### ❌ 失效链接（{len(dead)} 个）\n\n"
            for r in dead:
                body += f"- [{r['cat']}] [{r['name']}]({r['url']}) — HTTP {r['status']}\n"
            body += "\n"
        if error:
            body += f"### ⚠️ 无法连接（{len(error)} 个）\n\n"
            for r in error:
                body += f"- [{r['cat']}] [{r['name']}]({r['url']}) — 连接失败\n"
        with open("issue_body.txt", "w", encoding="utf-8") as f:
            f.write(body)
        sys.exit(1)

if __name__ == "__main__":
    main()
