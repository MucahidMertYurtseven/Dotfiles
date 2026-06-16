// ============================================================
// TAKVİM POPUP'I — canlı saat, tarih ve ay takvimi
// Her saniye güncellenir, güncel günü vurgular
// ============================================================
import QtQuick
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property Item theme: null
    property bool open: false

    anchors.fill: parent

    property var _now: new Date()

    // Her saniye zamanı güncelle
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root._now = new Date()
    }

    // Popup arkaplanı
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgPopupBlur : "#8c0c1a33"
        radius: theme ? theme.popupRadius : 12
        border.color: theme ? theme.border : "#66374d75"; border.width: 1
    }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: theme?.popupPad ?? 12 }
        spacing: 6

        // Canlı saat
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                var d = root._now
                var h = d.getHours().toString().padStart(2, "0")
                var m = d.getMinutes().toString().padStart(2, "0")
                var s = d.getSeconds().toString().padStart(2, "0")
                return h + ":" + m + ":" + s
            }
            color: theme ? theme.textBright : "#f7f7f7"
            font.pixelSize: 28
            font.bold: true
            font.family: theme ? theme.fontFamily : "monospace"
        }

        // Tarih
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                var d = root._now
                var months = ["Ocak","Şubat","Mart","Nisan","Mayıs","Haziran","Temmuz","Ağustos","Eylül","Ekim","Kasım","Aralık"]
                return d.getDate() + " " + months[d.getMonth()] + " " + d.getFullYear()
            }
            color: theme ? theme.textMuted : "#7f95bc"
            font.pixelSize: 14
            font.family: theme ? theme.fontFamily : "monospace"
        }

        // Ayraç
        Rectangle {
            Layout.fillWidth: true; height: 1
            color: theme ? theme.border : "#66374d75"
            opacity: 0.6
            Layout.topMargin: 2; Layout.bottomMargin: 2
        }

        // Gün başlıkları (Pzt-Paz)
        RowLayout {
            id: dayHeader
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: ["Pzt","Sal","Çar","Per","Cum","Cmt","Paz"]
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: theme ? theme.textMuted : "#7f95bc"
                    font.pixelSize: 10
                    font.family: theme ? theme.fontFamily : "monospace"
                }
            }
        }

        // Takvim günleri
        GridLayout {
            id: dayGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 2; columnSpacing: 0

            Repeater {
                model: {
                    var now = root._now
                    var first = new Date(now.getFullYear(), now.getMonth(), 1)
                    var startDay = first.getDay() === 0 ? 6 : first.getDay() - 1
                    var daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
                    var cells = []
                    for (var i = 0; i < startDay; i++) cells.push(0)
                    for (var d = 1; d <= daysInMonth; d++) cells.push(d)
                    return cells
                }

                Item {
                    implicitHeight: 28
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Bugün vurgusu
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(26, parent.width - 2)
                        height: Math.min(26, parent.height - 2)
                        radius: Math.min(width, height) / 2
                        visible: modelData > 0 && modelData === root._now.getDate()
                        color: theme ? theme.active : "#a6badd"
                    }

                    // Gün numarası
                    Text {
                        anchors.centerIn: parent
                        text: modelData > 0 ? modelData.toString() : ""
                        color: modelData > 0 && modelData === root._now.getDate()
                            ? "#000000"
                            : (theme ? theme.text : "#c2c3c6")
                        font.pixelSize: 12
                        font.family: theme ? theme.fontFamily : "monospace"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
