hl.config({

    xwayland = {
        force_zero_scaling = true,
    },
    --BORDER--
    general = {
        gaps_in = 2,
        gaps_out = 2,

        border_size = 1,
        
        col = {
            active_border = {colors = {"rgba(200,200,200,0.75)"} },
            inactive_border = "rgba(34,36,42,1)"
        }
    },

    --WINDOW--

    decoration = {
        rounding = 8,
        rounding_power = 2,
        
        active_opacity = 1,
        inactive_opacity = 0.9,

        blur = {
            enabled = true,
            size = 5,           -- size artırıldı (passes azaldı ama kalite korundu)
            ignore_opacity = true,
            passes = 2          -- 3→2: yaklaşık %40 daha az GPU yükü
        },

        shadow = {
            enabled = true,
            range = 7,
            color = 0xee0a0a0a,
        },
    }
})

hl.layer_rule({
    match = { namespace = "quickshell:bar" },
    blur = true,
    ignore_alpha = 0.1,
})

hl.layer_rule({
    match = { namespace = "quickshell:osd" },
    blur = true,
    ignore_alpha = 0.1,
})


hl.layer_rule({
    match = { namespace = "quickshell:toast" },
    blur = true,
    ignore_alpha = 0.1,
})

hl.layer_rule({
    match = { namespace = "quickshell:popup" },
    blur = true,
    ignore_alpha = 0.1,
})

-- Bezier eğrileri
-- directional_jiggle kaldırıldı (hiçbir yerde kullanılmıyordu)
hl.curve("clean_popin",  { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.0}  } })
hl.curve("easeOutCubic", { type = "bezier", points = { {0.215, 0.61}, {0.355, 1.0} } })
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1}    } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1}   } })
hl.curve("quick",        { type = "bezier", points = { {0.15, 0}, {0.1, 1}     } })

-- Animasyonlar
-- global → tüm alt animasyonlar için temel
hl.animation({ leaf = "global",      enabled = true, speed = 10,  bezier = "default" })
-- border: focus değişiminde tetiklenir, hızlı olsun (5→8)
hl.animation({ leaf = "border",      enabled = true, speed = 8,   bezier = "easeOutCubic" })
-- pencere açma/kapama/taşıma
hl.animation({ leaf = "windows",     enabled = true, speed = 5,   bezier = "easeOutCubic" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 5,   bezier = "easeOutCubic", style = "slide" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5,   bezier = "easeOutCubic", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.5, bezier = "easeOutCubic" })
-- fade: normalize edildi (1.73/1.46 → 3.0, çok yavaş hissettiriyordu)
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 3.0, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 3.0, bezier = "almostLinear" })
hl.animation({ leaf = "fade",        enabled = true, speed = 3,   bezier = "clean_popin" })
-- layer (quickshell bar/popup): layersOut 1.5→3.0 (kapanma lag'ı giderildi)
hl.animation({ leaf = "layers",      enabled = true, speed = 4,   bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 4,   bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 4,   bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
-- workspace: workspacesIn/Out kaldırıldı (parent ile birebir aynı değerdi, override yapmıyordu)
hl.animation({ leaf = "workspaces",  enabled = true, speed = 3.5, bezier = "easeOutCubic" })
-- zoomFactor: quick→easeOutCubic (quick eğrisi negatif overshoot yapıyordu)
hl.animation({ leaf = "zoomFactor",  enabled = true, speed = 7,   bezier = "easeOutCubic" })