#!/bin/bash
OUT=/tmp/lock_blur.png
FALLBACK="/home/mert/Resimler/Wallpapers/dark_skulls.png"
AWWW_CACHE="$HOME/.cache/awww"

WALL=""
if [[ -d "$AWWW_CACHE" ]]; then
  VER_DIR=$(ls -t "$AWWW_CACHE" 2>/dev/null | head -1)
  if [[ -n "$VER_DIR" ]]; then
    for f in "$AWWW_CACHE/$VER_DIR"/*; do
      [[ -f "$f" ]] || continue
      candidate=$(tr '\0' '\n' < "$f" | tail -1)
      [[ -n "$candidate" && -f "$candidate" ]] && { WALL="$candidate"; break; }
    done
  fi
fi
if [[ -z "$WALL" || ! -f "$WALL" ]]; then
  WALL="$FALLBACK"
fi

if [[ -f "$WALL" ]]; then
  if command -v convert &>/dev/null; then
    convert "$WALL" -resize 1280x720 -blur 0x6 "$OUT" 2>/dev/null &
  elif command -v magick &>/dev/null; then
    magick "$WALL" -resize 1280x720 -blur 0x6 "$OUT" 2>/dev/null &
  elif command -v ffmpeg &>/dev/null; then
    ffmpeg -i "$WALL" -vf "scale=1280:720,gblur=sigma=6" -q:v 1 -y "$OUT" 2>/dev/null &
  fi
fi

exec quickshell -p /home/mert/.config/quickshell/lockscreen/shell.qml
