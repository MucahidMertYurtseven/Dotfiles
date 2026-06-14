// ============================================================
// BAR ÇALIŞMA ALANI GÖSTERGESİ — Hyprland workspace'leri
// 10 adet çalışma alanını gösterir, aktif/boş/dolu durumuna
// göre farklı renk ve boyutta görünür
// ============================================================
import Quickshell
import Quickshell.Hyprland
import QtQuick

Rectangle {
    id: root
    property var theme: null

    height: 32
    width: wsRow.width + 24
    Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutBack; easing.overshoot: 2.8 } }
    color: theme ? theme.bgDark : "#202020"
    radius: 14
    border.color: theme ? theme.border : "#323232"
    border.width: 1

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: 10

        // 1-10 arası çalışma alanı
        Repeater {
            model: 10

            Rectangle {
                property int wsId: index + 1
                property bool isActive: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
                property var wsInfo: Hyprland.workspaces.values ? Hyprland.workspaces.values.find(w => w.id === wsId) : undefined
                property bool isOccupied: wsInfo !== undefined

                width: isActive ? 28 : 10   // aktif olan daha geniş
                height: 10
                radius: 5
                color: isActive
                    ? (theme ? theme.active : "#b0b0b0")
                    : (isOccupied
                        ? (theme ? theme.hover : "#606060")
                        : (theme ? theme.empty : "#414141"))

                Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutBack; easing.overshoot: 2.8 } }
                Behavior on color { ColorAnimation { duration: 200 } }

                // Tıklayınca o workspace'e git
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (Hyprland.usingLua)
                            Hyprland.dispatch('hl.dsp.focus({ workspace = "' + wsId + '" })')
                        else
                            Hyprland.dispatch("workspace " + wsId)
                    }
                }
            }
        }
    }
}
