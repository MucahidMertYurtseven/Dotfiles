// ============================================================
// BAR SİSTEM KAYNAK WIDGET'I — CPU, RAM, sıcaklık
// Değerler belirli eşiklerin üstündeyse kırmızı renk alır
// ============================================================
import QtQuick
import Quickshell
import qs.services
import qs.components

Rectangle {
    id: root
    property Item theme: null

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    height: 32
    implicitWidth: row.implicitWidth + 16
    visible: SystemService.ramUsed > 0

    color: theme ? theme.bgBar : "#7f31112d"
    radius: 14
    border.color: theme ? theme.border : "#6675376d"
    border.width: 1
    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        // CPU yükü
        Row {
            spacing: 4
            ColorizedIcon {
                source: root._icon + "computer-symbolic.svg"
                iconSize: 18
                iconColor: SystemService.cpuLoad > 80 ? (theme ? theme.warn : "#d09caa") : (theme ? theme.active : "#dda6d5")
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: Math.round(SystemService.cpuLoad) + "%"
                color: SystemService.cpuLoad > 80 ? (theme ? theme.warn : "#d09caa") : (theme ? theme.text : "#c6c2c5")
                font.pixelSize: 14; font.bold: true
                font.family: theme ? theme.fontFamily : "monospace"
            }
        }

        // RAM kullanımı
        Row {
            spacing: 4
            ColorizedIcon {
                source: root._icon + "drive-harddisk-symbolic.svg"
                iconSize: 18
                iconColor: SystemService.ramUsed > 0.8 ? (theme ? theme.warn : "#d09caa") : (theme ? theme.active : "#dda6d5")
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: Math.round(SystemService.ramUsed * 100) + "%"
                color: SystemService.ramUsed > 0.8 ? (theme ? theme.warn : "#d09caa") : (theme ? theme.text : "#c6c2c5")
                font.pixelSize: 14; font.bold: true
                font.family: theme ? theme.fontFamily : "monospace"
            }
        }

        // Sıcaklık
        Row {
            spacing: 4
            visible: SystemService.temp > 0
            ColorizedIcon {
                source: root._icon + "temperature-normal-symbolic.svg"
                iconSize: 18
                iconColor: SystemService.temp > 80 ? (theme ? theme.warn : "#d09caa") : (theme ? theme.active : "#dda6d5")
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: SystemService.temp + "\u00B0"
                color: SystemService.temp > 80 ? (theme ? theme.warn : "#d09caa") : (theme ? theme.text : "#c6c2c5")
                font.pixelSize: 14; font.bold: true
                font.family: theme ? theme.fontFamily : "monospace"
            }
        }
    }
}
