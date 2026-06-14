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
            size = 4,
            ignore_opacity = true,
            passes = 3
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

hl.curve("directional_jiggle", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.09} } })
hl.curve("clean_popin", {        type = "bezier", points = { {0.05, 0.9}, {0.1, 1.0} } })
hl.curve("easeOutQuint", {       type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("almostLinear", {       type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
hl.curve("quick", {              type = "bezier", points = { {0.15, 0}, {0.1, 1} } })

hl.animation({ leaf = "global",         enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border",         enabled = true, speed = 5, bezier = "directional_jiggle" })
hl.animation({ leaf = "windows",        enabled = true, speed = 5, bezier = "directional_jiggle" })
hl.animation({ leaf = "windowsIn",      enabled = true, speed = 5, bezier = "directional_jiggle", style = "slide" })
hl.animation({ leaf = "windowsOut",     enabled = true, speed = 4, bezier = "clean_popin", style = "popin 80%" })
hl.animation({ leaf = "windowsMove",    enabled = true, speed = 5, bezier = "directional_jiggle" })
hl.animation({ leaf = "fadeIn",         enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",        enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",           enabled = true, speed = 3, bezier = "clean_popin" })
hl.animation({ leaf = "layers",         enabled = true, speed = 4, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",       enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",      enabled = true, speed = 1.5, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn",   enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut",  enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",     enabled = true, speed = 5, bezier = "directional_jiggle", style = "slide" })
hl.animation({ leaf = "workspacesIn",   enabled = true, speed = 5, bezier = "directional_jiggle", style = "slide" })
hl.animation({ leaf = "workspacesOut",  enabled = true, speed = 5, bezier = "directional_jiggle", style = "slide" })
hl.animation({ leaf = "zoomFactor",     enabled = true, speed = 7, bezier = "quick" })