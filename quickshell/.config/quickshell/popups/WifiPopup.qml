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
    property var theme: null
    property bool open: false

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    anchors.fill: parent

    // Popup açılınca ağ taraması başlat
    onVisibleChanged: { if (visible) NetworkService.scan() }

    // Popup arkaplanı
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgPopupBlur : "#202020"
        radius: theme ? theme.popupRadius : 12
        border.color: theme ? theme.border : "#323232"; border.width: 1
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
                    ? (theme ? theme.text : "#c5c5c5")
                    : (theme ? theme.textMuted : "#7e8099")
            }

            Text {
                text: {
                    if (!NetworkService.enabled) return "Wi-Fi Kapalı"
                    if (NetworkService.connectedSsid) return NetworkService.connectedSsid
                    return "Wi-Fi Açık"
                }
                color: NetworkService.enabled
                    ? (theme ? theme.text : "#c5c5c5")
                    : (theme ? theme.textMuted : "#7e8099")
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
                    ? (theme ? theme.active : "#b0b0b0")
                    : (theme ? theme.empty : "#414141")
                Rectangle {
                    x: NetworkService.enabled ? parent.width - width - 2 : 2; y: 2
                    width: 20; height: 20; radius: 10
                    color: NetworkService.enabled ? "#ffffff" : (theme ? theme.text : "#c5c5c5")
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
            color: theme ? theme.border : "#323232"
            opacity: 0.6
        }

        // Alt başlık
        Text {
            text: NetworkService.enabled ? "Ağlar" : "Wi-Fi kapalıyken ağlar gösterilmez"
            color: theme ? theme.textMuted : "#7e8099"
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
                        width: parent.width
                        implicitHeight: 36
                        radius: 6
                        color: modelData?.connected
                            ? (theme ? theme.hover : "#606060")
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
                                color: theme ? theme.text : "#c5c5c5"
                                font.pixelSize: 14
                                font.family: theme ? theme.fontFamily : "monospace"
                            }

                            // Ağ adı
                            Text {
                                text: modelData?.name ?? ""
                                color: modelData?.connected
                                    ? (theme ? theme.textBright : "#ffffff")
                                    : (theme ? theme.text : "#c5c5c5")
                                font.pixelSize: 12
                                font.family: theme ? theme.fontFamily : "monospace"
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // Bağlıysa yeşil nokta
                            Text {
                                text: modelData?.connected ? "\u25CF" : ""
                                color: theme ? theme.green : "#4ade80"
                                font.pixelSize: 10
                            }

                            // Bağlanma düğmesi (bağlı değilse)
                            Rectangle {
                                width: 28; height: 22; radius: 4
                                color: theme ? theme.hover : "#606060"
                                border.color: theme ? theme.border : "#323232"
                                border.width: 1
                                visible: !modelData?.connected

                                ColorizedIcon {
                                    anchors.centerIn: parent
                                    source: root._icon + "network-wireless-signal-excellent-symbolic.svg"
                                    iconSize: 10
                                    iconColor: theme ? theme.text : "#c5c5c5"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData) NetworkService.connectTo(modelData.name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
