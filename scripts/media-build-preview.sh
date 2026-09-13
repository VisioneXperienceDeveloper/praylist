#!/bin/zsh
set -euo pipefail

# Encode an actual Simulator recording for App Store Connect.
# Usage: scripts/media-build-preview.sh ko|en input.mp4 startSeconds durationSeconds
# Cuts only the beginning/end of the real screen recording; no synthesized UI.
if [[ $# -ne 4 || ( "$1" != "ko" && "$1" != "en" ) ]]; then
  print -u2 'Usage: scripts/media-build-preview.sh ko|en input.mp4 startSeconds durationSeconds'
  exit 2
fi
media_language="$1"
media_input="$2"
media_start="$3"
media_duration="$4"
media_root="${0:A:h:h}"
media_output_dir="$media_root/release/video"
mkdir -p "$media_output_dir"
media_output="$media_output_dir/Praylist-App-Preview-$media_language.mp4"

ffmpeg -hide_banner -loglevel warning -y \
  -ss "$media_start" -i "$media_input" \
  -f lavfi -i 'anullsrc=channel_layout=stereo:sample_rate=48000' \
  -t "$media_duration" -map 0:v:0 -map 1:a:0 \
  -vf 'scale=886:1920:force_original_aspect_ratio=decrease:force_divisible_by=2,pad=886:1920:(ow-iw)/2:(oh-ih)/2:color=0xf7f4eb,fps=30,setsar=1' \
  -c:v libx264 -profile:v high -level:v 4.0 -preset slow \
  -b:v 11M -minrate 11M -maxrate 11M -bufsize 22M -x264-params 'nal-hrd=cbr:filler=1' \
  -pix_fmt yuv420p -color_primaries bt709 -color_trc bt709 -colorspace bt709 \
  -c:a aac -b:a 256k -ar 48000 -ac 2 -shortest -movflags +faststart \
  -metadata title="Praylist — App Preview ($media_language)" \
  -metadata comment='Actual iOS Simulator screen recording. Deliberately silent.' \
  "$media_output"

# The App Store default poster time is 5 seconds. Also provide it as an inspectable file.
ffmpeg -hide_banner -loglevel warning -y -ss 5 -i "$media_output" \
  -frames:v 1 -update 1 "$media_output_dir/Praylist-App-Preview-$media_language-poster.png"
ffmpeg -hide_banner -loglevel warning -y -i "$media_output" \
  -vf 'fps=1/4,scale=222:480,tile=4x2:padding=10:margin=10:color=0xf7f4eb' \
  -frames:v 1 -update 1 "$media_output_dir/Praylist-App-Preview-$media_language-contact-sheet.png"
ffprobe -v error -show_format -show_streams -of json "$media_output" \
  > "$media_output_dir/Praylist-App-Preview-$media_language-metadata.json"
print "$media_output"
