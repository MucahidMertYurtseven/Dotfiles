// ============================================================
// BLUETOOTH POPUP'I — bluetooth cihazlarını listeler
// bluetoothctl ile cihaz taraması ve bağlantı yönetimi
// ============================================================
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

Item {
    id: root
    property var theme: null
    property bool open: false

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    anchors.fill: parent

    property var _devices: []

    // Cihaz listesini yenile
    function _refresh() {
        listProc.running = true
    }

    // Bluetooth cihaza bağlan
    function _connect(mac) {
        connectProc.command = ["bluetoothctl", "connect", mac]
        connectProc.running = true
    }

    // Bluetooth bağlantıyı kes
    function _disconnect(mac) {
        connectProc.command = ["bluetoothctl", "disconnect", mac]
        connectProc.running = true
    }

    // Popup açılınca tara
    onVisibleChanged: { if (visible) _refresh() }

    // Cihaz listesini al
    Process {
        id: listProc
        command: ["bluetoothctl", "devices"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var m = line.match(/^Device\s+([0-9A-Fa-f:]+)\s+(.+)$/)
                if (m) {
                    var mac = m[1]
                    var name = m[2]
                    var exists = false
                    for (var i = 0; i < root._devices.length; i++) {
                        if (root._devices[i].mac === mac) { exists = true; break }
                    }
                    if (!exists) {
                        var devs = root._devices.slice()
                        devs.push({ mac: mac, name: name, connected: false })
                        root._devices = devs
                    }
                }
            }
        }
        onExited: { connectedProc.running = true }
    }

    // Bağlı cihazları işaretle
    Process {
        id: connectedProc
        command: ["bluetoothctl", "devices", "Connected"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var m = line.match(/^Device\s+([0-9A-Fa-f:]+)\s+(.+)$/)
                if (m) {
                    var cmac = m[1]
                    for (var i = 0; i < root._devices.length; i++) {
                        if (root._devices[i].mac === cmac) {
                            var devs = root._devices.slice()
                            devs[i] = Object.assign({}, devs[i], { connected: true })
                            root._devices = devs
                            break
                        }
                    }
                }
            }
        }
    }

    // Bağlan/kopar işlemi sonrası yenile
    Process {
        id: connectProc
        command: []
        running: false
        onExited: { Qt.callLater(_refresh) }
    }

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

        // Header: Bluetooth ikonu + durum + toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColorizedIcon {
                source: NetworkService.btEnabled
                    ? root._icon + "network-bluetooth-activated-symbolic.svg"
                    : root._icon + "network-bluetooth-inactive-symbolic.svg"
                iconSize: 16
                iconColor: theme ? theme.text : "#c5c5c5"
            }

            Text {
                text: NetworkService.btEnabled ? "Bluetooth Açık" : "Bluetooth Kapalı"
                color: NetworkService.btEnabled
                    ? (theme ? theme.text : "#c5c5c5")
                    : (theme ? theme.textMuted : "#7e8099")
                font.pixelSize: 13
                font.bold: true
                font.family: theme ? theme.fontFamily : "monospace"
                Layout.fillWidth: true
            }

            // Bluetooth toggle
            Rectangle {
                width: 44; height: 24; radius: 12
                color: NetworkService.btEnabled
                    ? (theme ? theme.active : "#b0b0b0")
                    : (theme ? theme.empty : "#414141")
                Rectangle {
                    x: NetworkService.btEnabled ? parent.width - width - 2 : 2; y: 2
                    width: 20; height: 20; radius: 10
                    color: NetworkService.btEnabled ? "#ffffff" : (theme ? theme.text : "#c5c5c5")
                    Behavior on x { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        NetworkService.btToggle()
                        if (!NetworkService.btEnabled) root._devices = []
                    }
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
            text: NetworkService.btEnabled ? "Eşleşmiş Cihazlar" : "Bluetooth kapalıyken cihazlar gösterilmez"
            color: theme ? theme.textMuted : "#7e8099"
            font.pixelSize: 10
            font.family: theme ? theme.fontFamily : "monospace"
        }

        // Cihaz listesi (kaydırılabilir)
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
                    model: NetworkService.btEnabled ? root._devices : []

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

                            // Bluetooth ikonu
                            ColorizedIcon {
                                source: modelData?.connected
                                    ? root._icon + "network-bluetooth-connected-symbolic.svg"
                                    : root._icon + "network-bluetooth-activated-symbolic.svg"
                                iconSize: 14
                                iconColor: modelData?.connected
                                    ? (theme ? theme.green : "#4ade80")
                                    : (theme ? theme.text : "#c5c5c5")
                            }

                            // Cihaz adı
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

                            // Bağlantı durumu
                            Text {
                                text: modelData?.connected ? "󰁨" : ""
                                color: theme ? theme.green : "#4ade80"
                                font.pixelSize: 12
                                font.family: theme ? theme.fontFamily : "monospace"
                            }

                            // Bağlan/kopar düğmesi
                            Rectangle {
                                width: 28; height: 22; radius: 4
                                color: theme ? theme.hover : "#606060"
                                border.color: theme ? theme.border : "#323232"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData?.connected ? "✕" : "󰁨"
                                    color: theme ? theme.text : "#c5c5c5"
                                    font.pixelSize: 10
                                    font.family: theme ? theme.fontFamily : "monospace"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData?.connected)
                                            root._disconnect(modelData.mac)
                                        else
                                            root._connect(modelData.mac)
                                    }
                                }
                            }
                        }
                    }
                }

                // Boş durum metni
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: NetworkService.btEnabled && root._devices.length === 0
                    text: "Eşleşmiş cihaz bulunamadı"
                    color: theme ? theme.textMuted : "#7e8099"
                    font.pixelSize: 11
                    font.family: theme ? theme.fontFamily : "monospace"
                    topPadding: 8
                }
            }
        }
    }
}
