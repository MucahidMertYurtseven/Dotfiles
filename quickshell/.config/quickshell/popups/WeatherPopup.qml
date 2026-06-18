import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import qs.services
import Quickshell
import Quickshell.Wayland
import "./weather"

Item {
    id: root
    property Item theme: null
    property bool open: false

    implicitWidth: popupItem.width
    implicitHeight: popupItem.height

    function updateSize() {
        if (popupItem) {
            root.implicitWidth = popupItem.width
            root.implicitHeight = popupItem.height
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (popupItem.width !== root.implicitWidth || popupItem.height !== root.implicitHeight) {
                root.updateSize()
            }
        }
    }

    Rectangle {
        id: popupItem
        width: 620
        implicitHeight: Math.min(650, mainLayout.implicitHeight + 0)
        color: theme ? theme.bgPopupBlur : "#b231112d"
        radius: theme ? theme.popupRadius : 24
        border.color: theme ? theme.border : "#6675376d"
        border.width: 1
        clip: true

        RowLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            // ==========================================
            // SOL SÜTUN: Genel Durum ve Döngüler (%40)
            // ==========================================
            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width * 0.44

                Rectangle {
                    anchors.fill: parent
                    color: "#0cffffff"
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 8

                    WeatherHeader {
                        theme: root.theme
                    }

                    Item { Layout.fillHeight: true }

                    WeatherMoonCycle {
                        theme: root.theme
                        Layout.fillWidth: true
                    }
                }
            }

            // ==========================================
            // SAĞ SÜTUN: Detaylar ve Tahmin (%60)
            // ==========================================
            ScrollView {
                id: rightScrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    id: rightContent
                    width: rightScrollView.availableWidth
                    spacing: 8

                    Item { Layout.preferredHeight: 12 } // top margin equiv

                    WeatherForecast {
                        theme: root.theme
                        Layout.fillWidth: true
                        Layout.rightMargin: 20
                        Layout.leftMargin: 20
                    }

                    WeatherDetailsGrid {
                        theme: root.theme
                        Layout.fillWidth: true
                        Layout.rightMargin: 20
                        Layout.leftMargin: 20
                    }
                    
                    Item { Layout.preferredHeight: 12 } // bottom margin equiv
                }
            }
        }
    }
}
