// ============================================================
// PARLAKLIK SERVİSİ (Singleton) — brightnessctl ile ekran
// parlaklığı kontrolü. Birden çok cihazı destekler.
// ============================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    visible: false

    property real value: 0
    property string deviceName: "Parlaklık"
    property var devices: []

    // Parlaklık değerini ayarla (0.0 - 1.0)
    function setValue(v, dev) {
        value = v
        var pct = Math.round(Math.max(1, Math.min(100, v * 100)))
        var cmd = dev ? ["brightnessctl", "-d", dev, "s", pct + "%"]
                      : ["brightnessctl", "s", pct + "%"]
        setProc.command = cmd
        setProc.running = true
    }

    // Cihazları listele
    Process {
        id: listProc
        command: ["brightnessctl", "-l"]
        stdout: SplitParser {
            onRead: function(line) {
                var m = line.match(/Device '([^']+)' of class 'backlight'/)
                if (m) {
                    var n = m[1]
                    var exists = false
                    for (var i = 0; i < devices.length; i++) {
                        if (devices[i] === n) { exists = true; break }
                    }
                    if (!exists) devices = devices.concat([n])
                }
            }
        }
    }

    // Mevcut parlaklığı oku
    Process {
        id: getProc
        command: ["brightnessctl", "-m"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split(",")
                if (parts.length >= 4) {
                    var pct = parseInt(parts[3]) || 0
                    value = Math.min(pct / 100.0, 1.0)
                    if (parts[0]) deviceName = parts[0].replace(/_/g, " ")
                }
            }
        }
    }

    // Parlaklık ayarlama process'i
    Process {
        id: setProc
        command: []
    }

    function refresh() { getProc.running = true }

    // 100ms'de bir güncelle
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: refresh()
    }
}
