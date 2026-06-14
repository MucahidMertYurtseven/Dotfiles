---------------
---- INPUT ----
---------------
hl.config({
    input = {
        kb_layout = "tr,us",
        
        natural_scroll = false, 
        
        touchpad = {
            natural_scroll = true
        }
    }
})


hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})
