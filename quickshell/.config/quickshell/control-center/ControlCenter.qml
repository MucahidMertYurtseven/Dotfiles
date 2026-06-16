// ============================================================
// KONTROL MERKEZİ — Wi-Fi/BT/DND toggle'ları, ses/parlaklık
// slider'ları, medya oynatıcı, sistem istatistikleri
// ============================================================
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.services

Item {
    id: root

    property Item theme: null

    implicitWidth:  420
    implicitHeight: mainCol.implicitHeight + 32

    readonly property color clrBg:      theme ? theme.bgDark : "#14151e"
    readonly property color clrCard:    theme ? theme.bgPopup : "#1c1d2b"
    readonly property color clrHov:     theme ? theme.hover : "#22243a"
    readonly property color clrViolet:  theme ? theme.active : "#7c6af7"
    readonly property color clrGreen:   theme ? theme.green : "#4ade80"
    readonly property color clrText:    theme ? theme.text : "#e8e9f5"
    readonly property color clrMuted:   theme ? theme.textMuted : "#7e8099"
    readonly property color clrBorder:  theme ? theme.border : "#2a2c42"

    // Ana arkaplan
    Rectangle {
        anchors.fill: parent
        color:        root.clrBg
        radius:       20
        border.color: root.clrBorder
        border.width: 1

        // Üstte mor ışıltı efekti
        Rectangle {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
            width: 260; height: 1; color: "transparent"
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: theme ? Qt.rgba(theme.active.r, theme.active.g, theme.active.b, 0.45) : Qt.rgba(0.49, 0.42, 0.97, 0.45) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }
    }

    ColumnLayout {
        id: mainCol
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
        spacing: 12

        // Başlık (tarih + ayarlar/güç düğmeleri)
        HeaderBar { Layout.fillWidth: true }

        // Hızlı ayar butonları (Wi-Fi, BT, Uçak, DND)
        GridLayout {
            Layout.fillWidth: true
            columns: 2; rowSpacing: 8; columnSpacing: 8

            ToggleTile {
                Layout.fillWidth: true
                icon:    "network-wireless-symbolic"
                label:   "Wi-Fi"
                sub:     NetworkService.connectedSsid
                active:  NetworkService.enabled
                theme:   root.theme
                onToggled: NetworkService.toggle()
            }
            ToggleTile {
                Layout.fillWidth: true
                icon:    "bluetooth-symbolic"
                label:   "Bluetooth"
                sub:     NetworkService.btEnabled ? "On" : "Off"
                active:  NetworkService.btEnabled
                theme:   root.theme
                onToggled: NetworkService.btToggle()
            }
            ToggleTile {
                Layout.fillWidth: true
                icon:   "airplane-mode-symbolic"
                label:  "Airplane"
                sub:    "Off"
                active: false
                theme:  root.theme
            }
            ToggleTile {
                Layout.fillWidth: true
                icon:    "notifications-disabled-symbolic"
                label:   "DND"
                sub:     AppState.dndEnabled ? "Active" : "Off"
                active:  AppState.dndEnabled
                theme:   root.theme
                onToggled: AppState.toggleDnd()
            }
        }

        // Ayraç
        Rectangle { Layout.fillWidth: true; height: 1; color: root.clrBorder; opacity: 0.6 }

        // Parlaklık slider'ı
        SliderRow {
            Layout.fillWidth: true
            icon:  "display-brightness-symbolic"
            value: BrightnessService.value
            theme: root.theme
            onMoved: function(v) { BrightnessService.setValue(v) }
        }

        // Ses slider'ı
        SliderRow {
            Layout.fillWidth: true
            icon:  "audio-volume-medium-symbolic"
            value: {
                var sink = Pipewire.defaultAudioSink
                if (!sink) return 0
                return sink.audio.muted ? 0 : Math.min(sink.audio.volume, 1.0)
            }
            theme: root.theme
            onMoved: function(v) {
                var sink = Pipewire.defaultAudioSink
                if (sink) {
                    sink.audio.volume = v
                    sink.audio.muted  = (v <= 0)
                }
            }
        }

        // Ayraç
        Rectangle { Layout.fillWidth: true; height: 1; color: root.clrBorder; opacity: 0.6 }

        // Medya oynatıcı
        MediaPlayer { Layout.fillWidth: true; theme: root.theme }

        // Ayraç
        Rectangle { Layout.fillWidth: true; height: 1; color: root.clrBorder; opacity: 0.6 }

        // Sistem istatistikleri + güç modu
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            SystemStatCard {
                Layout.fillWidth: true
                cpuLoad: SystemService.cpuLoad
                ramUsed: SystemService.ramUsed
                ramText: SystemService.ramUsedText
            }

            PowerCard {
                Layout.preferredWidth: 150
                batteryLevel: UPower.displayDevice ? UPower.displayDevice.percentage : 88
                powerMode:    PowerService.mode
            }
        }

        // Alt bilgi (uptime)
        FooterBar {
            Layout.fillWidth: true
            uptimeText: SystemService.uptime
        }
    }
}
