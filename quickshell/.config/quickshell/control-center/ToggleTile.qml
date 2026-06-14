// ============================================================
// TOGGLE KAROSU — Wi-Fi/BT/DND gibi aç/kapa düğmeleri
// Aktif/pasif durumuna göre renk değiştirir
// ============================================================
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell

AbstractButton {
    id: tile

    required property string icon
    required property string label
    required property string sub
    required property bool   active

    signal toggled()

    // SVG ikon yolunu belirle
    readonly property url _svgSource: {
        var iconsDir = Quickshell.shellDir + "/bar/icons/"
        if (tile.icon === "network-wireless-symbolic")       return iconsDir + "network-wireless-signal-excellent-symbolic.svg"
        if (tile.icon === "bluetooth-symbolic")               return iconsDir + "network-bluetooth-activated-symbolic.svg"
        if (tile.icon === "airplane-mode-symbolic")           return iconsDir + "network-wireless-signal-none-symbolic.svg"
        if (tile.icon === "notifications-disabled-symbolic")  return iconsDir + "notifications-disabled-symbolic.svg"
        return ""
    }

    implicitHeight: 72

    readonly property color _bg:     active ? "#2d2a52" : "#1c1d2b"
    readonly property color _bgHov:  active ? "#353261" : "#22243a"
    readonly property color _accent: "#7c6af7"
    readonly property color _text:   "#e8e9f5"
    readonly property color _muted:  "#7e8099"
    readonly property color _border: active ? "#4a45a0" : "#2a2c42"

    // Arkaplan
    background: Rectangle {
        color:        tile.hovered ? tile._bgHov : tile._bg
        radius:       14
        border.color: tile._border
        border.width: 1
        Behavior on color        { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    // İçerik
    contentItem: RowLayout {
        anchors { fill: parent; margins: 14 }
        spacing: 12

        // İkon kutusu
        Rectangle {
            width: 36; height: 36; radius: 10
            color: tile.active ? Qt.rgba(0.49, 0.42, 0.97, 0.22) : Qt.rgba(1,1,1,0.06)

            Item {
                anchors.centerIn: parent
                width: 20; height: 20

                Image {
                    id: img
                    anchors.fill: parent
                    source: tile._svgSource
                    sourceSize.width: 40; sourceSize.height: 40
                    visible: false
                    fillMode: Image.PreserveAspectFit
                    smooth: true; mipmap: true
                }

                MultiEffect {
                    anchors.fill: parent
                    source: img
                    visible: tile._svgSource.toString()
                    colorization: 1.0
                    colorizationColor: tile.active ? "#7c6af7" : "#7e8099"
                }

                Text {
                    anchors.centerIn: parent
                    text: tile._svgSource.toString() ? "" : "●"
                    font.pixelSize: 18
                    color: tile.active ? "#7c6af7" : "#7e8099"
                    visible: !tile._svgSource.toString()
                }
            }
        }

        // Etiket + alt metin
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text:  tile.label
                color: tile._text
                font { pixelSize: 14; weight: Font.SemiBold }
            }
            Text {
                text:  tile.sub
                color: tile._muted
                font.pixelSize: 11
            }
        }
    }

    onClicked: tile.toggled()

    // Basma animasyonu
    scale: tile.pressed ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
}
