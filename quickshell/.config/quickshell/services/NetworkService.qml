// ============================================================
// AĞ SERVİSİ (Singleton) — Wi-Fi ve Bluetooth yönetimi
// nmcli ile ağ tarama/bağlanma, bluetoothctl ile BT kontrolü
// ============================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    visible: false

    property var networks: []
    property string connectedSsid: ""
    property bool enabled: true

    property bool btEnabled: false

    // Wi-Fi taraması başlat
    function scan() { scanProc.running = true }

    // Ağa bağlan
    function connectTo(ssid) {
        connectProc.command = ["nmcli", "device", "wifi", "connect", ssid]
        connectProc.running = true
    }

    // Wi-Fi aç/kapat
    function toggle() {
        toggleProc.command = enabled
            ? ["nmcli", "radio", "wifi", "off"]
            : ["nmcli", "radio", "wifi", "on"]
        toggleProc.running = true
    }

    // Durumu yenile
    function refreshState() {
        stateProc.running = true
    }

    // Bluetooth aç/kapat
    function btToggle() {
        btEnabled = !btEnabled
        btToggleProc.command = ["bluetoothctl", "power", btEnabled ? "on" : "off"]
        btToggleProc.running = true
    }

    // Wi-Fi toggle sonrası durumu yenile
    Process {
        id: toggleProc
        command: []
        running: false
        onExited: { refreshState() }
    }

    // Wi-Fi taraması
    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list"]
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim() === "") return
                var parts = line.split(":")
                var ssid = parts[0] || ""
                var signal = parseInt(parts[1]) || 0
                var inUse = parts[3] || ""
                if (ssid === "" || ssid === "--") return
                if (inUse === "*") connectedSsid = ssid
                var exists = false
                for (var i = 0; i < networks.length; i++) {
                    if (networks[i].name === ssid) { exists = true; break }
                }
                if (!exists) {
                    networks = networks.concat([{
                        name: ssid,
                        signalStrength: signal,
                        connected: ssid === connectedSsid
                    }])
                }
            }
        }
    }

    // Ağa bağlanma process'i
    Process {
        id: connectProc
        command: []
        running: false
    }

    // Wi-Fi durumu sorgula
    Process {
        id: stateProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device", "status"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split(":")
                if (parts.length >= 2 && parts[0] === "wifi") {
                    enabled = (parts[1] !== "unavailable")
                }
            }
        }
    }

    // 30sn'de bir otomatik tara
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: scan()
    }

    // Bluetooth durumu sorgula
    Process {
        id: btCheckProc
        command: ["bluetoothctl", "show"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                if (line.indexOf("Powered: yes") !== -1) btEnabled = true
                if (line.indexOf("Powered: no") !== -1) btEnabled = false
            }
        }
    }

    // Bluetooth toggle process
    Process {
        id: btToggleProc
        command: []
        running: false
        onExited: { btCheckProc.running = true }
    }

    // 10sn'de bir bluetooth durumu kontrol et
    Timer {
        interval: 10000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: btCheckProc.running = true
    }
}
