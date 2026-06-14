// ============================================================
// KONTROL MERKEZİ BAŞLIK — tarih, ayarlar ve güç düğmeleri
// ============================================================
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    spacing: 0

    readonly property string _icons: Quickshell.shellDir + "/bar/icons/"

    // Sol: tarih + başlık
    ColumnLayout {
        spacing: 2
        Text {
            text:  Qt.formatDate(new Date(), "MMMM yyyy").toUpperCase()
            font { pixelSize: 22; weight: Font.Bold; letterSpacing: 0.5 }
            color: "#e8e9f5"
        }
        Text {
            text:  "CACHYOS CONTROL"
            font { pixelSize: 10; letterSpacing: 2.5; weight: Font.Medium }
            color: "#7e8099"
        }
    }

    Item { Layout.fillWidth: true }

    // Ayarlar düğmesi
    IconButton {
        iconSource: _icons + "computer-symbolic.svg"
        size: 18
        onClicked: Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["systemsettings"]; running: true }',
            parent)
    }

    Item { width: 6 }

    // Güç düğmesi
    IconButton {
        iconSource: _icons + "system-shutdown-symbolic.svg"
        size:   18
        accent: true
        onClicked: Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["wlogout"]; running: true }',
            parent)
    }
}
