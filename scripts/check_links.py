import re, sys, time, json
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
                links.append({"name": name, "url": url, "cat": cat, "desc": desc, "src": filepath})
    except Exception as e:
        print(f"读取 {filepath} 失败: {e}", file=sys.stderr)
    return links

def check_url(entry):
    url = entry["url"]
    try:
        with httpx.Client(timeout=TIMEOUT, follow_redirects=True) as client:
            resp = client.head(url, headers={"User-Agent": "LinkChecker/1.0"})
            code = resp.status_code
    except Exception as e:
        code = str(e)[:60]
    return {"name": entry["name"], "url": url, "cat": entry["cat"], "desc": entry["desc"], "status": code}

def main():
    all_links = []
    for d in DIRS:
        all_links.extend(extract_links(d))

    total = len(all_links)
    print(f"共发现 {total} 个链接，开始检查...")

    ok, dead, error = [], [], []
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
        futures = {pool.submit(check_url, e): e for e in all_links}
        for i, f in enumerate(as_completed(futures), 1):
            r = f.result()
            s = r["status"]
            if s == 200:
                ok.append(r)
            elif isinstance(s, int) and 300 <= s < 400:
                ok.append(r)  # 重定向也算可用
            elif isinstance(s, int) and s >= 400:
                dead.append(r)
            else:
                error.append(r)
            print(f"[{i}/{total}] {r['name']} -> {s}")

    print(f"\n{'='*60}")
    print(f"结果汇总: 正常 {len(ok)} | 失效 {len(dead)} | 错误 {len(error)}")

    if dead:
        print(f"\n--- 失效链接 ({len(dead)} 个) ---")
        for r in dead:
            print(f"  [{r['cat']}] {r['name']} | {r['status']} | {r['url']}")

    if error:
        print(f"\n--- 检查异常 ({len(error)} 个) ---")
        for r in error:
            print(f"  [{r['cat']}] {r['name']} | {r['status']} | {r['url']}")

    # 写入 JSON 报告
    report = {
        "checked_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "total": total,
        "ok": len(ok),
        "dead": len(dead),
        "error": len(error),
        "dead_links": [{"name": r["name"], "url": r["url"], "category": r["cat"], "status": r["status"]} for r in dead],
        "error_links": [{"name": r["name"], "url": r["url"], "category": r["cat"], "error": r["status"]} for r in error],
    }
    with open("link-check-report.json", "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    if dead:
        sys.exit(1)  # 有失效链接时标记失败，方便在 Actions 中看到红色警告

if __name__ == "__main__":
    main()
