// ============================================================
// BİLDİRİM POPUP'I — sağ üstte bildirim listesini gösterir
// ListModel'e bağlıdır, her bildirimi tek tek veya topluca
// temizleme imkanı sağlar.
// ============================================================
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.components

Item {
    id: root
    property var theme: null
    property bool open: false
    property bool dnd: false
    property var notificationModel: null     // shell.qml'deki ListModel
    signal toggleDnd()
    signal dismissNotif(int id)
    signal clearAll()                 // Tümünü temizle sinyali

    readonly property string _icon: Quickshell.shellDir + "/bar/icons/"

    // Popup arkaplanı
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgPopupBlur : "#202020"
        radius: theme ? theme.popupRadius : 12
        border.color: theme ? theme.border : "#323232"; border.width: 1
    }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: theme?.popupPad ?? 12 }
        spacing: 8

        // Header: ikon + başlık + Tümünü Temizle + DND toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Bildirim ikonu (DND / var / yok durumuna göre)
            ColorizedIcon {
                source: dnd ? root._icon + "notifications-disabled-symbolic.svg"
                    : (notificationModel && notificationModel.count > 0)
                        ? root._icon + "notifications-unread-symbolic.svg"
                        : root._icon + "notifications-symbolic.svg"
                iconSize: 18
                iconColor: dnd
                    ? (theme ? theme.warn : "#f38ba8")
                    : (theme ? theme.text : "#c5c5c5")
            }

            // Başlık
            Text {
                text: dnd ? "Rahatsız Etmeyin Açık" : "Bildirimler"
                color: theme ? theme.text : "#c5c5c5"
                font.pixelSize: 13
                font.bold: true
                font.family: theme ? theme.fontFamily : "monospace"
                Layout.fillWidth: true
            }

            // TÜMÜNÜ TEMİZLE butonu — modern pill tasarım
            Rectangle {
                id: clearAllBtn
                visible: notificationModel ? notificationModel.count > 0 : false
                implicitWidth: 28; height: 28; radius: 14
                color: clearAllMa.containsMouse
                    ? (theme ? theme.hover : "#606060")
                    : (theme ? theme.bgDark : "#202020")
                border.color: clearAllMa.containsMouse
                    ? (theme ? theme.textMuted : "#7e8099")
                    : (theme ? theme.border : "#323232")
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: clearAllMa.containsMouse
                        ? (theme ? theme.textBright : "#ffffff")
                        : (theme ? theme.textMuted : "#7e8099")
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: clearAllMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearAll()
                }
            }

            // DND toggle düğmesi
            Rectangle {
                width: 44; height: 24; radius: 12
                color: dnd ? (theme ? theme.warn : "#f38ba8") : (theme ? theme.empty : "#414141")
                Rectangle {
                    x: dnd ? parent.width - width - 2 : 2; y: 2
                    width: 20; height: 20; radius: 10
                    color: dnd ? "#ffffff" : (theme ? theme.text : "#c5c5c5")
                    Behavior on x { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleDnd()
                }
            }
        }

        // Ayraç çizgisi
        Rectangle {
            Layout.fillWidth: true; height: 1
            color: theme ? theme.border : "#323232"
            opacity: 0.6
        }

        // Bildirim listesi (kaydırılabilir)
        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.interactive: true

            Column {
                width: parent.width
                spacing: 6

                // Her bildirim için bir satır
                Repeater {
                    model: notificationModel

                    Rectangle {
                        id: notifItem
                        width: parent.width
                        implicitHeight: 54
                        radius: 6
                        color: ma.containsMouse
                            ? (theme ? theme.hover : "#606060")
                            : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            // Önem derecesi çizgisi (toast ile uyumlu)
                            Rectangle {
                                width: 3; height: parent.height; radius: 1.5
                                color: urgency === 2 ? (theme ? theme.warn : "#f38ba8")
                                     : urgency === 1 ? (theme ? theme.text : "#c5c5c5")
                                     : (theme ? theme.textMuted : "#7e8099")
                            }

                            // Bildirim içeriği: başlık + mesaj
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Text {
                                    text: summary || ""
                                    color: theme ? theme.textBright : "#ffffff"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: theme ? theme.fontFamily : "monospace"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: body || ""
                                    color: theme ? theme.text : "#c5c5c5"
                                    font.pixelSize: 10
                                    font.family: theme ? theme.fontFamily : "monospace"
                                    elide: Text.ElideRight
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    Layout.fillWidth: true
                                }
                            }

                            // Silme butonu (hover'da görünür)
                            Rectangle {
                                width: 22; height: 22; radius: 5
                                color: theme ? theme.hover : "#606060"
                                visible: ma.containsMouse
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    width: 12; height: 2; radius: 1
                                    anchors.centerIn: parent
                                    color: theme ? theme.text : "#c5c5c5"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        mouse.accepted = true
                                        root.dismissNotif(id)
                                    }
                                }
                            }
                        }

                        // Tüm satıra tıklayınca da sil
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton
                            onClicked: {
                                root.dismissNotif(id)
                            }
                        }
                    }
                }

                // Boş durum metni
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: notificationModel ? notificationModel.count === 0 : true
                    text: dnd ? "Bildirimler susturuldu" : "Bildirim yok"
                    color: theme ? theme.textMuted : "#7e8099"
                    font.pixelSize: 11
                    font.family: theme ? theme.fontFamily : "monospace"
                    topPadding: 8
                }
            }
        }
    }
}
