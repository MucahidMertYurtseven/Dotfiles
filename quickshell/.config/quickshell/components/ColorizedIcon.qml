// ============================================================
// RENKLİ İKON BİLEŞENİ — SVG ikonları MultiEffect ile
// istenilen renge boyar. Tek renkli ikonlar için kullanılır.
// ============================================================
import QtQuick
import QtQuick.Effects

Item {
    id: root

    property url source: ""         // SVG dosya yolu
    property color iconColor: "#c5c5c5"
    property int iconSize: 16

    width: iconSize
    height: iconSize
    implicitWidth: iconSize
    implicitHeight: iconSize

    // Kaynak resim (görünmez, MultiEffect'e kaynak olur)
    Image {
        id: img
        anchors.fill: parent
        source: root.source
        sourceSize.width: root.iconSize * 2
        sourceSize.height: root.iconSize * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        visible: false
    }

    // Çoklu efekt: renklendirme (colorization)
    MultiEffect {
        anchors.fill: parent
        source: img
        colorization: 1.0
        colorizationColor: root.iconColor
    }
}
