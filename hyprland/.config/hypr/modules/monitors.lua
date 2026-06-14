------------------
---- MONITORS ----
------------------
---
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080",
    position = "0x0",
    scale    = "1.0",
})

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080",
    position = "1920x0",
    scale    = "1.0",
})


hl.monitor({
     output = "WAYLAND-1",
     disabled = true
})

-- Workspace assignments
-- External (HDMI-A-1): 1-5, Internal (eDP-1): 6-10
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1", persistent = true })

hl.workspace_rule({ workspace = "6", monitor = "eDP-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "7", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "8", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "9", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "10", monitor = "eDP-1", persistent = true })
