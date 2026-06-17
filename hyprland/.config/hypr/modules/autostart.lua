-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function ()
    -- DBus session bus'un calistigindan emin ol (MPRIS icin sart)
    hl.exec_cmd("bash -c 'if [ ! -S /run/user/1000/bus ]; then dbus-daemon --session --address=unix:path=/run/user/1000/bus --fork; fi'")

    -- Live tema JSON'unu boot'ta hazir et (poller ilk saniyede renkleri alir)
    hl.exec_cmd("python3 ~/.config/quickshell/scripts/generate_theme.py --auto --live 2>/dev/null")

    -- DBus env'ini quickshell'den once guncelle ki MPRIS calissin
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DBUS_SESSION_BUS_ADDRESS")

    -- Theme.qml.next varsa kopyala, quickshell'i baslat
    hl.exec_cmd("cp ~/.config/quickshell/bar/Theme.qml.next ~/.config/quickshell/bar/Theme.qml 2>/dev/null; quickshell")

    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("wl-paste --type text --watch cliphist store &")
    hl.exec_cmd("wl-paste --type image --watch cliphist store &")
end)
