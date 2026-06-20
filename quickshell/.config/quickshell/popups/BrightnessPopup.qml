// ============================================================
// PARLAKLIK POPUP'I — ekran parlaklığı göstergesi ve slider
// BrightnessService üzerinden brightnessctl ile kontrol
// ============================================================
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

Item {
    id: root
    property Item theme: null

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"
    property bool open: false

    property real _val: BrightnessService.value

    anchors.fill: parent

    // Popup arkaplanı
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgPopupBlur : "#b2143630"
        radius: theme ? theme.popupRadius : 12
        border.color: theme ? theme.border : "#6637756a"; border.width: 1
    }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: theme?.popupPad ?? 12 }
        spacing: 10

        // Cihaz adı
        Text {
            text: BrightnessService.deviceName
            color: theme ? theme.textMuted : "#7fbcb1"
            font.pixelSize: 10
            font.family: theme ? theme.fontFamily : "monospace"
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        // İkon + yüzde
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColorizedIcon {
                source: {
                    var pct = Math.round(root._val * 100)
                    return root._icon + (pct > 60 ? "brightness-high-symbolic.svg"
                        : pct > 20 ? "brightness-medium-symbolic.svg"
                        : pct > 0 ? "brightness-low-symbolic.svg"
                        : "brightness-empty-symbolic.svg")
                }
                iconSize: 28
                iconColor: root._val <= 0.05
                    ? (theme ? theme.warn : "#d09caa")
                    : (theme ? theme.text : "#c2c6c5")
            }

            Text {
                text: Math.round(root._val * 100) + "%"
                color: theme ? theme.text : "#c2c6c5"
                font.pixelSize: 16
                font.bold: true
                font.family: theme ? theme.fontFamily : "monospace"
                Layout.fillWidth: true
            }
        }

        // Ayraç
        Rectangle {
            Layout.fillWidth: true; height: 1
            color: theme ? theme.border : "#6637756a"
            opacity: 0.6
        }

        // Parlaklık slider'ı
        Item {
            id: slider
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.leftMargin: 4; Layout.rightMargin: 4

            property real from: 0.05
            property real to: 1
            property real value: root._val

            readonly property real _pos: to > from ? (value - from) / (to - from) : 0
            property bool _dragging: false
            property bool _clicking: false
            property bool _hovered: false
            property real _scaleY: _hovered || _dragging ? 1.0 : 0.75
            Behavior on _scaleY { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

            onValueChanged: {
                if (_dragging || _clicking)
                    BrightnessService.setValue(value)
            }

            // Slider arkaplan
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 8
                radius: height / 2
                color: theme ? theme.border : "#6637756a"

                transform: Scale { origin.y: 4; yScale: slider._scaleY }

                // Slider dolu kısım
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * slider._pos
                    radius: parent.radius
                    color: theme ? theme.active : "#a6ddd3"

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        width: parent.width * 0.8
                        height: parent.height * 0.3
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, 0.15)
                        visible: parent.width > 2
                    }
                }
            }

            // Slider fare etkileşimi
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onEntered: slider._hovered = true
                onExited: slider._hovered = false

                onPressed: (mouse) => {
                    slider._dragging = true
                    slider._clicking = true
                    var ratio = Math.max(0, Math.min(1, mouse.x / width))
                    slider.value = slider.from + ratio * (slider.to - slider.from)
                }

                onPositionChanged: (mouse) => {
                    if (slider._dragging && pressed) {
                        var ratio = Math.max(0, Math.min(1, mouse.x / width))
                        slider.value = slider.from + ratio * (slider.to - slider.from)
                    }
                }

                onReleased: {
                    slider._dragging = false
                    slider._clicking = false
                }
            }
        }
    }
}
