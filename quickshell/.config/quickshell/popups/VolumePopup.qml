// ============================================================
// SES POPUP'I — ses seviyesi göstergesi ve slider
// Pipewire üzerinden varsayılan hoparlörü kontrol eder
// ============================================================
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.components

Item {
    id: root
    property Item theme: null

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"
    property bool open: false

    property real vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false

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

        // Ses cihaz adı
        Text {
            text: Pipewire.defaultAudioSink?.description ?? Pipewire.defaultAudioSink?.name ?? "Ses"
            color: theme ? theme.textMuted : "#7fbcb1"
            font.pixelSize: 10
            font.family: theme ? theme.fontFamily : "monospace"
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        // Ses ikonu + yüzde + mute düğmesi
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColorizedIcon {
                source: {
                    if (root.muted) return root._icon + "audio-volume-muted-symbolic.svg"
                    if (root.vol === 0) return root._icon + "audio-volume-off-symbolic.svg"
                    if (root.vol >= 0.50) return root._icon + "audio-volume-high-symbolic.svg"
                    return root._icon + "audio-volume-medium-symbolic.svg"
                }
                iconSize: 28
                iconColor: root.muted ? (theme ? theme.warn : "#d09caa") : (theme ? theme.text : "#c2c6c5")
            }

            Text {
                text: root.muted ? "Sessiz" : Math.round(root.vol * 100) + "%"
                color: theme ? theme.text : "#c2c6c5"
                font.pixelSize: 16
                font.bold: true
                font.family: theme ? theme.fontFamily : "monospace"
                Layout.fillWidth: true
            }

            // Mute toggle düğmesi
            Rectangle {
                width: 40; height: 30; radius: 6
                color: root.muted ? (theme ? theme.hover : "#53b6a4") : (theme ? theme.empty : "#33796d")
                border.color: theme ? theme.border : "#6637756a"
                border.width: 1
                ColorizedIcon {
                    anchors.centerIn: parent
                    source: root.muted ? root._icon + "audio-volume-muted-symbolic.svg" : root._icon + "audio-volume-high-symbolic.svg"
                    iconSize: 16
                    iconColor: root.muted ? (theme ? theme.warn : "#d09caa") : (theme ? theme.text : "#c2c6c5")
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var a = Pipewire.defaultAudioSink?.audio
                        if (a) a.muted = !a.muted
                    }
                }
            }
        }

        // Ayraç
        Rectangle {
            Layout.fillWidth: true; height: 1
            color: theme ? theme.border : "#6637756a"
            opacity: 0.6
        }

        // Ses slider'ı
        Item {
            id: slider
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.leftMargin: 4; Layout.rightMargin: 4

            property real value: root.vol
            readonly property real _pos: Math.min(value, 1.0)
            property bool _dragging: false
            property bool _clicking: false
            property bool _hovered: false
            property real _scaleY: _hovered || _dragging ? 1.0 : 0.75
            Behavior on _scaleY { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

            onValueChanged: {
                if (_dragging || _clicking) {
                    var a = Pipewire.defaultAudioSink?.audio
                    if (a) a.volume = value
                }
            }

            // Slider arkaplan (boş kısım)
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

                    // Parlaklık efekti
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
                    slider.value = Math.max(0, Math.min(1, mouse.x / width))
                }

                onPositionChanged: (mouse) => {
                    if (slider._dragging && pressed) {
                        slider.value = Math.max(0, Math.min(1, mouse.x / width))
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
