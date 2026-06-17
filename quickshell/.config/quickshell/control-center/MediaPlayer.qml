// ============================================================
// MEDYA OYNATICI — MPRIS kontrollü tam medya widget'ı
// Şarkı bilgisi, ilerleme çubuğu, kontroller, ses ayarı
// ============================================================
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.components

Item {
    id: mediaRoot
    property Item theme: null
    implicitHeight: 88

    readonly property string _icons: Quickshell.shellDir + "/bar/icons/"

    property var player: null

    readonly property string trackTitle:  player ? player.trackTitle   : ""
    readonly property string trackArtist: player && player.trackArtists
        ? player.trackArtists.join(", ") : "\u2014"
    readonly property bool   isPlaying:   player ? player.isPlaying : false

    readonly property real position: player ? player.position : 0
    readonly property real length: player ? player.length : 1
    readonly property real volume: player ? player.volume : 0

    // En iyi oynatıcıyı bul
    function findBestPlayer() {
        var best = null
        var bestPri = -1
        var arr = Mpris.players.values
        for (var i = 0; i < arr.length; i++) {
            var p = arr[i]
            var pri = 0
            if (p.playbackState === MprisPlaybackState.Playing) pri = 2
            else if (p.playbackState === MprisPlaybackState.Paused) pri = 1
            if (pri > bestPri) {
                bestPri = pri
                best = p
            }
        }
        if (best !== player) {
            player = best
        }
    }

    // Süre formatla (mikrosaniye -> mm:ss)
    function formatTime(microseconds) {
        if (!microseconds || isNaN(microseconds)) return "0:00"
        var sec = Math.floor(microseconds / 1000000)
        var m = Math.floor(sec / 60)
        var s = Math.floor(sec % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    Component.onCompleted: findBestPlayer()

    // Her saniye oynatıcıyı kontrol et
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: findBestPlayer()
    }

    // Özel QML slider'ı — saf QML, hiçbir tema etkilemez
    component AppleSlider : Item {
        id: control
        implicitWidth: 100
        implicitHeight: 8

        property real from: 0
        property real to: 1
        property real value: 0

        signal userSeek(real val)

        // Arkaplan
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: mediaRoot.theme ? mediaRoot.theme.border : "#2a2c42"

            // İlerleme (dolu kısım)
            Rectangle {
                property real fillPercent: {
                    if (control.to <= control.from) return 0;
                    if (mouseArea.pressed) {
                        return Math.max(0, Math.min(1, mouseArea.mouseX / control.width));
                    }
                    return Math.max(0, Math.min(1, (control.value - control.from) / (control.to - control.from)));
                }

                width: parent.width * fillPercent
                height: parent.height
                color: mediaRoot.theme ? mediaRoot.theme.active : "#e8e9f5"
                radius: parent.radius
            }
        }

        // Fare etkileşimi
        MouseArea {
            id: mouseArea
            anchors.fill: parent

            function updatePos(mouse) {
                let pct = Math.max(0, Math.min(1, mouse.x / width))
                let newVal = control.from + pct * (control.to - control.from)
                control.userSeek(newVal)
            }

            onPositionChanged: (mouse) => { if (pressed) updatePos(mouse) }
            onPressed: (mouse) => updatePos(mouse)
        }
    }

    // Kart arkaplanı
    Rectangle {
        anchors.fill: parent
        color:        theme ? theme.bgPopup : "#1c1d2b"
        radius:       14
        border.color: theme ? theme.border : "#2a2c42"
        border.width: 1

        RowLayout {
            anchors { fill: parent; margins: 12 }
            spacing: 14

            // Müzik ikonu
            Rectangle {
                width: 48; height: 48; radius: 10
                color: theme ? theme.empty : "#2a2c42"
                ColorizedIcon {
                    anchors.centerIn: parent
                    source: mediaRoot._icons + "audio-volume-medium-symbolic.svg"
                    iconSize: 22
                    iconColor: theme ? theme.active : "#7e8099"
                }
            }

            // Şarkı bilgisi + ilerleme
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text:  mediaRoot.trackTitle
                    color: theme ? theme.textBright : "#e8e9f5"
                    font { pixelSize: 14; weight: Font.SemiBold }
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text:  mediaRoot.trackArtist
                    color: theme ? theme.textMuted : "#7e8099"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                // İlerleme çubuğu
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: mediaRoot.formatTime(mediaRoot.position)
                        color: theme ? theme.textMuted : "#7e8099"
                        font.pixelSize: 10
                    }

                    AppleSlider {
                        Layout.fillWidth: true
                        from: 0
                        to: mediaRoot.length > 0 ? mediaRoot.length : 1
                        value: mediaRoot.position
                        onUserSeek: (val) => {
                            if (mediaRoot.player) mediaRoot.player.position = val
                        }
                    }

                    Text {
                        text: mediaRoot.formatTime(mediaRoot.length)
                        color: theme ? theme.textMuted : "#7e8099"
                        font.pixelSize: 10
                    }
                }
            }

            // Kontroller + ses
            ColumnLayout {
                spacing: 6
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                // Önceki / Oynat / Sonraki
                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignHCenter

                    MediaButton {
                        iconSource: mediaRoot._icons + "media-skip-backward-symbolic.svg"
                        enabled: mediaRoot.player !== null
                        theme: mediaRoot.theme
                        onClicked: if (mediaRoot.player) mediaRoot.player.previous()
                    }
                    MediaButton {
                        iconSource: mediaRoot.isPlaying
                            ? mediaRoot._icons + "media-playback-pause-symbolic.svg"
                            : mediaRoot._icons + "media-playback-start-symbolic.svg"
                        primary: true
                        enabled: mediaRoot.player !== null
                        theme: mediaRoot.theme
                        onClicked: if (mediaRoot.player) mediaRoot.player.togglePlaying()
                    }
                    MediaButton {
                        iconSource: mediaRoot._icons + "media-skip-forward-symbolic.svg"
                        enabled: mediaRoot.player !== null
                        theme: mediaRoot.theme
                        onClicked: if (mediaRoot.player) mediaRoot.player.next()
                    }
                }

                // Ses slider'ı
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    ColorizedIcon {
                        source: mediaRoot._icons + "audio-volume-low-symbolic.svg"
                        iconSize: 12
                        iconColor: theme ? theme.textMuted : "#7e8099"
                    }

                    AppleSlider {
                        Layout.preferredWidth: 70
                        from: 0
                        to: 1
                        value: mediaRoot.volume
                        onUserSeek: (val) => {
                            if (mediaRoot.player) mediaRoot.player.volume = val
                        }
                    }
                }
            }
        }
    }
}
