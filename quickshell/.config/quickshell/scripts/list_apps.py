#!/usr/bin/env python3
import json, os, sys
from pathlib import Path

XDG_DATA_HOME = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
XDG_DATA_DIRS = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")

PAPIRUS_DIRS = [
    Path.home() / ".local" / "share" / "icons" / "Papirus-Dark",
    Path("/usr/share/icons/Papirus-Dark"),
    Path("/usr/share/icons/papirus-dark"),
    Path.home() / ".local" / "share" / "icons" / "Papirus",
    Path("/usr/share/icons/Papirus"),
]
ICON_SUBDIRS = ["apps", "categories", "places", "devices", "status", "emblems"]

FAVORITES_FILE = Path.home() / ".config" / "quickshell" / "app_favorites.json"

def find_icon(iconname):
    if not iconname:
        return ""
    tried = set()
    base = iconname.rsplit(".", 1)[0] if "." in iconname else iconname
    candidates = [iconname, base, base.lower(), base.lower().replace("-", "_"), base.lower().replace("_", "-")]
    # Also try without leading "org." prefix (common in freedesktop icons)
    if base.startswith("org."):
        candidates.append(base.split(".", 1)[-1])
        candidates.append(base.split(".", 1)[-1].lower())

    for name in candidates:
        if name in tried:
            continue
        tried.add(name)
        # Papirus themes
        for basedir in PAPIRUS_DIRS:
            if not basedir.is_dir():
                continue
            for subdir in ICON_SUBDIRS:
                for ext in [".svg", ".png"]:
                    p = basedir / "48x48" / subdir / f"{name}{ext}"
                    if p.is_file():
                        return str(p)
            # symbolic fallback
            p = basedir / "symbolic" / "apps" / f"{name}-symbolic.svg"
            if p.is_file():
                return str(p)
        # hicolor: search any size dir + scalable
        hicolor = Path("/usr/share/icons/hicolor")
        if hicolor.is_dir():
            for sizedir in hicolor.iterdir():
                if sizedir.is_dir():
                    for subdir in ["apps", "categories", "places"]:
                        for ext in [".png", ".svg"]:
                            p = sizedir / subdir / f"{name}{ext}"
                            if p.is_file():
                                return str(p)
    return ""

def get_data_dirs():
    dirs = [XDG_DATA_HOME]
    for d in XDG_DATA_DIRS:
        p = Path(d)
        if p.is_dir():
            dirs.append(p)
    return dirs

def list_desktop_files():
    files = {}
    for d in get_data_dirs():
        apps_dir = d / "applications"
        if apps_dir.is_dir():
            for f in apps_dir.glob("*.desktop"):
                files[f.name] = f
    return files

def parse_desktop(path):
    name = None
    exec_cmd = None
    icon = None
    comment = None
    no_display = False
    hidden = False
    terminal = False
    categories = ""
    current_locale = None
    try:
        import locale
        current_locale = locale.getlocale()[0]
    except:
        pass

    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            in_desktop = False
            for line in f:
                line = line.rstrip("\n\r")
                if line.startswith("[Desktop Entry]"):
                    in_desktop = True
                    continue
                if in_desktop and line.startswith("["):
                    break
                if not in_desktop:
                    continue
                if "=" not in line:
                    continue
                key, val = line.split("=", 1)
                key = key.strip()
                val = val.strip()
                if key == "NoDisplay":
                    no_display = val.lower() == "true"
                elif key == "Hidden":
                    hidden = val.lower() == "true"
                elif key == "Terminal":
                    terminal = val.lower() == "true"
                elif key == "Exec":
                    exec_cmd = val
                elif key == "Icon":
                    icon = val
                elif key == "Comment":
                    comment = val
                elif key == "Categories":
                    categories = val
                elif current_locale and key == f"Name[{current_locale}]":
                    name = val
                elif key == "Name" and name is None:
                    name = val
    except:
        return None

    if name is None:
        return None
    if no_display or hidden:
        return None
    if terminal:
        return None
    if "trash" in path.name.lower():
        return None
    if "screensaver" in path.parent.name.lower():
        return None
    # Skip system config panels with no exec
    if not exec_cmd:
        return None
    # Skip known non-GUI services
    skip_names = {
        "uuctl", "xgps", "xgpsspeed", "lstopo",
    }
    if name.lower() in skip_names:
        return None
    # Skip Avahi discovery tools
    if "avahi" in path.name.lower() or path.name.lower() in ("bssh.desktop", "bvnc.desktop"):
        return None
    iconpath = find_icon(icon)
    return {"name": name, "exec": exec_cmd or "", "icon": iconpath, "comment": comment or "", "file": path.name}

def load_favorites():
    try:
        if FAVORITES_FILE.exists():
            return json.loads(FAVORITES_FILE.read_text())
    except:
        pass
    return []

def save_favorites(favs):
    FAVORITES_FILE.parent.mkdir(parents=True, exist_ok=True)
    FAVORITES_FILE.write_text(json.dumps(favs, indent=2))

def main():
    files = list_desktop_files()
    apps = []
    for fname, fpath in sorted(files.items()):
        app = parse_desktop(fpath)
        if app:
            apps.append(app)

    apps.sort(key=lambda a: a["name"].lower())

    favorites = load_favorites()
    fav_set = set(favorites)

    if len(sys.argv) > 1 and sys.argv[1] == "favorite":
        if len(sys.argv) > 2:
            fname = sys.argv[2]
            if fname in fav_set:
                fav_set.remove(fname)
            else:
                fav_set.add(fname)
            save_favorites(list(fav_set))
            return

    result = {"apps": apps, "favorites": list(fav_set)}
    print(json.dumps(result))

if __name__ == "__main__":
    main()
