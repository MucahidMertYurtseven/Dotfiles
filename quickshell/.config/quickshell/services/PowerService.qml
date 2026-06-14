// ============================================================
// GÜÇ SERVİSİ (Singleton) — güç profili yönetimi
// powerprofilesctl ile Performance/Balanced/Power Saver
// ============================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    visible: false

    property string mode: "Balanced"
    readonly property var modes: ["Performance", "Balanced", "Power Saver"]

    function refresh() { getProc.running = true }

    // Güç modunu ayarla
    function setMode(m) {
        mode = m
        var arg = m.toLowerCase().replace(" ", "-")
        setProc.command = ["powerprofilesctl", "set", arg]
        setProc.running = true
    }

    // Mevcut modu oku
    Process {
        id: getProc
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var m = line.trim()
                var map = {
                    "performance": "Performance",
                    "balanced": "Balanced",
                    "power-saver": "Power Saver"
                }
                mode = map[m] || m || "Balanced"
            }
        }
    }

    // Mod ayarlama process'i
    Process {
        id: setProc
        command: []
        running: false
    }
}
