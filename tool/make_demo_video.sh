#!/usr/bin/env bash
#
# Encodes the whiteboard frames captured by
# test/features/visual_tutor/demo_video_frames_test.dart into MP4 clips for the
# closing-project deck.
#
#   flutter test test/features/visual_tutor/demo_video_frames_test.dart
#   tool/make_demo_video.sh
#
# Output: build/demo_video/<name>.mp4 and build/demo_video/rean-ai-demo.mp4
#
# Why the tail is trimmed: once the last action is written, the board advances to
# a fresh empty page and sits there. Encoding the capture as-is ends the clip on
# a blank board. An empty board compresses to roughly a third of what a board
# carrying a worked step does, so the last frame worth keeping is found by size
# against the first frame, which is empty by definition.
set -euo pipefail

cd "$(dirname "$0")/.."
root="build/demo_video"
fps=25
hold_seconds=2.5

if [ ! -d "$root" ]; then
  echo "No frames in $root — run the capture test first:" >&2
  echo "  flutter test test/features/visual_tutor/demo_video_frames_test.dart" >&2
  exit 1
fi

command -v ffmpeg >/dev/null || { echo "ffmpeg is not installed" >&2; exit 1; }

clips=()

for dir in "$root"/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  count=$(find "$dir" -name 'f_*.png' | wc -l | tr -d ' ')
  [ "$count" -gt 0 ] || { echo "skip $name: no frames"; continue; }

  # Last frame that still carries board content.
  last=$(python3 - "$dir" <<'PY'
import os, sys
d = sys.argv[1]
frames = sorted(f for f in os.listdir(d) if f.startswith('f_') and f.endswith('.png'))
sizes = [os.path.getsize(os.path.join(d, f)) for f in frames]
baseline = sizes[0]                      # frame 0 is an empty board
threshold = baseline * 1.3
keep = [i for i, s in enumerate(sizes) if s > threshold]
# Fall back to the whole capture rather than emit nothing.
print(keep[-1] if keep else len(frames) - 1)
PY
)
  kept=$((last + 1))
  echo "$name: $count frames captured, keeping $kept (trimmed $((count - kept)) empty)"

  # ffmpeg needs a gap-free sequence, so the kept frames are hardlinked into a
  # scratch directory rather than the originals being renamed or deleted.
  seq_dir="$dir/.seq"
  rm -rf "$seq_dir"; mkdir -p "$seq_dir"
  i=0
  while [ "$i" -le "$last" ]; do
    ln -f "$(printf '%s/f_%04d.png' "$dir" "$i")" "$(printf '%s/s_%04d.png' "$seq_dir" "$i")"
    i=$((i + 1))
  done

  out="$root/$name.mp4"
  ffmpeg -y -loglevel error \
    -framerate "$fps" -start_number 0 -i "$seq_dir/s_%04d.png" \
    -vf "tpad=stop_mode=clone:stop_duration=$hold_seconds,format=yuv420p" \
    -c:v libx264 -crf 18 -preset slow -movflags +faststart \
    "$out"
  rm -rf "$seq_dir"
  clips+=("$out")
  echo "  -> $out"
done

# One clip for the slide: the English board, then the same solution in Khmer.
if [ "${#clips[@]}" -gt 1 ]; then
  list="$root/.concat.txt"
  : > "$list"
  for c in "${clips[@]}"; do
    echo "file '$(basename "$c")'" >> "$list"
  done
  ffmpeg -y -loglevel error -f concat -safe 0 -i "$list" -c copy "$root/rean-ai-demo.mp4"
  rm -f "$list"
  echo "combined -> $root/rean-ai-demo.mp4"
fi

echo
for f in "$root"/*.mp4; do
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" 2>/dev/null || echo '?')
  size=$(du -h "$f" | cut -f1)
  printf '%-44s %6ss  %s\n' "$f" "${dur%.*}" "$size"
done
