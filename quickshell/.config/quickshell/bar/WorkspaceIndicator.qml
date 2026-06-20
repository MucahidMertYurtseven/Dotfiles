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
    property Item theme: null

    height: 32
    width: wsRow.width + 24
    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    color: theme ? theme.bgBar : "#7f143630"
    radius: 14
    border.color: theme ? theme.border : "#6637756a"
    border.width: 1
    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }

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
                    ? (theme ? theme.active : "#a6ddd3")
                    : (isOccupied ? (theme ? theme.hover : "#53b6a4") : (theme ? theme.empty : "#33796d"))

                
                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
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
