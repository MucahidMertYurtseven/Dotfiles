// ============================================================
// KONTROL MERKEZİ ALT BİLGİ — uptime ve kısayol düğmeleri
// ============================================================
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io

RowLayout {
    spacing: 8
    required property string uptimeText

    readonly property string _icons: Quickshell.shellDir + "/bar/icons/"

    // Kilit ikonu
    Item { width: 12; height: 12
        Image {
            id: clockImg
            anchors.fill: parent
            source: _icons + "system-lock-screen-symbolic.svg"
            sourceSize.width: 24; sourceSize.height: 24
            visible: false
            fillMode: Image.PreserveAspectFit
            smooth: true; mipmap: true
        }
        MultiEffect {
            anchors.fill: parent; source: clockImg
            colorization: 1.0; colorizationColor: "#7e8099"
        }
    }

    // Uptime metni
    Text {
        text:  "UPTIME: " + uptimeText
        color: "#7e8099"
        font { pixelSize: 10; letterSpacing: 1.2; weight: Font.Medium }
    }

    Item { Layout.fillWidth: true }

    // Ayarlar
    IconButton {
        iconSource: _icons + "computer-symbolic.svg"
        size: 16
        onClicked: Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["xdg-open", "' + Qt.resolvedUrl(".") + '"]; running: true }',
            parent)
    }

    // Güç
    IconButton {
        iconSource: _icons + "system-shutdown-symbolic.svg"
        size: 16
        onClicked: Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["wlogout"]; running: true }',
            parent)
    }
}
