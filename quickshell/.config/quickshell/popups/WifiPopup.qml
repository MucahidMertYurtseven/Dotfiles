// ============================================================
// WI-FI POPUP'I — kablosuz ağ tarama ve bağlanma
// NetworkService üzerinden nmcli ile ağları listeler
// ============================================================
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

Item {
    id: root
    property Item theme: null
    property bool open: false

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    anchors.fill: parent

    // Popup açılınca ağ taraması başlat
    onVisibleChanged: { if (visible) NetworkService.scan() }

    // Popup arkaplanı
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgPopupBlur : "#b2143630"
        radius: theme ? theme.popupRadius : 12
        border.color: theme ? theme.border : "#6637756a"; border.width: 1
        clip: true
    }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: theme?.popupPad ?? 12 }
        spacing: 8

        // Header: Wi-Fi ikonu + durum + toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColorizedIcon {
                source: NetworkService.enabled
                    ? root._icon + "network-wireless-signal-excellent-symbolic.svg"
                    : root._icon + "network-wireless-signal-none-symbolic.svg"
                iconSize: 18
                iconColor: NetworkService.enabled
                    ? (theme ? theme.text : "#c2c6c5")
                    : (theme ? theme.textMuted : "#7fbcb1")
            }

            Text {
                text: {
                    if (!NetworkService.enabled) return "Wi-Fi Kapalı"
                    if (NetworkService.connectedSsid) return NetworkService.connectedSsid
                    return "Wi-Fi Açık"
                }
                color: NetworkService.enabled
                    ? (theme ? theme.text : "#c2c6c5")
                    : (theme ? theme.textMuted : "#7fbcb1")
                font.pixelSize: 13
                font.bold: true
                font.family: theme ? theme.fontFamily : "monospace"
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Wi-Fi toggle düğmesi
            Rectangle {
                width: 44; height: 24; radius: 12
                color: NetworkService.enabled
                    ? (theme ? theme.active : "#a6ddd3")
                    : (theme ? theme.empty : "#33796d")
                Rectangle {
                    x: NetworkService.enabled ? parent.width - width - 2 : 2; y: 2
                    width: 20; height: 20; radius: 10
                    color: NetworkService.enabled ? "#ffffff" : (theme ? theme.text : "#c2c6c5")
                    Behavior on x { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NetworkService.toggle()
                }
            }
        }

        // Ayraç
        Rectangle {
            Layout.fillWidth: true; height: 1
            color: theme ? theme.border : "#6637756a"
            opacity: 0.6
        }

        // Alt başlık
        Text {
            text: NetworkService.enabled ? "Ağlar" : "Wi-Fi kapalıyken ağlar gösterilmez"
            color: theme ? theme.textMuted : "#7fbcb1"
            font.pixelSize: 10
            font.family: theme ? theme.fontFamily : "monospace"
        }

        // Ağ listesi (kaydırılabilir)
        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.interactive: true

            Column {
                width: parent.width
                spacing: 4

                Repeater {
                    model: NetworkService.enabled ? NetworkService.networks : []

                    Rectangle {
                        id: wifiItem
                        width: parent.width
                        implicitHeight: 36
                        radius: 6
                        color: modelData?.connected || wifiHover.containsMouse
                            ? (theme ? theme.hover : "#53b6a4")
                            : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            spacing: 8

                            // Sinyal gücü ikonu
                            Text {
                                text: {
                                    var sig = modelData?.signalStrength ?? 0
                                    if (sig > 75) return "󰤨"
                                    if (sig > 50) return "󰤥"
                                    if (sig > 25) return "󰤢"
                                    return "󰤟"
                                }
                                color: theme ? theme.text : "#c2c6c5"
                                font.pixelSize: 14
                                font.family: theme ? theme.fontFamily : "monospace"
                            }

                            // Ağ adı
                            Text {
                                text: modelData?.name ?? ""
                                color: modelData?.connected
                                    ? (theme ? theme.textBright : "#f7f7f7")
                                    : (theme ? theme.text : "#c2c6c5")
                                font.pixelSize: 12
                                font.family: theme ? theme.fontFamily : "monospace"
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // Bağlıysa yeşil nokta
                            Text {
                                text: modelData?.connected ? "\u25CF" : ""
                                color: theme ? theme.green : "#78c293"
                                font.pixelSize: 10
                            }
                        }

                        MouseArea {
                            id: wifiHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData && !modelData.connected)
                                    NetworkService.connectTo(modelData.name)
                            }
                        }
                    }
                }
            }
        }
    }
}
