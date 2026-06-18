import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root
    property Item theme: null

    Layout.fillWidth: true
    implicitHeight: 130

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        Text {
            text: WeatherService.city
            color: theme ? theme.textBright : "#ffffff"
            font.pixelSize: 24
            font.bold: true
            font.family: "Inter"
        }

        Text {
            text: "Şehri Değiştir"
            color: theme ? theme.text : "#87929a"
            font.pixelSize: 12
            font.family: "Inter"
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 12

            Text {
                text: WeatherService.tempFormatted
                color: theme ? theme.active : "#f7f7f7"
                font.pixelSize: 64
                font.bold: true
                font.family: "Inter"
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    spacing: 4
                    Text {
                        text: WeatherService.materialIcon
                        font.family: "Material Symbols Outlined"
                        color: theme ? theme.active : "#f7f7f7"
                        font.pixelSize: 24
                    }
                    Text {
                        text: WeatherService.desc
                        color: theme ? theme.textBright : "#ffffff"
                        font.pixelSize: 18
                        font.bold: true
                        font.family: "Inter"
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                    }
                }
                Text {
                    text: WeatherService.forecastMinMax
                    color: theme ? theme.text : "#9ca3af"
                    font.pixelSize: 11
                    font.family: "Inter"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: WeatherService.changeCity()
    }
}
