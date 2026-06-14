// ============================================================
// İKON DÜĞME — kontrol merkezi için özelleştirilmiş buton
// Hover ve active durumuna göre renk değiştirir
// ============================================================
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

AbstractButton {
    id: btn

    property string icon: ""
    property url    iconSource: ""
    property color  iconColor: btn.accent
                               ? (btn.hovered ? "#9b8bff" : "#7c6af7")
                               : (btn.hovered ? "#c5c8e8" : "#7e8099")
    property int    size:   18
    property bool   accent: false

    implicitWidth:  size + 14
    implicitHeight: size + 14

    // Yuvarlak arkaplan
    background: Rectangle {
        radius: (btn.size + 14) / 2
        color:  btn.hovered
                ? (btn.accent ? Qt.rgba(0.49,0.42,0.97,0.2) : Qt.rgba(1,1,1,0.07))
                : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    contentItem: Item {
        anchors.centerIn: parent
        width: btn.size; height: btn.size

        // Metin ikon (SVG yoksa)
        Text {
            anchors.centerIn: parent
            text:                btn.iconSource.toString() ? "" : btn.icon
            font.pixelSize:      btn.size - 2
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment:   Text.AlignVCenter
            color:               btn.iconColor
            visible:             !btn.iconSource.toString()
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        // SVG ikon
        Image {
            id: img
            anchors.fill: parent
            source: btn.iconSource
            sourceSize.width: btn.size * 2; sourceSize.height: btn.size * 2
            visible: false
            fillMode: Image.PreserveAspectFit
            smooth: true; mipmap: true
        }

        // Renklendirme efekti
        MultiEffect {
            anchors.fill: parent
            source: img
            visible: btn.iconSource.toString()
            colorization: 1.0
            colorizationColor: btn.iconColor
        }
    }

    // Basma animasyonu
    scale: btn.pressed ? 0.88 : 1.0
    Behavior on scale { NumberAnimation { duration: 80 } }
}
