// ============================================================
// MEDYA DÜĞME — medya oynatıcı için özel buton
// Primary modda daha büyük ve mor renkli (oynat/duraklat)
// ============================================================
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

AbstractButton {
    id: btn

    property string icon: ""
    property url    iconSource: ""
    property bool   primary: false

    readonly property color _iconColor: btn.primary ? "#ffffff" : "#a0a3c0"

    implicitWidth:  primary ? 38 : 30
    implicitHeight: primary ? 38 : 30

    // Yuvarlak arkaplan
    background: Rectangle {
        radius: btn.primary ? 19 : 15
        color:  btn.primary
                ? (btn.hovered ? "#9b8bff" : "#7c6af7")
                : (btn.hovered ? "#2a2c42" : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    contentItem: Item {
        anchors.centerIn: parent
        width: btn.primary ? 18 : 14; height: width

        // Metin ikon
        Text {
            anchors.centerIn: parent
            text:                btn.iconSource.toString() ? "" : btn.icon
            font.pixelSize:      btn.primary ? 16 : 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment:   Text.AlignVCenter
            color:               btn._iconColor
            visible:             !btn.iconSource.toString()
        }

        // SVG ikon
        Image {
            id: img
            anchors.fill: parent
            source: btn.iconSource
            sourceSize.width: width * 2; sourceSize.height: height * 2
            visible: false
            fillMode: Image.PreserveAspectFit
            smooth: true; mipmap: true
        }

        // Renklendirme
        MultiEffect {
            anchors.fill: parent
            source: img
            visible: btn.iconSource.toString()
            colorization: 1.0
            colorizationColor: btn._iconColor
        }
    }

    // Basma animasyonu
    scale: btn.pressed ? 0.88 : 1.0
    Behavior on scale { NumberAnimation { duration: 80 } }
}
