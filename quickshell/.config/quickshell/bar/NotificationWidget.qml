// ============================================================
// BAR BİLDİRİM İKONU — sağ üstte bildirim çanı
// DND, okunmamış bildirim veya boş durumuna göre ikon değişir
// Tıklanınca bildirim popup'ını açar
// ============================================================
import QtQuick
import Quickshell
import qs.services
import qs.components

Item {
    id: root
    property Item theme: null

    signal notifyClicked()

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    height: 32
    width: notifInner.width + 16

    // Bar modülü arkaplanı
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgBar : "#7f0c1a33"
        radius: 14
        border.color: theme ? theme.border : "#66343434"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Item {
            id: notifInner
            anchors.centerIn: parent
            width: 28
            height: 32

            // Duruma göre ikon: DND / var / yok
            ColorizedIcon {
                anchors.centerIn: parent
                source: AppState.dndEnabled ? root._icon + "notifications-disabled-symbolic.svg"
                    : AppState.hasNotifs ? root._icon + "notifications-unread-symbolic.svg"
                    : root._icon + "notifications-symbolic.svg"
                iconSize: 18
                iconColor: AppState.dndEnabled
                    ? (theme ? theme.warn : "#d09caa")
                    : (theme ? theme.active : "#a6badd")
            }

            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                onClicked: root.notifyClicked()
            }
        }
    }
}
