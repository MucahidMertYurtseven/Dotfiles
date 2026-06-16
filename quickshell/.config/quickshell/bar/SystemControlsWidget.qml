// ============================================================
// BAR SİSTEM KONTROLLERİ — Pil, parlaklık, ses düğmeleri
// Her biri tıklanınca ilgili popup'ı açar
// Parlaklık/ses üzerinde scroll ile ayar yapılabilir
// ============================================================
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.services
import qs.components

Item {
    id: root
    property Item theme: null

    signal batteryClicked()
    signal brightnessClicked()
    signal volumeClicked()

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    // -- Pil durumu --
    property int _batPct: 80
    property bool _charging: false

    function _updateBat() {
        var dev = UPower.displayDevice
        if (dev?.ready) {
            _charging = (dev.state === 1 || dev.state === 4)
            _batPct = Math.round((dev.percentage || 0) * 100)
        }
    }
    Component.onCompleted: _updateBat()
    Connections {
        target: UPower
        function onOnBatteryChanged() { root._updateBat() }
    }
    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: root._updateBat()
    }

    height: 32
    width: innerRow.width + 16

    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgBar : "#7f0c1a33"
        radius: 14
        border.color: theme ? theme.border : "#66343434"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Row {
            id: innerRow
            anchors.centerIn: parent
            spacing: 0

            // Pil yüzdesi
            Item {
                width: 62; height: 32

                Row {
                    anchors.centerIn: parent
                    spacing: 3

                    ColorizedIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        source: {
                            if (root._charging) return root._icon + "battery-android-frame-charging.svg"
                            if (root._batPct > 90) return root._icon + "battery-android-frame-full.svg"
                            if (root._batPct > 70) return root._icon + "battery-android-frame-6.svg"
                            if (root._batPct > 50) return root._icon + "battery-android-frame-5.svg"
                            if (root._batPct > 30) return root._icon + "battery-android-frame-4.svg"
                            if (root._batPct > 10) return root._icon + "battery-android-frame-3.svg"
                            return root._icon + "battery-android-frame-2.svg"
                        }
                        iconSize: 20
                        iconColor: root._batPct <= 10 ? (theme ? theme.warn : "#d09caa") : (theme ? theme.active : "#a6badd")
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root._batPct + "%"
                        color: theme ? theme.text : "#c2c3c6"
                        font.pixelSize: 14
                        font.family: theme ? theme.fontFamily : "monospace"
                        font.bold: true
                    }
                }

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                    onClicked: root.batteryClicked()
                }
            }

            // Ayraç
            Item { width: 8; height: 32
                Rectangle { anchors.centerIn: parent; width: 1; height: 18; color: theme ? theme.border : "#66374d75"; opacity: 0.5 }
            }

            // Parlaklık
            Item {
                width: 26; height: 32
                ColorizedIcon {
                    anchors.centerIn: parent
                    source: {
                        var pct = Math.round((BrightnessService.value ?? 1) * 100)
                        return root._icon + (pct > 60 ? "brightness-high-symbolic.svg"
                            : pct > 20 ? "brightness-medium-symbolic.svg"
                            : pct > 0 ? "brightness-low-symbolic.svg"
                            : "brightness-empty-symbolic.svg")
                    }
                    iconSize: 18
                    iconColor: theme ? theme.active : "#a6badd"
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                    onClicked: root.brightnessClicked()
                    onWheel: (wheel) => {
                        var step = 0.05
                        var v = Math.max(0.05, Math.min(1, BrightnessService.value + (wheel.angleDelta.y > 0 ? step : -step)))
                        BrightnessService.setValue(v)
                        AppState.showOsd("brightness", v)
                    }
                }
            }

            // Ayraç
            Item { width: 8; height: 32
                Rectangle { anchors.centerIn: parent; width: 1; height: 18; color: theme ? theme.border : "#66374d75"; opacity: 0.5 }
            }

            // Ses
            Item {
                width: 26; height: 32
                ColorizedIcon {
                    anchors.centerIn: parent
                    source: AudioService.muted ? root._icon + "audio-volume-muted-symbolic.svg"
                        : (AudioService.volume === 0 ? root._icon + "audio-volume-off-symbolic.svg"
                            : (AudioService.volume >= 0.50 ? root._icon + "audio-volume-high-symbolic.svg"
                                : root._icon + "audio-volume-medium-symbolic.svg"))
                    iconSize: 20
                    iconColor: AudioService.muted ? (theme ? theme.warn : "#d09caa") : (theme ? theme.active : "#a6badd")
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                    onClicked: root.volumeClicked()
                    onWheel: (wheel) => {
                        var step = 0.05
                        var v = Math.max(0, Math.min(1, AudioService.volume + (wheel.angleDelta.y > 0 ? step : -step)))
                        AudioService.setVolume(v)
                        AppState.showOsd("volume", v)
                    }
                }
            }
        }
    }
}
