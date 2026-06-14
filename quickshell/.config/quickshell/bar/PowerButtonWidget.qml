// ============================================================
// BAR GÜÇ DÜĞMESİ — sağda güç simgesi
// Tıklayınca güç menüsü popup'ını açar
// ============================================================
import QtQuick
import Quickshell
import qs.components

Item {
    id: root
    property var theme: null

    signal powerClicked()

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    height: 32
    width: powerInner.width + 16

    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgDark : "#202020"
        radius: 14
        border.color: theme ? theme.border : "#323232"
        border.width: 1

        Item {
            id: powerInner
            anchors.centerIn: parent
            width: 22
            height: 32

            ColorizedIcon {
                anchors.centerIn: parent
                source: root._icon + "system-shutdown-symbolic.svg"
                iconSize: 14
                iconColor: theme ? theme.text : "#c5c5c5"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: root.powerClicked()
            }
        }
    }
}
