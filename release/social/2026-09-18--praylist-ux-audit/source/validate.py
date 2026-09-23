from __future__ import annotations

import hashlib
import json
from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
FEED = ROOT / "feed"
VALIDATION = ROOT / "validation"


def srgb(v: int) -> float:
    c = v / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def luminance(hex_color: str) -> float:
    h = hex_color.lstrip("#")
    r, g, b = [int(h[i:i + 2], 16) for i in (0, 2, 4)]
    return 0.2126 * srgb(r) + 0.7152 * srgb(g) + 0.0722 * srgb(b)


def contrast(a: str, b: str) -> float:
    l1, l2 = sorted([luminance(a), luminance(b)], reverse=True)
    return (l1 + 0.05) / (l2 + 0.05)


def main():
    files = sorted(FEED.glob("*.png"))
    items = []
    errors = []
    for index, path in enumerate(files, 1):
        with Image.open(path) as im:
            width, height = im.size
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        item = {"file": path.name, "width": width, "height": height, "sha256": digest}
        items.append(item)
        if (width, height) != (1080, 1350):
            errors.append(f"{path.name}: expected 1080x1350, got {width}x{height}")
        if not path.name.startswith(f"{index:02d}-"):
            errors.append(f"{path.name}: unexpected sequence at position {index}")

    if len(files) != 10:
        errors.append(f"expected 10 slides, got {len(files)}")

    caption = (ROOT / "caption.ko.md").read_text(encoding="utf-8").strip()
    alt = (ROOT / "alt-text.ko.md").read_text(encoding="utf-8")
    alt_entries = [line for line in alt.splitlines() if line[:2].rstrip(".").isdigit() and ". " in line]
    if len(caption) > 2200:
        errors.append(f"caption exceeds 2200 characters: {len(caption)}")
    if len(alt_entries) != 10:
        errors.append(f"expected 10 alt-text entries, got {len(alt_entries)}")

    ratios = {
        "ink_on_paper": contrast("#253D32", "#F8F6EF"),
        "forest_on_paper": contrast("#426B55", "#F8F6EF"),
        "white_on_forest": contrast("#FFFFFF", "#426B55"),
        "white_on_red": contrast("#FFFFFF", "#B84C3F"),
    }
    for name, ratio in ratios.items():
        if ratio < 4.5:
            errors.append(f"{name}: contrast {ratio:.2f}:1 below 4.5:1")

    report = {
        "status": "PASS" if not errors else "FAIL",
        "slideCount": len(files),
        "expectedDimensions": [1080, 1350],
        "captionCharacters": len(caption),
        "altTextEntries": len(alt_entries),
        "contrastRatios": {k: round(v, 2) for k, v in ratios.items()},
        "slides": items,
        "errors": errors,
        "reviewState": "AWAITING_USER_REVIEW",
        "publicationState": "NOT_PUBLISHED",
    }
    VALIDATION.mkdir(parents=True, exist_ok=True)
    (VALIDATION / "validation-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# Validation report",
        "",
        f"- Status: **{report['status']}**",
        f"- Slides: {len(files)}/10",
        "- Dimensions: 1080×1350 PNG",
        f"- Caption: {len(caption)} characters",
        f"- Alt text entries: {len(alt_entries)}/10",
        f"- Contrast: ink/paper {ratios['ink_on_paper']:.2f}:1, forest/paper {ratios['forest_on_paper']:.2f}:1, white/forest {ratios['white_on_forest']:.2f}:1, white/red {ratios['white_on_red']:.2f}:1",
        "- Review: AWAITING_USER_REVIEW",
        "- Publication: NOT_PUBLISHED",
    ]
    if errors:
        lines += ["", "## Errors", ""] + [f"- {e}" for e in errors]
    (VALIDATION / "validation-report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    (VALIDATION / "checksums.sha256").write_text("".join(f"{item['sha256']}  ../feed/{item['file']}\n" for item in items), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    raise SystemExit(1 if errors else 0)


if __name__ == "__main__":
    main()
