import QtQuick
import QtQuick.Layouts
import qs.services

GridLayout {
    id: root
    property Item theme: null

    Layout.fillWidth: true
    columns: 2
    columnSpacing: 12
    rowSpacing: 12

    function getWindAngle(dirStr) {
        if (!dirStr) return 0;
        var map = {
            "Kuzey": 0, "Kuzey Kuzeydoğu": 22.5, "Kuzeydoğu": 45, "Doğu Kuzeydoğu": 67.5,
            "Doğu": 90, "Doğu Güneydoğu": 112.5, "Güneydoğu": 135, "Güney Güneydoğu": 157.5,
            "Güney": 180, "Güney Güneybatı": 202.5, "Güneybatı": 225, "Batı Güneybatı": 247.5,
            "Batı": 270, "Batı Kuzeybatı": 292.5, "Kuzeybatı": 315, "Kuzey Kuzeybatı": 337.5,
            "N": 0, "NNE": 22.5, "NE": 45, "ENE": 67.5,
            "E": 90, "ESE": 112.5, "SE": 135, "SSE": 157.5,
            "S": 180, "SSW": 202.5, "SW": 225, "WSW": 247.5,
            "W": 270, "WNW": 292.5, "NW": 315, "NNW": 337.5
        };
        return map[dirStr] !== undefined ? map[dirStr] : (map[dirStr.toUpperCase()] || 0);
    }

    component WeatherCard: Rectangle {
        property string iconName
        property string title
        property string mainValue
        property string mainValueUnit
        property string subValueText
        property string descText
        property int descFontSize: 10
        property int descAlignment: Text.AlignTop
        property int subValueFontSize: 14
        property bool subValueFontBold: true
        property bool isValueBold: true
        property bool showCompass: false

        property real barProgress: -1
        property string barColor1: "#4ade80"
        property string barColor2: "#f97316"

        Layout.fillWidth: true
        Layout.preferredHeight: 135
        radius: 16
        color: theme ? theme.bgPopup : "#cc131b2e"
        border.color: theme ? theme.border : "#1affffff"; border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 14
            anchors.bottomMargin: 30 // Alt yazı için yer bırak
            spacing: 4

            RowLayout {
                spacing: 4
                Layout.fillWidth: true
                Text { text: iconName; font.family: "Material Symbols Outlined"; color: theme ? theme.text : "#9ca3af"; font.pixelSize: 12 }
                Text { 
                    text: title
                    color: theme ? theme.text : "#9ca3af"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 0.5
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillHeight: true }

            // Normal Card Value
            RowLayout {
                visible: !showCompass
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: mainValue
                    color: theme ? theme.textBright : "#ffffff"
                    font.pixelSize: 24
                    font.bold: isValueBold
                    font.family: "Inter"
                }
                
                Text {
                    visible: mainValueUnit !== ""
                    text: mainValueUnit
                    color: theme ? theme.text : "#9ca3af"
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignBottom | Qt.AlignLeft
                    Layout.bottomMargin: 2
                }
            }

            Text {
                visible: !showCompass && subValueText !== ""
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                text: subValueText
                color: theme ? theme.active : "#38bdf8"
                font.pixelSize: subValueFontSize
                font.bold: subValueFontBold
                font.family: "Inter"
            }

            // Wind Compass Card Logic
            RowLayout {
                visible: showCompass
                Layout.fillWidth: true
                Layout.topMargin: 14
                spacing: 12
                
                Item {
                    Layout.topMargin: 4
                    width: 48; height: 48
                    Rectangle {
                        anchors.fill: parent; radius: 24; color: "transparent"
                        border.color: theme ? theme.border : "#1affffff"; border.width: 2
                        Rectangle { anchors.fill: parent; anchors.margins: 4; radius: 20; color: "#1affffff" }
                        Text { text: "K"; font.pixelSize: 10; color: "#66ffffff"; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "G"; font.pixelSize: 10; color: "#66ffffff"; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "D"; font.pixelSize: 10; color: "#66ffffff"; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "B"; font.pixelSize: 10; color: "#66ffffff"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: "navigation"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: theme ? theme.textBright : "#ffffff"
                            anchors.centerIn: parent
                            rotation: root.getWindAngle(WeatherService.windDir)
                        }
                    }
                }
                ColumnLayout {
                    Layout.topMargin: 8
                    spacing: 0
                    RowLayout {
                        Text { text: WeatherService.windSpeed; color: theme ? theme.textBright : "#ffffff"; font.pixelSize: 24; font.bold: true; font.family: "Inter" }
                        Text { text: "km/s"; color: theme ? theme.text : "#9ca3af"; font.pixelSize: 12; Layout.alignment: Qt.AlignBottom | Qt.AlignLeft; Layout.bottomMargin: 3 }
                    }
                    Text { text: WeatherService.windDir; color: theme ? theme.text : "#9ca3af"; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true; elide: Text.ElideRight }
                }
            }

            Item { Layout.fillHeight: true }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                
                Item {
                    visible: barProgress >= 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    Layout.bottomMargin: 2
                    Rectangle {
                        anchors.fill: parent
                        radius: 2
                        color: "#1affffff"
                        clip: true
                        Rectangle {
                            height: parent.height
                            width: parent.width * Math.min(1.0, Math.max(0.0, barProgress / 100.0))
                            radius: 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: barColor1 }
                                GradientStop { position: 1.0; color: barColor2 }
                            }
                        }
                    }
                }

            }
        }

        // Kartın Altına Sabitlenmiş Açıklama Yazısı
        Text {
            visible: descText !== ""
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 8 // Kutunun alt sınırından 8px yukarıda
            text: descText
            color: theme ? theme.text : "#9ca3af"
            font.pixelSize: descFontSize
            font.family: "Inter"
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            verticalAlignment: Text.AlignBottom
            horizontalAlignment: Text.AlignLeft
        }
    }

    WeatherCard {
        iconName: "device_thermostat"
        title: "HİSSEDİLEN"
        mainValue: WeatherService.feelsLikeFormatted
        descText: WeatherService.feelsLikeDesc
    }

    WeatherCard {
        iconName: "light_mode"
        title: "UV İNDEKSİ"
        mainValue: WeatherService.uvIndex
        subValueText: {
            var val = parseInt(WeatherService.uvIndex);
            if (isNaN(val)) return "";
            if (val <= 2) return "Düşük";
            if (val <= 5) return "Orta";
            if (val <= 7) return "Yüksek";
            if (val <= 10) return "Çok Yüksek";
            return "Aşırı";
        }
        descText: WeatherService.uvDesc
        descAlignment: Text.AlignTop
        barProgress: {
            var val = parseInt(WeatherService.uvIndex);
            return isNaN(val) ? 0 : Math.min((val / 11.0) * 100, 100);
        }
        barColor1: "#4ade80"
        barColor2: "#f97316"
    }

    WeatherCard {
        showCompass: true
        iconName: "air"
        title: "RÜZGAR"
        mainValue: ""
        descText: ""
    }

    WeatherCard {
        iconName: "visibility"
        title: "GÖRÜŞ MESAFESİ"
        mainValue: WeatherService.visibility
        mainValueUnit: "km"
        descText: WeatherService.visibilityDesc
    }

    WeatherCard {
        iconName: "water_drop"
        title: "YAĞIŞ İHTİMALİ"
        mainValue: WeatherService.rainChanceFormatted
        subValueText: WeatherService.rainLevel
        descText: WeatherService.rainDesc
        descAlignment: Text.AlignTop
        barProgress: parseInt(WeatherService.rainChance) || 0
        barColor1: "#3b82f6"
        barColor2: "#60a5fa"
    }

    WeatherCard {
        iconName: "humidity_percentage"
        title: "NEM ORANI"
        mainValue: "%" + WeatherService.humidity
        subValueText: WeatherService.dewPointFormatted
        subValueFontSize: 12
        subValueFontBold: false
        descText: WeatherService.humidityDesc
    }
}
