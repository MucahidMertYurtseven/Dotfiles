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
    property var theme: null

    signal notifyClicked()

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    height: 32
    width: notifInner.width + 16

    // Bar modülü arkaplanı
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgDark : "#202020"
        radius: 14
        border.color: theme ? theme.border : "#323232"
        border.width: 1

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
                    ? (theme ? theme.warn : "#f38ba8")
                    : (theme ? theme.text : "#c5c5c5")
            }

            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onPressed: root.notifyClicked()
            }
        }
    }
}
