// ============================================================
// KONTROL MERKEZİ SHELL — ayrı bir pencere olarak açılır
// Sadece ilk ekranda görünür, overlay katmanında çalışır
// ============================================================
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import QtQuick
import qs.services

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            property var modelData
            screen: modelData

            visible: screen === Quickshell.screens[0]  // sadece ilk ekran

            anchors.top:   true
            anchors.right: true

            implicitWidth:  cc.implicitWidth
            implicitHeight: cc.implicitHeight

            color: "transparent"

            WlrLayerShell.layer:         WlrLayer.Overlay
            WlrLayerShell.keyboardFocus: WlrKeyboardFocus.OnDemand

            ControlCenter { id: cc }
        }
    }
}
