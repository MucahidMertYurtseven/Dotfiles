// ============================================================
// GÜÇ POPUP'I — pil durumu ve güç modu seçici
// UPower üzerinden pil bilgisi, powerprofilesctl ile mod
// ============================================================
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.components

Item {
    id: root
    property var theme: null

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"
    property bool open: false
    property string mode: "Balanced"
    property int batteryPct: 80
    property bool charging: false
    signal modeSelected(string mode)

    anchors.fill: parent

    // Popup arkaplanı
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgPopupBlur : "#202020"
        radius: theme ? theme.popupRadius : 12
        border.color: theme ? theme.border : "#323232"; border.width: 1
    }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: theme?.popupPad ?? 12 }
        spacing: 10

        // Pil durumu
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColorizedIcon {
                source: root._icon + root._batteryIcon()
                iconSize: 26
                iconColor: theme ? theme.text : "#c5c5c5"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: batteryPct + "%"
                    color: batteryPct < 20
                        ? (theme ? theme.warn : "#f38ba8")
                        : (theme ? theme.text : "#c5c5c5")
                    font.pixelSize: 22
                    font.bold: true
                    font.family: theme ? theme.fontFamily : "monospace"
                }

                Text {
                    text: root._timeText()
                    color: theme ? theme.textMuted : "#7e8099"
                    font.pixelSize: 9
                    font.family: theme ? theme.fontFamily : "monospace"
                    visible: text !== ""
                }
            }

            // Şarj durumu
            Text {
                text: root._statusText()
                color: root._statusColor()
                font.pixelSize: 10
                font.family: theme ? theme.fontFamily : "monospace"
            }
        }

        // Ayraç
        Rectangle {
            Layout.fillWidth: true; height: 1
            color: theme ? theme.border : "#323232"
            opacity: 0.6
        }

        // Güç modu seçici başlık
        Text {
            text: "Güç Modu"
            color: theme ? theme.textMuted : "#7e8099"
            font.pixelSize: 10
            font.family: theme ? theme.fontFamily : "monospace"
        }

        // Mod ikonları
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: [
                    { key: "Performance", icon: "bolt-symbolic.svg" },
                    { key: "Balanced", icon: "balance-symbolic.svg" },
                    { key: "Power Saver", icon: "eco-symbolic.svg" }
                ]

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 6
                    color: modelData.key === root.mode
                        ? (theme ? theme.active : "#b0b0b0")
                        : (ma.containsMouse ? (theme ? theme.hover : "#606060") : (theme ? theme.empty : "#414141"))
                    Behavior on color { ColorAnimation { duration: 100 } }

                    ColorizedIcon {
                        anchors.centerIn: parent
                        source: root._icon + modelData.icon
                        iconSize: 18
                        iconColor: modelData.key === root.mode ? "#000000" : (theme ? theme.text : "#c5c5c5")
                    }

                    property bool containsMouse: false
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.containsMouse = true
                        onExited: parent.containsMouse = false
                        onClicked: {
                            if (root.mode !== modelData.key) root.modeSelected(modelData.key)
                        }
                    }
                }
            }
        }

        // Mod etiketleri
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: [
                    { key: "Performance", label: "Performans" },
                    { key: "Balanced", label: "Dengeli" },
                    { key: "Power Saver", label: "Tasarruf" }
                ]

                Item {
                    Layout.fillWidth: true
                    implicitHeight: txt.implicitHeight

                    Text {
                        id: txt
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: modelData.key === root.mode
                            ? (theme ? theme.text : "#c5c5c5")
                            : (theme ? theme.textMuted : "#7e8099")
                        font.pixelSize: 9
                        font.family: theme ? theme.fontFamily : "monospace"
                        font.bold: modelData.key === root.mode
                    }
                }
            }
        }
    }

    // Pil seviyesine göre ikon seç
    function _batteryIcon() {
        if (charging) return "battery-android-frame-charging.svg"
        if (batteryPct >= 100) return "battery-android-frame-full.svg"
        if (batteryPct < 10) return "battery-android-frame-alert.svg"
        var idx = Math.min(Math.floor(batteryPct / 16.7), 5)
        return "battery-android-frame-" + (idx + 1) + ".svg"
    }

    // Şarj durumu metni
    function _statusText() {
        var dev = UPower.displayDevice
        if (!dev || !dev.ready) return ""
        if (dev.state === 1) return "Şarj Oluyor"
        if (dev.state === 4) return "Dolu"
        return ""
    }

    // Şarj durumu rengi
    function _statusColor() {
        if (charging) return theme ? theme.green : "#4ade80"
        return theme ? theme.textMuted : "#7e8099"
    }

    // Kalan süre metni
    function _timeText() {
        var dev = UPower.displayDevice
        if (!dev || !dev.ready) return ""
        var secs = -1
        if (dev.state === 2 && dev.timeToEmpty > 0) {
            secs = dev.timeToEmpty
        } else if ((dev.state === 1 || dev.state === 5) && dev.timeToFull > 0) {
            secs = dev.timeToFull
        }
        if (secs <= 0) return ""
        var h = Math.floor(secs / 3600)
        var m = Math.floor((secs % 3600) / 60)
        if (h > 0) return h + "s " + m + "dk kaldı"
        return m + "dk kaldı"
    }
}
