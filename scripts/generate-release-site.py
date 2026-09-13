#!/usr/bin/env python3
"""Render the reviewed release Markdown into standalone, bilingual static pages."""

from html import escape
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
RELEASE = ROOT / "release"
DESTINATION = RELEASE / "site"
EMAIL = "visionexperiencedeveloper@gmail.com"

STYLE = """
:root { color-scheme: light; --paper: #f8f6ef; --ink: #253d32; --muted: #526258; --line: #d7ded5; --accent: #2d6952; }
* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body { margin: 0; color: var(--ink); background: var(--paper); font-family: -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Segoe UI", sans-serif; font-size: 17px; line-height: 1.85; word-break: keep-all; overflow-wrap: anywhere; }
a { color: var(--accent); text-underline-offset: 4px; }
a:hover { text-decoration-thickness: 2px; }
a:focus-visible { outline: 3px solid var(--accent); outline-offset: 5px; border-radius: 3px; }
.skip { position: absolute; top: -100px; left: 16px; padding: 8px 14px; background: white; z-index: 2; }
.skip:focus { top: 12px; }
.shell { max-width: 820px; margin: 0 auto; padding: 0 30px; }
.site-header { display: flex; flex-wrap: wrap; gap: 18px 28px; align-items: center; justify-content: space-between; padding-top: 36px; padding-bottom: 26px; border-bottom: 1px solid var(--line); }
.brand { color: var(--ink); font-family: Georgia, serif; font-size: 32px; line-height: 1; letter-spacing: -1px; text-decoration: none; }
.language { display: flex; align-items: center; gap: 6px; font-size: 14px; }
.language a { padding: 6px 12px; border-radius: 999px; text-decoration: none; }
.language a[aria-current="page"] { color: var(--ink); background: #e7ebe2; font-weight: 600; }
.site-nav { display: flex; flex-wrap: wrap; gap: 12px 24px; padding-top: 20px; font-size: 14px; }
.site-nav a[aria-current="page"] { color: var(--ink); font-weight: 600; }
main { padding-top: 50px; padding-bottom: 50px; }
.eyebrow { margin: 0 0 14px; color: var(--accent); font-size: 12px; font-weight: 650; letter-spacing: 2px; }
h1 { margin: 0 0 26px; max-width: 720px; font-size: clamp(32px, 6vw, 46px); line-height: 1.28; letter-spacing: -1.5px; font-weight: 650; }
h2 { margin: 44px 0 12px; font-size: 22px; line-height: 1.5; letter-spacing: -.35px; font-weight: 650; }
p { margin: 0 0 18px; color: var(--muted); }
ul { margin: 0 0 20px; padding-left: 24px; color: var(--muted); }
li { padding-left: 4px; margin: 5px 0; }
footer { border-top: 1px solid var(--line); padding: 28px 0 42px; color: var(--muted); font-size: 14px; }
footer p { margin: 8px 0 0; }
.footer-links { display: flex; flex-wrap: wrap; gap: 8px 22px; }
@media (max-width: 480px) { body { font-size: 16px; } .shell { padding: 0 22px; } main { padding-top: 36px; } h2 { font-size: 20px; } .site-header { padding-top: 26px; } }
@media (prefers-reduced-motion: reduce) { html { scroll-behavior: auto; } }
@media print { body { background: white; font-size: 11pt; } .site-header, .site-nav, .skip, .eyebrow { display: none; } main { padding-top: 0; } h1 { font-size: 25pt; } h2 { font-size: 15pt; break-after: avoid; } p, li { orphans: 3; widows: 3; } a { color: inherit; } }
""".strip()


def inline(text: str) -> str:
    text = escape(text)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', text)
    return text.replace(EMAIL, f'<a href="mailto:{EMAIL}">{EMAIL}</a>')


def markdown(source: str) -> str:
    blocks = []
    for block in source.strip().split("\n\n"):
        lines = block.splitlines()
        if block.startswith("# "):
            blocks.append(f"<h1>{inline(block[2:])}</h1>")
        elif block.startswith("## "):
            blocks.append(f"<h2>{inline(block[3:])}</h2>")
        elif all(line.startswith("- ") for line in lines):
            blocks.append("<ul>\n" + "\n".join(f"<li>{inline(line[2:])}</li>" for line in lines) + "\n</ul>")
        else:
            content = ""
            for index, line in enumerate(lines):
                content += inline(line.rstrip())
                if index < len(lines) - 1:
                    content += "<br>\n" if line.endswith("  ") else "\n"
            blocks.append(f"<p>{content}</p>")
    return "\n".join(blocks)


def page(kind: str, language: str) -> str:
    korean = language == "ko"
    source = (RELEASE / f"{kind}.{language}.md").read_text()
    suffix = "" if korean else "-en"
    title = source.splitlines()[0][2:]
    support = f"support{suffix}.html"
    privacy = f"privacy{suffix}.html"
    support_label = "사용 안내" if korean else "Support"
    privacy_label = "개인정보 처리방침" if korean else "Privacy Policy"
    description = (
        "Praylist의 기기 내 저장, 알림, 언어 설정, 백업과 개인정보 처리 안내입니다."
        if korean and kind == "privacy" else
        "Praylist의 pray 작성, 기도 기록, 언어 선택, 알림 및 백업 사용 방법입니다."
        if korean else
        "How Praylist handles on-device records, reminders, language preferences, backups, and privacy."
        if kind == "privacy" else
        "Help with writing prays, prayer history, languages, reminders, and backups in Praylist."
    )
    current = ' aria-current="page"'
    return f'''<!doctype html>
<html lang="{language}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="{escape(description)}">
<meta name="theme-color" content="#f8f6ef">
<title>{escape(title)} · VXDeveloper</title>
<link rel="alternate" hreflang="ko" href="{kind}.html">
<link rel="alternate" hreflang="en" href="{kind}-en.html">
<style>{STYLE}</style>
</head>
<body>
<a class="skip" href="#content">{'본문으로 이동' if korean else 'Skip to content'}</a>
<div class="shell">
<header class="site-header">
<a class="brand" href="{support}" aria-label="Praylist {'사용 안내' if korean else 'support'}">praylist</a>
<nav class="language" aria-label="{'페이지 언어' if korean else 'Page language'}">
<a href="{kind}.html" lang="ko" hreflang="ko"{current if korean else ''}>한국어</a>
<a href="{kind}-en.html" lang="en" hreflang="en"{current if not korean else ''}>English</a>
</nav>
</header>
<nav class="site-nav" aria-label="{'안내 페이지' if korean else 'Information pages'}">
<a href="{support}"{current if kind == 'support' else ''}>{support_label}</a>
<a href="{privacy}"{current if kind == 'privacy' else ''}>{privacy_label}</a>
</nav>
<main id="content">
<p class="eyebrow">PRAYLIST · {kind.upper()}</p>
{markdown(source)}
</main>
<footer>
<div class="footer-links"><a href="{support}">{support_label}</a><a href="{privacy}">{privacy_label}</a></div>
<p><a href="mailto:{EMAIL}">{EMAIL}</a></p>
<p>© 2026 VXDeveloper</p>
</footer>
</div>
</body>
</html>
'''


if __name__ == "__main__":
    DESTINATION.mkdir(parents=True, exist_ok=True)
    for kind in ("privacy", "support"):
        for language in ("ko", "en"):
            filename = f"{kind}{'' if language == 'ko' else '-en'}.html"
            path = DESTINATION / filename
            path.write_text(page(kind, language))
            print(path.relative_to(ROOT))
