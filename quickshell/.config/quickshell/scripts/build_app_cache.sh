#!/bin/sh
CACHE="${1:-/tmp/qs-app-cache.txt}"
echo -n > "$CACHE"
find /usr/share/applications ~/.local/share/applications \
     /var/lib/flatpak/exports/share/applications \
     ~/.local/share/flatpak/exports/share/applications \
     -name '*.desktop' 2>/dev/null | while read f; do
    n=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
    x=$(grep -m1 '^Exec=' "$f" | cut -d= -f2- | sed 's/%[a-zA-Z]//g; s/ *$//')
    c=$(grep -m1 '^Comment=' "$f" | cut -d= -f2-)
    nd=$(grep -m1 '^NoDisplay=' "$f" | cut -d= -f2-)
    [ "$nd" = "true" ] && continue
    [ -z "$n" ] && continue
    echo "$n|$x|$c" >> "$CACHE"
done
LC_ALL=C sort -t'|' -k1,1 "$CACHE" | uniq > "${CACHE}.tmp" && mv "${CACHE}.tmp" "$CACHE"
