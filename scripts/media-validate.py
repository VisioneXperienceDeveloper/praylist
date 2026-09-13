#!/usr/bin/env python3
"""Validate finished App Store media without changing any image or video."""
from datetime import datetime, timezone
from hashlib import sha256
from pathlib import Path
import json
import struct
import subprocess

ROOT = Path(__file__).resolve().parent.parent
RELEASE = ROOT / "release"
entries = []
text_audit = json.loads((RELEASE / "media-text-audit.json").read_text())
assert text_audit["status"] == "passed"
audited_images = {entry["file"]: entry for entry in text_audit["files"]}


def base(path):
    content = path.read_bytes()
    return {"file": str(path.relative_to(ROOT)), "bytes": len(content), "sha256": sha256(content).hexdigest()}


for language in ("ko", "en"):
    captures = sorted((RELEASE / "screenshots" / language).glob("*.png"))
    assert len(captures) == 8, f"Expected eight {language} raw screenshots"
    for path in captures:
        header = path.read_bytes()[:33]
        assert header[:8] == b"\x89PNG\r\n\x1a\n", path
        width, height, depth, color, _, _, _ = struct.unpack(">IIBBBBB", header[16:29])
        assert (width, height, depth, color) == (1320, 2868, 8, 2), path
        entries.append({**base(path), "kind": "raw-simulator-screenshot", "language": language,
                        "width": width, "height": height, "opaque": True,
                        "captureResult": f"build/MediaScreenshots{language.upper()}Final.xcresult"})
    images = sorted((RELEASE / "store-images" / language).glob("*.png"))
    assert len(images) == 8, f"Expected eight {language} store screenshots, got {len(images)}"
    for path in images:
        audited = audited_images[str(path.relative_to(ROOT))]
        assert audited["sha256"] == base(path)["sha256"] and not audited["flaggedText"], f"Stale or failed text audit: {path}"
        header = path.read_bytes()[:33]
        assert header[:8] == b"\x89PNG\r\n\x1a\n", path
        width, height, depth, color, _, _, _ = struct.unpack(">IIBBBBB", header[16:29])
        assert (width, height) == (1320, 2868), f"Incorrect screenshot size: {path}"
        assert depth == 8 and color == 2, f"Expected opaque 8-bit RGB PNG: {path}"
        entries.append({**base(path), "kind": "app-store-screenshot", "language": language,
                        "width": width, "height": height, "opaque": True})

    path = RELEASE / "video" / f"Praylist-App-Preview-{language}.mp4"
    report = json.loads(subprocess.check_output([
        "ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json", str(path)
    ]))
    video = next(stream for stream in report["streams"] if stream["codec_type"] == "video")
    audio = next(stream for stream in report["streams"] if stream["codec_type"] == "audio")
    duration = float(report["format"]["duration"])
    assert 15 <= duration <= 30, f"Video duration must be 15–30 seconds: {path}"
    assert path.stat().st_size < 500_000_000, f"Video larger than 500 MB: {path}"
    assert (video["width"], video["height"]) == (886, 1920), path
    assert video["codec_name"] == "h264" and video["profile"] == "High" and video["level"] == 40, path
    assert video["pix_fmt"] == "yuv420p" and video["r_frame_rate"] == "30/1", path
    assert audio["codec_name"] == "aac" and audio["sample_rate"] == "48000" and audio["channels"] == 2, path
    assert 10_000_000 <= int(video["bit_rate"]) <= 12_000_000, f"Video bit rate outside Apple target: {path}"
    entries.append({**base(path), "kind": "app-preview", "language": language,
                    "durationSeconds": duration, "width": video["width"], "height": video["height"],
                    "frameRate": video["r_frame_rate"], "videoCodec": video["codec_name"],
                    "profile": video["profile"], "level": video["level"], "videoBitRate": int(video["bit_rate"]),
                    "audioCodec": audio["codec_name"], "audioChannels": audio["channels"],
                    "audioSampleRate": int(audio["sample_rate"]), "audioIntent": "deliberately silent"})

manifest = {
    "app": "Praylist", "verifiedAt": datetime.now(timezone.utc).isoformat(),
    "languages": ["ko", "en"], "rawScreenshotCount": 16, "storeScreenshotCount": 16, "appPreviewCount": 2,
    "source": "Actual iPhone 17 Pro Max Simulator app captures using isolated sample data; no synthesized UI.",
    "specifications": [
        "https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications",
        "https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications"
    ],
    "checks": {"pngDimensionsAndOpacity": "passed", "videoEncodingAndDuration": "passed", "displayedTerminologyOCR": "passed", "fileHashes": "sha256"},
    "files": entries,
}
output = RELEASE / "media-manifest.json"
output.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
print(f"PASS: {len(entries)} media files verified (16 raw screenshots, 16 store screenshots, 2 previews). {output}")
