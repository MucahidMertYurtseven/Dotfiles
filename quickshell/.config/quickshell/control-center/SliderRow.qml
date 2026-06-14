// ============================================================
// SLIDER SATIRI — ikon + slider (parlaklık/ses için)
// Gradient dolgulu özel Qt Slider görünümü
// ============================================================
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell

RowLayout {
    spacing: 12

    required property string icon
    required property real   value
    signal moved(real value)

    readonly property url _svgSource: {
        var iconsDir = Quickshell.shellDir + "/bar/icons/"
        if (icon === "display-brightness-symbolic")       return iconsDir + "brightness-high-symbolic.svg"
        if (icon === "audio-volume-medium-symbolic")      return iconsDir + "audio-volume-medium-symbolic.svg"
        return ""
    }

    // İkon
    Item {
        width: 18; height: 18

        Image {
            id: img
            anchors.fill: parent
            source: parent._svgSource
            sourceSize.width: 36; sourceSize.height: 36
            visible: false
            fillMode: Image.PreserveAspectFit
            smooth: true; mipmap: true
        }

        MultiEffect {
            anchors.fill: parent
            source: img
            visible: parent._svgSource.toString()
            colorization: 1.0
            colorizationColor: "#7e8099"
        }

        Text {
            anchors.centerIn: parent
            text: parent._svgSource.toString() ? "" : "●"
            font.pixelSize: 16
            color: "#7e8099"
            visible: !parent._svgSource.toString()
        }
    }

    // Qt Slider
    Slider {
        id: slider
        Layout.fillWidth: true
        from:  0.0
        to:    1.0
        value: parent.value
        live:  true

        onMoved: parent.moved(value)

        // Slider arkaplan
        background: Rectangle {
            x:      slider.leftPadding
            y:      slider.topPadding + slider.availableHeight / 2 - height / 2
            width:  slider.availableWidth
            height: 5
            radius: 3
            color:  "#2a2c42"

            // Gradient dolu kısım
            Rectangle {
                width:  slider.visualPosition * parent.width
                height: parent.height
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#5a50d0" }
                    GradientStop { position: 1.0; color: "#9b8bff" }
                }
            }
        }

        // Slider topuzu
        handle: Rectangle {
            x:      slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y:      slider.topPadding  + slider.availableHeight / 2 - height / 2
            width:  14; height: 14; radius: 7
            color:  "#9b8bff"
            border.color: Qt.rgba(1,1,1,0.15)
            border.width: 1
        }
    }
}
