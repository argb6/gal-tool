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
            elif s == -1:
                error.append(r)
            print(f"[{i}/{total}] {r['name']} -> {s}")

    print(f"\n{'='*60}")
    print(f"正常 {len(ok)} | 失效 {len(dead)} | 错误 {len(error)}")

    if dead:
        print(f"\n--- 失效链接 ({len(dead)} 个) ---")
        for r in dead:
            print(f"  [{r['cat']}] {r['name']} | HTTP {r['status']} | {r['url']}")

    # 精简 JSON：只存 url -> status，方便前端读取
    report = {
        "checked_at": time.strftime("%Y-%m-%d %H:%M UTC"),
        "total": total,
        "alive": len(ok),
        "dead": len(dead),
        "error": len(error),
        "status": url_status
    }

    import os
    os.makedirs("docs", exist_ok=True)
    with open("docs/link-status.json", "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False)

    if dead:
        sys.exit(1)

if __name__ == "__main__":
    main()
