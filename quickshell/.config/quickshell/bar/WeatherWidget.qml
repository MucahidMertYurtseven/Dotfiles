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
    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    height: 32
    implicitWidth: row.implicitWidth + 24

    color: theme ? theme.bgBar : "#7f143630"
    radius: 14
    border.color: theme ? theme.border : "#6637756a"
    border.width: 1
    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        ColorizedIcon {
            anchors.verticalCenter: parent.verticalCenter
            source: root._icon + "weather/" + WeatherService.icon
            iconSize: 18
            iconColor: theme ? theme.active : "#a6ddd3"
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: WeatherService.temp + "\u00B0"
            color: theme ? theme.text : "#c2c6c5"
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
