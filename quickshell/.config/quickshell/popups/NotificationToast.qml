// ============================================================
// BİLDİRİM TOAST'I — sağ üstte kısa süreli bildirim balonu
// 7 saniye sonra veya tıklanınca otomatik kaybolur
// Üzerine gelince timer durur, böylece kullanıcı okuyabilir
// ============================================================
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components

Item {
    id: root
    property Item theme: null
    property int notifId: -1
    property string summary: ""
    property string body: ""
    property int urgency: 0

    signal dismissed(int id)
    signal clicked(int id)

    width: 320
    height: Math.max(58, col.implicitHeight + 20)
    Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

    // Giriş animasyonu: scale bounce + opacity fade
    SequentialAnimation {
        id: enterAnim
        running: true
        PropertyAction { target: root; property: "scale"; value: 0.8 }
        PropertyAction { target: root; property: "opacity"; value: 0 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "scale"; duration: 350; to: 1; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "opacity"; duration: 450; to: 1; easing.type: Easing.OutCubic }
        }
        ScriptAction { script: dismissTimer.restart() }
    }

    // Çıkış animasyonu: scale + fade
    SequentialAnimation {
        id: exitAnim
        running: false
        ParallelAnimation {
            NumberAnimation { target: root; property: "scale"; duration: 450; to: 0.8; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "opacity"; duration: 450; to: 0; easing.type: Easing.OutCubic }
        }
        ScriptAction { script: root.dismissed(root.notifId) }
    }

    // Çıkışı başlat (manuel)
    function startExit() {
        if (exitAnim.running) return
        dismissTimer.stop()
        exitAnim.restart()
    }

    // 7 saniye sonra otomatik kaybol
    Timer {
        id: dismissTimer
        interval: 7000
        running: false
        repeat: false
        onTriggered: root.startExit()
    }

    // Bildirime tıklayınca bildirim popup'ını aç
    MouseArea {
        id: toastMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { root.clicked(root.notifId); root.startExit() }
        onEntered: dismissTimer.stop()      // okurken timer dursun
        onExited: dismissTimer.restart()    // çıkınca timer devam
    }

    // Toast arkaplanı
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: theme ? theme.bgPopupBlur : "#b2143630"
        border.color: theme ? theme.border : "#6637756a"; border.width: 1
    }

    // İçerik
    RowLayout {
        id: col
        anchors { fill: parent; margins: 8 }
        spacing: 8

        // Önem derecesi çizgisi
        Rectangle {
            width: 3; height: parent.height; radius: 1.5
            color: urgency === 2 ? (theme ? theme.warn : "#d09caa")
                 : urgency === 1 ? (theme ? theme.text : "#c2c6c5")
                 : (theme ? theme.textMuted : "#7fbcb1")
        }

        // Başlık + mesaj
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            Text {
                text: root.summary
                color: theme ? theme.textBright : "#f7f7f7"
                font.pixelSize: 11
                font.bold: true
                font.family: theme ? theme.fontFamily : "monospace"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.body
                color: theme ? theme.text : "#c2c6c5"
                font.pixelSize: 10
                font.family: theme ? theme.fontFamily : "monospace"
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                maximumLineCount: 1
                Layout.fillWidth: true
            }
        }

        // Kapatma butonu (cercevesiz, hep görünür)
        Item {
            width: 16; height: 22
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: 10; height: 2; radius: 1
                anchors.centerIn: parent
                color: theme ? theme.text : "#c2c6c5"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    mouse.accepted = true
                    root.startExit()
                }
            }
        }

    }
}
