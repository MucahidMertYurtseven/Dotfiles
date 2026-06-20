#!/usr/bin/env python3
"""
"Sıcak grayscale" tema üretici.

Wallpaper'ın koyu bir renginden hue alır, tüm paleti bu hue'da ÇOK
düşük saturation ile üretir. Lightness değerleri orijinal grayscale
temadan alınmıştır — sonuç: gri gibi görünür ama wallpaper'ın
sıcaklığı hissedilir, ne pastel ne neon.

Lightness tablosu (orijinal grayscale):
  bgDark      L=0.126   bgPopup      L=0.165
  border      L=0.196   empty        L=0.255
  hover       L=0.376   textMuted    L=0.50
  active      L=0.69    text         L=0.77
  textBright  L=0.97    activeText   L=0.149

Usage:
  python3 generate_theme.py                    # mevcut wallpaper
  python3 generate_theme.py --image <path>
  python3 generate_theme.py --color <hex>
  python3 generate_theme.py --default
  python3 generate_theme.py --auto
  python3 generate_theme.py --restart          # + quickshell restart
"""
import subprocess
import re
import os
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
THEME_FILE = BASE / "bar" / "Theme.qml"
THEME_NEXT_FILE = BASE / "bar" / "Theme.qml.next"
LOCKSCREEN_THEME_FILE = BASE / "lockscreen" / "Theme.qml"
FALLBACK_WALL = Path.home() / "Resimler" / "Wallpapers" / "dark_skulls.png"
AWWW_CACHE = Path.home() / ".cache" / "awww"

QML_FILES = list((BASE / "bar").glob("*.qml")) + list((BASE / "popups").glob("*.qml"))

MAGICK = None
for cand in ("magick", "convert"):
    if subprocess.run(["which", cand], capture_output=True).returncode == 0:
        MAGICK = cand
        break


def rgb_to_hex(r, g, b):
    return f"#{r:02x}{g:02x}{b:02x}"

def rgb_to_argb_hex(r, g, b, alpha=0.50):
    a = max(0, min(255, int(alpha * 255)))
    return f"#{a:02x}{r:02x}{g:02x}{b:02x}"


def hex_to_rgb(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def rgb_to_hsl(r, g, b):
    r, g, b = r / 255, g / 255, b / 255
    mx, mn = max(r, g, b), min(r, g, b)
    l = (mx + mn) / 2.0
    if mx == mn:
        return (0.0, 0.0, l)
    d = mx - mn
    s = d / (2.0 - mx - mn) if l > 0.5 else d / (mx + mn)
    if mx == r:
        h = (g - b) / d + (6.0 if g < b else 0.0)
    elif mx == g:
        h = (b - r) / d + 2.0
    else:
        h = (r - g) / d + 4.0
    h /= 6.0
    return (h, s, l)


def hsl_to_rgb(h, s, l):
    if s == 0.0:
        v = int(l * 255)
        return (v, v, v)

    def hue2rgb(p, q, t):
        if t < 0: t += 1
        if t > 1: t -= 1
        if t < 1 / 6: return p + (q - p) * 6 * t
        if t < 1 / 2: return q
        if t < 2 / 3: return p + (q - p) * (2 / 3 - t) * 6
        return p

    q = l * (1 + s) if l < 0.5 else l + s - l * s
    p = 2 * l - q
    r = hue2rgb(p, q, h + 1 / 3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1 / 3)
    return (int(r * 255), int(g * 255), int(b * 255))


def get_luminance(r, g, b):
    def f(v):
        v = v / 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def soften_color(r, g, b, strength=0.5):
    gray = int(r * 0.299 + g * 0.587 + b * 0.114)
    return (
        int(r * strength + gray * (1 - strength)),
        int(g * strength + gray * (1 - strength)),
        int(b * strength + gray * (1 - strength)),
    )


def darken_color(r, g, b, target_l=0.14, desaturate=0.3):
    """
    Source color'u hedef lightness'a scale edip biraz desaturate et.
    HSL'den farklı olarak RGB oranlarını korur — böylece koyu renk
    griye dönüşmez, source'un rengi net kalır.
    """
    h, s, l = rgb_to_hsl(r, g, b)
    if l <= 0:
        return (5, 5, 5)
    scale = min(target_l / l, 1.0)
    dr = max(0, min(255, int(r * scale)))
    dg = max(0, min(255, int(g * scale)))
    db = max(0, min(255, int(b * scale)))
    gray = int(dr * 0.299 + dg * 0.587 + db * 0.114)
    return (
        int(dr * (1 - desaturate) + gray * desaturate),
        int(dg * (1 - desaturate) + gray * desaturate),
        int(db * (1 - desaturate) + gray * desaturate),
    )


def boost_source(r, g, b, min_l=0.25):
    """Source çok koyuysa (L < min_l), hue ve saturation'u koruyarak parlat.
    Bu sayede koyu wallpaper'larda bile aktif renkler canlı çıkar."""
    h, s, l = rgb_to_hsl(r, g, b)
    if l >= min_l:
        return (r, g, b)
    return hsl_to_rgb(h, s, min_l)


def color_distance(c1, c2):
    return sum((a - b) ** 2 for a, b in zip(c1, c2))


def find_wallpaper():
    if AWWW_CACHE.is_dir():
        try:
            for d in sorted(AWWW_CACHE.iterdir(), key=lambda x: x.stat().st_mtime, reverse=True):
                if d.is_dir():
                    for f in sorted(d.iterdir()):
                        if f.is_file():
                            raw = f.read_bytes()
                            parts = [p.decode("utf-8", errors="replace") for p in raw.split(b"\x00") if p]
                            for p in reversed(parts):
                                p = p.strip()
                                if p.startswith("/") and Path(p).exists():
                                    return p
        except Exception:
            pass
    if FALLBACK_WALL.exists():
        return str(FALLBACK_WALL)
    return None


def extract_colors(image_path):
    if not MAGICK:
        return None
    try:
        cmd = [MAGICK, image_path, "-resize", "32x32!", "-colors", "8", "-depth", "8", "txt:-"]
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        if r.returncode != 0:
            return None
        color_counts = {}
        for line in r.stdout.strip().split("\n")[1:]:
            parts = line.split()
            if len(parts) < 3:
                continue
            hex_color = parts[2]
            if hex_color.startswith("#") and len(hex_color) in (7, 9):
                hex_rgb = hex_color[:7]
                color_counts[hex_rgb] = color_counts.get(hex_rgb, 0) + 1
        result = []
        for hex_color, count in sorted(color_counts.items(), key=lambda x: -x[1]):
            r, g, b = hex_to_rgb(hex_color)
            result.append((count, r, g, b))
        return result
    except (FileNotFoundError, subprocess.TimeoutExpired, ValueError):
        return None


def pick_source(colors):
    """
    Wallpaper'ın en karakteristik rengini seç.
    Koyu wallpaper'larda bile saturation'lu renk bulmaya çalışır.
    """
    best = None
    best_score = -1
    # İlk geçiş: L=0.08-0.70 arası, saturation ağırlıklı
    for count, r, g, b in colors:
        h, s, l = rgb_to_hsl(r, g, b)
        if l < 0.08 or l > 0.70:
            continue
        score = s * 0.5 + (count / max(1, colors[0][0])) * 0.3 + (1 - abs(l - 0.30) * 1.5) * 0.2
        if score > best_score:
            best_score = score
            best = (r, g, b)
    # İkinci geçiş: çok koyu wallpaper'lar için (L>0.02)
    if best is None:
        for count, r, g, b in colors:
            h, s, l = rgb_to_hsl(r, g, b)
            if l < 0.02 or l > 0.70:
                continue
            score = s * 0.4 + (count / max(1, colors[0][0])) * 0.4 + (1 - abs(l - 0.15) * 1.5) * 0.2
            if score > best_score:
                best_score = score
                best = (r, g, b)
    return best or (50, 50, 55)


# Orijinal grayscale temadan lightness değerleri
_L = {
    "bgDark": 0.14, "bgPopup": 0.18, "bgPopupBlur": 0.14,
    "border": 0.34, "empty": 0.34, "hover": 0.52,
    "textMuted": 0.62, "active": 0.76, "text": 0.77,
    "textBright": 0.97, "activeText": 0.15,
}
# Her rolün saturation çarpanı
_SAT = {
    "bgPopup": 0.90, "border": 0.80, "empty": 0.90,
    "hover": 0.90, "textMuted": 0.70, "active": 1.0,
    "text": 0.08, "textBright": 0.04, "activeText": 0.10,
}

def derive_full_palette(source_rgb):
    """
    Wallpaper'ın rengini tüm palette yay.
    BG roller source'un RGB oranlarını korur (darken_color ile),
    diğer roller HSL tabanlı, yüksek sat.
    """
    # Çok koyu source'u parlat — böylece darken_color düzgün scale edebilir
    # ve aktif renkler (hover/active/textMuted) her wallpaper'da canlı kalır
    sr, sg, sb = boost_source(*source_rgb)
    h, s, _ = rgb_to_hsl(sr, sg, sb)
    sat = min(max(s * 0.8, 0.15), 0.45)

    bg_r, bg_g, bg_b = darken_color(sr, sg, sb, _L["bgDark"])
    bgp_r, bgp_g, bgp_b = darken_color(sr, sg, sb, _L["bgPopup"])

    wr, wg, wb = soften_color(243, 139, 168, 0.5)
    gr, gg, gb = soften_color(74, 222, 128, 0.5)

    bgdark_hex = rgb_to_hex(bg_r, bg_g, bg_b)
    pal = {"bgDark": bgdark_hex, "bgBar": rgb_to_argb_hex(bg_r, bg_g, bg_b),
            "bgPopup": rgb_to_hex(bgp_r, bgp_g, bgp_b),     "bgPopupBlur": rgb_to_argb_hex(bg_r, bg_g, bg_b, alpha=0.70)}
    for key in ("empty", "hover", "textMuted", "active", "text", "textBright", "activeText"):
        pal[key] = rgb_to_hex(*hsl_to_rgb(h, sat * _SAT[key], _L[key]))
    br, bg, bb = hsl_to_rgb(h, sat * _SAT["border"], _L["border"])
    pal["border"] = rgb_to_argb_hex(br, bg, bb, alpha=0.40)

    return {
        **pal,
        "warn": rgb_to_hex(wr, wg, wb),
        "green": rgb_to_hex(gr, gg, gb),
    }


DEFAULT_PALETTE = {
    "bgDark": "#242424",
    "bgBar": "#40242424",
    "bgPopup": "#2e2e2e",
    "bgPopupBlur": "#99242424",
    "text": "#c5c5c5",
    "textBright": "#f7f7f7",
    "textMuted": "#808080",
    "border": "#66343434",
    "hover": "#626262",
    "active": "#b0b0b0",
    "activeText": "#272727",
    "empty": "#434343",
    "warn": "#f38ba8",
    "green": "#4ade80",
}


def get_default_palette():
    return dict(DEFAULT_PALETTE)


def sync_inline_fallbacks(palette):
    updated = 0
    for qml_file in QML_FILES:
        if qml_file.name == "Theme.qml":
            continue
        content = qml_file.read_text()
        original = content

        for prop, new_hex in palette.items():
            content = re.sub(
                r'(theme\s*\?\s*theme\.' + prop + r'\s*:\s*)'
                r'"#[0-9a-fA-F]{6,8}"',
                r'\1"' + new_hex + '"',
                content,
            )

        if content != original:
            qml_file.write_text(content)
            updated += 1
    return updated


def _theme_qml_content(palette, source_note):
    (BASE / "bar").mkdir(parents=True, exist_ok=True)
    return f"""// AUTOGENERATED by generate_theme.py
// Source: {source_note}
// Edit this file directly or re-run the script.
import QtQuick

QtObject {{
    readonly property color bgDark:      "{palette['bgDark']}"
    readonly property color bgBar:       "{palette['bgBar']}"
    readonly property color bgPopup:     "{palette['bgPopup']}"
    readonly property color bgPopupBlur: "{palette['bgPopupBlur']}"
    readonly property color text:        "{palette['text']}"
    readonly property color textBright:  "{palette['textBright']}"
    readonly property color textMuted:   "{palette['textMuted']}"
    readonly property color border:      "{palette['border']}"
    readonly property color hover:       "{palette['hover']}"
    readonly property color active:      "{palette['active']}"
    readonly property color activeText:  "{palette['activeText']}"
    readonly property color empty:       "{palette['empty']}"
    readonly property color warn:        "{palette['warn']}"
    readonly property color green:       "{palette['green']}"

    // Wallpaper picker semantic aliases
    readonly property color base:     "{palette['bgDark']}"
    readonly property color mantle:   "{palette['bgPopup']}"
    readonly property color surface1: "{palette['empty']}"
    readonly property color surface2: "{palette['hover']}"

    readonly property int barHeight:    50
    readonly property int moduleRadius: 8
    readonly property int moduleHeight: 16
    readonly property int popupRadius:  12
    readonly property int popupPad:     12
    readonly property int popupWidth:   320

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}}
"""

def _write_theme_to(path, palette, source_note=""):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(_theme_qml_content(palette, source_note))

def write_theme(palette, source_note=""):
    _write_theme_to(THEME_FILE, palette, source_note)


def print_palette(p):
    for k, v in p.items():
        if v.startswith("#"):
            print(f"  {k:15s} {v}")


def main():
    image_path = None
    accent_color = None
    use_default = False
    auto = False
    live = False
    restart = False

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] in ("--image", "-i") and i + 1 < len(args):
            image_path = args[i + 1]
            i += 2
        elif args[i] in ("--color", "-c") and i + 1 < len(args):
            accent_color = args[i + 1]
            i += 2
        elif args[i] in ("--default", "-d"):
            use_default = True
            i += 1
        elif args[i] in ("--auto", "-a"):
            auto = True
            i += 1
        elif args[i] in ("--live", "-l"):
            live = True
            i += 1
        elif args[i] in ("--restart", "-r"):
            restart = True
            i += 1
        else:
            print(f"Bilinmeyen: {args[i]}")
            sys.exit(1)

    if not auto:
        print("→ generate_theme.py")

    if use_default:
        palette = get_default_palette()
        source = "default"
        if not auto:
            print("Varsayılan tema.")
    elif accent_color:
        accent_color = accent_color.lstrip("#")
        if len(accent_color) != 6:
            print("Hata: Renk 6 haneli hex olmalı (örn: ff0000)")
            sys.exit(1)
        r, g, b = hex_to_rgb(accent_color)
        palette = derive_full_palette((r, g, b))
        source = f"manual #{accent_color}"
    elif image_path:
        if not os.path.exists(image_path):
            print(f"Hata: {image_path} bulunamadı")
            sys.exit(1)
        if not auto:
            print(f"Resim: {image_path}")
        colors = extract_colors(image_path)
        if colors:
            src = pick_source(colors)
            palette = derive_full_palette(src)
            source = os.path.basename(image_path)
        else:
            palette = get_default_palette()
            source = "fallback"
    else:
        wall = find_wallpaper()
        if wall:
            if not auto:
                print(f"Wallpaper: {wall}")
            colors = extract_colors(wall)
            if colors:
                src = pick_source(colors)
                palette = derive_full_palette(src)
                source = os.path.basename(wall)
            else:
                palette = get_default_palette()
                source = "fallback"
        else:
            if not auto:
                print("Wallpaper bulunamadı, varsayılan.")
            palette = get_default_palette()
            source = "none"

    import json as _json

    if live:
        # Canlı mod: sadece JSON (poller anında alır) + Theme.qml.next (boot'ta kullanılır)
        # Theme.qml'ye DOKUNMA — gereksiz yazma blokaj yapmasın
        _write_theme_to(THEME_NEXT_FILE, palette, source)
        _write_theme_to(LOCKSCREEN_THEME_FILE, palette, source)
        Path("/tmp/qs_theme.json").write_text(_json.dumps(palette))
        n = 0
    else:
        # Normal mod: tüm dosyaları güncelle + inline fallback sync
        write_theme(palette, source)
        _write_theme_to(THEME_NEXT_FILE, palette, source)
        _write_theme_to(LOCKSCREEN_THEME_FILE, palette, source)
        Path("/tmp/qs_theme.json").write_text(_json.dumps(palette))
        n = sync_inline_fallbacks(palette)

    # Hyprland pencere çerçevelerini dinamik olarak güncelle
    try:
        active_color = palette.get("active", "#b0a6dd")
        r, g, b = hex_to_rgb(active_color)
        active_rgba = f"rgba({r},{g},{b},1.0)"
        eval_cmd = f"hl.config({{ general = {{ col = {{ active_border = '{active_rgba}', inactive_border = 'rgba(0,0,0,0)' }} }} }})"
        subprocess.run(["hyprctl", "eval", eval_cmd], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        # Çerçeve renginin anında görselleşmesi için Hyprland'i reload et
        subprocess.run(["hyprctl", "reload"], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    if not auto:
        print(f"  → {THEME_FILE}")
        if n:
            print(f"  {n} dosyadaki fallback'ler güncellendi.")
        print_palette(palette)
        print("✓ Tamam")
    else:
        print(f"ok:{source}")

    if restart:
        subprocess.run(["quickshell", "kill"], check=False)
        subprocess.Popen(["quickshell", "-d"])


if __name__ == "__main__":
    main()
