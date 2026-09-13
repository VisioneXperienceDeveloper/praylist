#!/usr/bin/env python3
"""Make a 15–30 second preview from selected sections of a real screen recording.

Usage: python3 scripts/media-compose-preview.py release/video/edit-ko.json
Each segment retains its original playback speed. Only idle portions are omitted.
"""
from pathlib import Path
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
plan_path = Path(sys.argv[1]).resolve()
plan = json.loads(plan_path.read_text())
language = plan["language"]
assert language in ("ko", "en")
source = ROOT / plan["source"]
segments = plan["segments"]
duration = sum(segment["duration"] for segment in segments)
assert 15 <= duration <= 30
assert segments and all(segment["start"] >= 0 and segment["duration"] > 0 for segment in segments)
output_dir = ROOT / "release" / "video"
output_dir.mkdir(parents=True, exist_ok=True)
output = output_dir / f"Praylist-App-Preview-{language}.mp4"

split = "".join(f"[s{index}]" for index in range(len(segments)))
filters = [f"[0:v]split={len(segments)}{split}"]
for index, segment in enumerate(segments):
    filters.append(f"[s{index}]trim=start={segment['start']}:duration={segment['duration']},setpts=PTS-STARTPTS[v{index}]")
sources = "".join(f"[v{index}]" for index in range(len(segments)))
filters.append(sources + f"concat=n={len(segments)}:v=1:a=0,scale=886:1920:force_original_aspect_ratio=decrease:force_divisible_by=2,pad=886:1920:(ow-iw)/2:(oh-ih)/2:color=0xf7f4eb,fps=30,setsar=1[outv]")

subprocess.run([
    "ffmpeg", "-hide_banner", "-loglevel", "warning", "-y", "-i", str(source),
    "-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=48000",
    "-filter_complex", ";".join(filters), "-map", "[outv]", "-map", "1:a:0", "-t", str(duration),
    "-c:v", "libx264", "-profile:v", "high", "-level:v", "4.0", "-preset", "slow",
    "-b:v", "11M", "-minrate", "11M", "-maxrate", "11M", "-bufsize", "22M",
    "-x264-params", "nal-hrd=cbr:filler=1", "-pix_fmt", "yuv420p",
    "-color_primaries", "bt709", "-color_trc", "bt709", "-colorspace", "bt709",
    "-c:a", "aac", "-b:a", "256k", "-ar", "48000", "-ac", "2", "-shortest", "-movflags", "+faststart",
    "-metadata", f"title=Praylist — App Preview ({language})",
    "-metadata", "comment=Actual iOS Simulator recording; original playback speed; deliberate silence.",
    str(output),
], check=True)
subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "warning", "-y", "-ss", "5", "-i", str(output),
                "-frames:v", "1", "-update", "1", str(output_dir / f"Praylist-App-Preview-{language}-poster.png")], check=True)
subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "warning", "-y", "-i", str(output),
                "-vf", "fps=1/4,scale=222:480,tile=4x2:padding=10:margin=10:color=0xf7f4eb", "-frames:v", "1", "-update", "1",
                str(output_dir / f"Praylist-App-Preview-{language}-contact-sheet.png")], check=True)
metadata = subprocess.check_output(["ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json", str(output)])
(output_dir / f"Praylist-App-Preview-{language}-metadata.json").write_bytes(metadata)
print(output)
