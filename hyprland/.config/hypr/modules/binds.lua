---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "thunar"


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- ==========================================
-- APP KEYBINDINGS
-- ==========================================

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("touch /tmp/quickshell-launcher"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("touch /tmp/quickshell-wallpaper"))
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd(" quickshell -c /home/mert/.config/quickshell/HyprQuickFrame/ -n"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("sh -c 'cliphist list | wofi --dmenu --show dmenu -p \"Pano: \" | cliphist decode | wl-copy'"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("/home/mert/.config/quickshell/lockscreen/lock.sh"))
-- ==========================================
-- PENCERE ODAĞI (FOCUS) DEĞİŞTİRME
-- ==========================================

-- Yön Tuşları ile Odaklanma
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- ==========================================
-- PENCERELERİ TAŞIMA (MOVE)
-- ==========================================

-- Yön Tuşları ile Taşıma
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))



-- ==========================================
-- PENCERELERİ BOYUTLANDIRMA (RESIZE)
-- ==========================================

-- Klavye ile Boyutlandırma (SUPER + ALT + HJKL)
hl.bind(mainMod .. " + ALT + L", hl.dsp.window.resize({ x = 30, y = 0, relative = true }),  { repeating = true })
hl.bind(mainMod .. " + ALT + H", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + K", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + J", hl.dsp.window.resize({ x = 0, y = 30, relative = true }),  { repeating = true })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({"0"}))

-- ==========================================
-- FARE İLE PENCERE YÖNETİMİ
-- ==========================================

-- SUPER + Sol Tık ile Taşıma (Drag)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
-- Orijinal dosyandaki SUPER + SHIFT + Sağ Tık ile Boyutlandırma (Resize)
hl.bind(mainMod .. " + SHIFT + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ==========================================
-- FONKSİYON, SES VE MEDYA TUŞLARI
-- ==========================================

-- PipeWire (wpctl) ile Ses Kontrolleri
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),    { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })

--Parlaklık Kontrolü
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

-- MSI Harici Monitör Parlaklık Kontrolü
hl.bind(mainMod .. " + F6", hl.dsp.exec_cmd("ddcutil setvcp 10 + 5"), { locked = true, repeating = true })
hl.bind(mainMod .. " + F5", hl.dsp.exec_cmd("ddcutil setvcp 10 - 5"), { locked = true, repeating = true })


-- ==========================================
-- ÇALIŞMA ALANLARI (WORKSPACES)
-- ==========================================

-- SUPER + CTRL + Sağ/Sol ok ile çalışma alanlarında gezinme (Yeni alan oluşturur/geçiş yapar)
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.focus({ workspace = "r-1" }))

-- Ekstra: SUPER + 1,2,3.. ile direkt numaralı çalışma alanına gitme (Sıfırdan yaratmak için çok kullanışlıdır)
for i = 1, 10 do
    local key = i % 10 -- 10. alanı '0' tuşuna atar
    -- O alana git
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i}))
    -- Aktif pencereyi o alana fırlat (SUPER + SHIFT + 1,2,3..)
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- UYKU MODU
-- Kilit ekranındayken ESC'ye basınca monitörleri kapat
-- Laptop kapağını kapatınca uyku moduna geç
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout current next"))
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("systemctl suspend"))