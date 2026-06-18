// ============================================================
// BAR HAVA DURUMU WIDGET'I — Güncel sıcaklık ve ikon
// Tıklanınca hava durumu detaylarını içeren popup'ı açar
// ============================================================
import QtQuick
import Quickshell
import qs.services
import qs.components

Rectangle {
    id: root
    property Item theme: null

    signal clicked()

    height: 32
    implicitWidth: row.implicitWidth + 24

    color: theme ? theme.bgBar : "#7f31112d"
    radius: 14
    border.color: theme ? theme.border : "#6675376d"
    border.width: 1
    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherService.materialIcon
            font.family: "Material Symbols Outlined"
            font.pixelSize: 18
            color: theme ? theme.active : "#dda6d5"
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherService.temp + "\u00B0"
            color: theme ? theme.text : "#c6c2c5"
            font.pixelSize: 14; font.bold: true
            font.family: theme ? theme.fontFamily : "monospace"
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
