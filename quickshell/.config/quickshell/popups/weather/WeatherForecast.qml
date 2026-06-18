import QtQuick
import QtQuick.Layouts
import qs.services

Rectangle {
    id: root
    property Item theme: null

    Layout.fillWidth: true
    implicitHeight: forecastCol.implicitHeight + 32
    radius: 16
    color: theme ? theme.bgPopup : "#cc131b2e"
    border.color: theme ? theme.border : "#1affffff"; border.width: 1

    ColumnLayout {
        id: forecastCol
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        RowLayout {
            spacing: 6
            Text { text: "calendar_month"; font.family: "Material Symbols Outlined"; color: theme ? theme.text : "#9ca3af"; font.pixelSize: 12 }
            Text { text: "3 GÜNLÜK TAHMİN"; color: theme ? theme.text : "#9ca3af"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.0 }
        }

        Repeater {
            model: WeatherService.forecast

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.preferredWidth: 64
                    text: index === 0 ? "Bugün" : index === 1 ? "Yarın" : WeatherService.getDayName(modelData.date)
                    color: theme ? theme.text : "#9ca3af"
                    font.pixelSize: 14
                    font.family: "Inter"
                }

                Text {
                    text: modelData.materialIcon || "cloud"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                    color: theme ? theme.active : "#f7f7f7"
                }

                Text {
                    Layout.preferredWidth: 28
                    horizontalAlignment: Text.AlignRight
                    text: modelData.min + "°"
                    color: theme ? theme.text : "#9ca3af"
                    font.pixelSize: 14
                    font.family: "Inter"
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 4
                    radius: 2
                    color: "#1affffff"
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 0.6
                        height: 4
                        radius: 2
                        color: theme ? theme.active : "#f7f7f7"
                    }
                }

                Text {
                    Layout.preferredWidth: 28
                    text: modelData.max + "°"
                    color: theme ? theme.textBright : "#ffffff"
                    font.bold: true
                    font.pixelSize: 14
                    font.family: "Inter"
                }
            }
        }
    }
}
