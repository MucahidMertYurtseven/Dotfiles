// ============================================================
// GÜÇ KARTI — pil seviyesi + güç modu göstergesi
// ============================================================
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell

Item {
    implicitHeight: 90

    required property real   batteryLevel
    required property string powerMode

    readonly property string _icons: Quickshell.shellDir + "/bar/icons/"

    // Kart arkaplanı
    Rectangle {
        anchors.fill: parent
        color:        "#1c1d2b"
        radius:       14
        border.color: "#2a2c42"
        border.width: 1

        ColumnLayout {
            anchors { fill: parent; margins: 14 }
            spacing: 6

            // Pil yüzdesi
            RowLayout {
                Item { width: 18; height: 18
                    Image {
                        id: batImg
                        anchors.fill: parent
                        source: _icons + "battery-android-frame-full.svg"
                        sourceSize.width: 36; sourceSize.height: 36
                        visible: false
                        fillMode: Image.PreserveAspectFit
                        smooth: true; mipmap: true
                    }
                    MultiEffect {
                        anchors.fill: parent; source: batImg
                        colorization: 1.0; colorizationColor: "#e8e9f5"
                    }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text:                      Math.round(batteryLevel * 100) + "%"
                    color: "#e8e9f5"
                    font { pixelSize: 14; weight: Font.Bold }
                }
            }

            Item { Layout.fillHeight: true }

            // Güç modu
            Text { text: "POWER MODE"; color: "#7e8099"; font { pixelSize: 9; letterSpacing: 1.5; weight: Font.Medium } }

            RowLayout {
                spacing: 6
                Rectangle {
                    width: 7; height: 7; radius: 4; color: "#4ade80"
                    SequentialAnimation on opacity {
                        running: true; loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                    }
                }
                Text { text: powerMode; color: "#e8e9f5"; font { pixelSize: 13; weight: Font.SemiBold } }
            }
        }
    }
}
