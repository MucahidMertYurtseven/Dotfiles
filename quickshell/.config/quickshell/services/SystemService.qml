// ============================================================
// SİSTEM SERVİSİ (Singleton) — CPU, RAM, sıcaklık, çalışma
// süresi bilgilerini /proc dosyalarından okur
// ============================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    property real cpuLoad: 0
    property real ramUsed: 0
    property string ramUsedText: "0 GB"
    property int temp: 0
    property string uptime: "0H 0M"

    property var _prevCpu: null

    // CPU yükü hesaplama (/proc/stat)
    Process {
        id: _cpuProc
        command: ["cat", "/proc/stat"]
        stdout: SplitParser {
            onRead: function(line) {
                if (!line.startsWith("cpu ")) return
                var f = line.trim().split(/\s+/)
                var user = parseInt(f[1])
                var nice = parseInt(f[2])
                var system = parseInt(f[3])
                var idle = parseInt(f[4])
                var iowait = parseInt(f[5])
                var irq = parseInt(f[6])
                var softirq = parseInt(f[7])
                var total = user + nice + system + idle + iowait + irq + softirq
                var active = total - idle - iowait
                if (root._prevCpu) {
                    var dt = total - root._prevCpu.total
                    var da = active - root._prevCpu.active
                    root.cpuLoad = dt > 0 ? Math.min((da / dt) * 100, 100) : 0
                }
                root._prevCpu = { total: total, active: active }
            }
        }
    }

    // 2sn'de bir CPU güncelle
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: _cpuProc.running = true
    }

    property var _ramBuf: ""

    // RAM kullanımı (/proc/meminfo)
    Process {
        id: _ramProc
        command: ["cat", "/proc/meminfo"]
        stdout: SplitParser {
            onRead: function(line) { _ramBuf += line + "\n" }
        }
        onExited: function() {
            var mem = {}
            _ramBuf.split("\n").forEach(function(l) {
                var p = l.split(":")
                if (p.length === 2) mem[p[0].trim()] = parseInt(p[1].trim())
            })
            _ramBuf = ""
            var total = mem["MemTotal"] || 1
            var avail = mem["MemAvailable"] || 0
            var used = total - avail
            ramUsed = used / total
            ramUsedText = (used / 1048576).toFixed(1) + "GB"
        }
    }

    // 2sn'de bir RAM güncelle
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: _ramProc.running = true
    }

    // Sıcaklık (/sys/class/thermal)
    Process {
        id: _tempProc
        command: ["sh", "-c", "for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat \"$z/type\" 2>/dev/null)\" = \"x86_pkg_temp\" ] && { cat \"$z/temp\" | awk '{printf \"%.0f\", $1/1000}'; break; }; done 2>/dev/null || echo 0"]
        stdout: SplitParser {
            onRead: function(line) {
                var v = parseInt(line.trim()) || 0
                temp = v
            }
        }
    }

    // 5sn'de bir sıcaklık güncelle
    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: _tempProc.running = true
    }

    // Çalışma süresi (/proc/uptime)
    Process {
        id: _upProc
        command: ["cat", "/proc/uptime"]
        stdout: SplitParser {
            onRead: function(line) {
                var secs = parseFloat(line.split(" ")[0])
                if (!isNaN(secs)) {
                    uptime = Math.floor(secs / 3600) + "H " +
                             Math.floor((secs % 3600) / 60) + "M"
                }
            }
        }
    }

    // 60sn'de bir uptime güncelle
    Timer {
        interval: 60000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: _upProc.running = true
    }
}
