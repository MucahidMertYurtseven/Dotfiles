// ============================================================
// GÜÇ MENÜSÜ POPUP'I — kilit, uyku, yeniden başlat, kapat
// Her öğe tıklanınca ilgili sistem komutunu çalıştırır
// ============================================================
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components

Item {
    id: root
    property Item theme: null
    property bool open: false

    anchors.fill: parent

    // Popup arkaplanı
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgPopupBlur : "#b2143630"
        radius: theme ? theme.popupRadius : 12
        border.color: theme ? theme.border : "#6637756a"; border.width: 1
    }

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    ColumnLayout {
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: theme?.popupPad ?? 12 }
        spacing: 6

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColorizedIcon {
                source: root._icon + "system-shutdown-symbolic.svg"
                iconSize: 16
                iconColor: theme ? theme.textMuted : "#7fbcb1"
            }

            Text {
                text: "Sistem"
                color: theme ? theme.textMuted : "#7fbcb1"
                font.pixelSize: 10
                font.family: theme ? theme.fontFamily : "monospace"
                font.bold: true
                Layout.fillWidth: true
            }
        }

        // Ayraç
        Rectangle {
            Layout.fillWidth: true; height: 1
            color: theme ? theme.border : "#6637756a"
            opacity: 0.6
        }

        // Güç eylemleri
        Repeater {
            model: [
                { icon: "system-lock-screen-symbolic.svg", label: "Kilit", cmd: "/home/mert/.config/quickshell/lockscreen/lock.sh" },
                { icon: "system-suspend-symbolic.svg", label: "Uyku", cmd: "systemctl suspend" },
                { icon: "system-reboot-symbolic.svg", label: "Yeniden Başlat", cmd: "systemctl reboot" },
                { icon: "system-shutdown-symbolic.svg", label: "Kapat", cmd: "systemctl poweroff" }
            ]

            // Her eylem için bir satır
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: 6
                color: ma.containsMouse ? (theme ? theme.hover : "#53b6a4") : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10; anchors.rightMargin: 10
                    spacing: 10

                    ColorizedIcon {
                        source: root._icon + modelData.icon
                        iconSize: 20
                        iconColor: theme ? theme.text : "#c2c6c5"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: modelData.label
                        color: theme ? theme.text : "#c2c6c5"
                        font.pixelSize: 13
                        font.family: theme ? theme.fontFamily : "monospace"
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "›"
                        color: theme ? theme.textMuted : "#7fbcb1"
                        font.pixelSize: 18
                        font.family: theme ? theme.fontFamily : "monospace"
                        Layout.alignment: Qt.AlignVCenter
                        visible: ma.containsMouse
                    }
                }

                property bool containsMouse: false
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: parent.containsMouse = true
                    onExited: parent.containsMouse = false
                    onClicked: {
                        actionProc.command = ["sh", "-c", modelData.cmd]
                        actionProc.running = true
                    }
                }
            }
        }
    }

    // Eylemleri çalıştırmak için process
    Process {
        id: actionProc
        command: []
        running: false
    }
}
