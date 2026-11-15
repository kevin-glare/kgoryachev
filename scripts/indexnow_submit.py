#!/usr/bin/env python3
"""IndexNow: отправка изменившихся URL в Bing/Yandex/Seznam после деплоя.

Аргументы: key, host, since (unix-время водяного знака прошлой отправки).
Выбирает из public/sitemap.xml URL с lastmod новее водяного знака и отправляет
одним POST на api.indexnow.org. При успехе (200/202) пишет новый водяной знак
в indexnow-watermark рядом со скриптом (cwd), иначе ничего не делает.
"""
import json
import os
import re
import sys
import urllib.request
from datetime import datetime

key, host, since = sys.argv[1], sys.argv[2], float(sys.argv[3])

with open("public/sitemap.xml", encoding="utf-8") as f:
    sitemap = f.read()

pairs = re.findall(
    r"<url>\s*<loc>([^<]+)</loc>\s*<lastmod>([^<]+)</lastmod>",
    sitemap,
)
changed, newest = [], since
for loc, lastmod in pairs:
    try:
        ts = datetime.fromisoformat(lastmod).timestamp()
    except ValueError:
        print(f"IndexNow: skip unparsable lastmod {lastmod!r}")
        continue
    newest = max(newest, ts)
    if ts > since:
        changed.append(loc)

if not changed:
    print("IndexNow: no changed URLs, nothing to submit")
    sys.exit(0)

payload = json.dumps({
    "host": host,
    "key": key,
    "keyLocation": f"https://{host}/{key}.txt",
    "urlList": changed[:10000],
}).encode()

req = urllib.request.Request(
    "https://api.indexnow.org/indexnow",
    data=payload,
    headers={"Content-Type": "application/json; charset=utf-8"},
)
try:
    with urllib.request.urlopen(req, timeout=30) as r:
        print(f"IndexNow: submitted {len(changed)} URLs, HTTP {r.status}")
        if r.status in (200, 202):
            with open("indexnow-watermark", "w") as f:
                f.write(str(int(newest)))
except Exception as e:  # noqa: BLE001 — пинг поисковиков не должен ронять деплой
    print(f"IndexNow: submission failed: {e}")
