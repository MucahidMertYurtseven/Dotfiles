// ============================================================
// BAR GÜÇ DÜĞMESİ — sağda güç simgesi
// Tıklayınca güç menüsü popup'ını açar
// ============================================================
import QtQuick
import Quickshell
import qs.components

Item {
    id: root
    property Item theme: null

    signal powerClicked()

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    height: 32
    width: powerInner.width + 16

    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgBar : "#7f0c1a33"
        radius: 14
        border.color: theme ? theme.border : "#66343434"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Item {
            id: powerInner
            anchors.centerIn: parent
            width: 22
            height: 32

            ColorizedIcon {
                anchors.centerIn: parent
                source: root._icon + "system-shutdown-symbolic.svg"
                iconSize: 14
                iconColor: theme ? theme.active : "#a6badd"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.powerClicked()
            }
        }
    }
}
