#!/usr/bin/env python3
"""Copy named original XCT attachments without changing their pixels.

Usage: python3 scripts/media-extract-captures.py ko|en build/media/attachments-LANG
First export with: xcrun xcresulttool export attachments --path RESULT --output-path ATTACHMENTS
"""
from pathlib import Path
import json
import shutil
import sys

ROOT = Path(__file__).resolve().parent.parent
language, export = sys.argv[1], Path(sys.argv[2]).resolve()
assert language in ("ko", "en")
expected = {"01-notebook", "02-travel", "03-prayer", "04-achievements", "05-reminder", "06-onboarding", "07-prayer-calendar", "08-new-category"}
destination = ROOT / "release" / "screenshots" / language
destination.mkdir(parents=True, exist_ok=True)
copied = set()
for group in json.loads((export / "manifest.json").read_text()):
    for item in group.get("attachments", []):
        name = item.get("suggestedHumanReadableName", "").split("_0_")[0]
        if name in expected and item["exportedFileName"].endswith(".png"):
            assert name not in copied, f"Duplicate screenshot: {name}"
            source = export / item["exportedFileName"]
            shutil.copyfile(source, destination / f"{name}.png")
            copied.add(name)
assert copied == expected, f"Missing captures: {expected - copied}"
print(f"Copied {len(copied)} unmodified {language} screenshots into {destination}")
