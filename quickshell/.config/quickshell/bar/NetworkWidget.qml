// ============================================================
// BAR AĞ WIDGET'I — Wi-Fi ve Bluetooth ikonları
// Tıklanınca ilgili popup'ı açar
// ============================================================
import QtQuick
import Quickshell
import qs.services
import qs.components

Item {
    id: root
    property Item theme: null

    signal wifiClicked()
    signal bluetoothClicked()

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    height: 32
    width: innerRow.width + 16

    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgBar : "#7f31112d"
        radius: 14
        border.color: theme ? theme.border : "#6675376d"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Row {
            id: innerRow
            anchors.centerIn: parent
            spacing: 0

            // Wi-Fi ikonu
            Item {
                width: 24; height: 32
                ColorizedIcon {
                    anchors.centerIn: parent
                    source: NetworkService.enabled && NetworkService.connectedSsid
                        ? root._icon + "network-wireless-signal-excellent-symbolic.svg"
                        : root._icon + "network-wireless-signal-none-symbolic.svg"
                    iconSize: 16
                    iconColor: theme ? theme.active : "#dda6d5"
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                    onClicked: root.wifiClicked()
                }
            }

            // Ayraç
            Item { width: 8; height: 32
                Rectangle { anchors.centerIn: parent; width: 1; height: 18; color: theme ? theme.border : "#6675376d"; opacity: 0.5 }
            }

            // Bluetooth ikonu
            Item {
                width: 28; height: 32
                ColorizedIcon {
                    anchors.centerIn: parent
                    source: NetworkService.btEnabled
                        ? root._icon + "network-bluetooth-activated-symbolic.svg"
                        : root._icon + "network-bluetooth-inactive-symbolic.svg"
                    iconSize: 18
                    iconColor: theme ? theme.active : "#dda6d5"
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                    onClicked: root.bluetoothClicked()
                }
            }
        }
    }
}
