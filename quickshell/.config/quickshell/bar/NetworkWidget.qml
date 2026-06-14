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
    property var theme: null

    signal wifiClicked()
    signal bluetoothClicked()

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    height: 32
    width: innerRow.width + 16

    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgDark : "#202020"
        radius: 14
        border.color: theme ? theme.border : "#323232"
        border.width: 1

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
                    iconColor: NetworkService.enabled && NetworkService.connectedSsid
                        ? (theme ? theme.text : "#c5c5c5")
                        : (theme ? theme.textMuted : "#7e8099")
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onPressed: root.wifiClicked()
                }
            }

            // Ayraç
            Item { width: 8; height: 32
                Rectangle { anchors.centerIn: parent; width: 1; height: 18; color: theme ? theme.border : "#323232"; opacity: 0.5 }
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
                    iconColor: theme ? theme.text : "#c5c5c5"
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onPressed: root.bluetoothClicked()
                }
            }
        }
    }
}
