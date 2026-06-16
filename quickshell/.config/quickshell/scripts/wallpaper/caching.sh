#!/usr/bin/env bash
QS_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell"
QS_RUN_DIR="/tmp/quickshell"
QS_LOG_DIR="${QS_LOG_DIR:-$QS_RUN_DIR/logs}"

QS_CACHE_WALLPAPER_PICKER="$QS_CACHE_DIR/wallpaper_picker"
QS_RUN_WALLPAPER_PICKER="$QS_RUN_DIR/wallpaper_picker"

export QS_CACHE_WALLPAPER_PICKER
export QS_RUN_WALLPAPER_PICKER
export QS_LOG_DIR

mkdir -p "$QS_CACHE_WALLPAPER_PICKER/thumbs"
mkdir -p "$QS_CACHE_WALLPAPER_PICKER/colors_markers"
mkdir -p "$QS_RUN_WALLPAPER_PICKER"
mkdir -p "$QS_LOG_DIR"
