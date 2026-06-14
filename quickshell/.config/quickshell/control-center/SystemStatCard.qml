// ============================================================
// SİSTEM İSTATİSTİK KARTI — CPU ve RAM kullanım çubukları
// Gradient dolgulu canlı gösterge
// ============================================================
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    implicitHeight: 90

    required property real   cpuLoad
    required property real   ramUsed
    required property string ramText

    // Kart arkaplanı
    Rectangle {
        anchors.fill: parent
        color:        "#1c1d2b"
        radius:       14
        border.color: "#2a2c42"
        border.width: 1

        ColumnLayout {
            anchors { fill: parent; margins: 14 }
            spacing: 8

            // CPU yükü
            RowLayout {
                spacing: 0
                Text { text: "CPU LOAD"; color: "#7e8099"; font { pixelSize: 10; letterSpacing: 1.5; weight: Font.Medium } }
                Item  { Layout.fillWidth: true }
                Text { text: Math.round(cpuLoad) + "%"; color: "#e8e9f5"; font { pixelSize: 12; weight: Font.Bold } }
            }
            Rectangle {
                Layout.fillWidth: true; height: 4; radius: 2; color: "#2a2c42"
                Rectangle {
                    width:  parent.width * Math.min(cpuLoad / 100, 1)
                    height: parent.height; radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#5a50d0" }
                        GradientStop { position: 1.0; color: "#9b8bff" }
                    }
                    Behavior on width { NumberAnimation { duration: 400 } }
                }
            }

            // RAM kullanımı
            RowLayout {
                spacing: 0
                Text { text: "RAM"; color: "#7e8099"; font { pixelSize: 10; letterSpacing: 1.5; weight: Font.Medium } }
                Item  { Layout.fillWidth: true }
                Text { text: ramText; color: "#4ade80"; font { pixelSize: 12; weight: Font.Bold } }
            }
            Rectangle {
                Layout.fillWidth: true; height: 4; radius: 2; color: "#2a2c42"
                Rectangle {
                    width:  parent.width * Math.min(ramUsed, 1)
                    height: parent.height; radius: parent.radius
                    color:  "#4ade80"
                    Behavior on width { NumberAnimation { duration: 400 } }
                }
            }
        }
    }
}
