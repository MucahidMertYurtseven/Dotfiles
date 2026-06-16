// ============================================================
// MEDYA POPUP'I — MPRIS oynatıcı kontrolü
// Şarkı bilgisi, ilerleme çubuğu, önceki/oynat/sonraki
// Ses slider'ı ile tam medya denetimi
// ============================================================
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import qs.components

Item {
    id: root
    property Item theme: null
    property bool open: false

    readonly property string _icons: Quickshell.shellDir + "/bar/icons/"

    property var player: null

    // Yerel pozisyon takibi (D-Bus sadece seek/event'te güncellenir)
    property real _trackPosition: 0

    readonly property bool hasPlayer: player !== null
    readonly property string trackTitle: hasPlayer ? player.trackTitle : "Nothing Playing"
    readonly property string trackArtist: hasPlayer ? player.trackArtist : ""
    readonly property bool   isPlaying: hasPlayer ? player.isPlaying : false
    readonly property real pos: _trackPosition
    readonly property real len: hasPlayer ? player.length : 0
    readonly property real progress: len > 0 ? pos / len : 0
    readonly property real displayProgress: _dragging ? _dragRatio : progress
    readonly property real displayPos: _dragging ? _dragRatio * len : pos

    property bool _dragging: false
    property real _dragRatio: 0
    property real _dragLen: 0
    property real _progressScaleY: seekArea.containsMouse || _dragging ? 1.0 : 0.75
    Behavior on _progressScaleY { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

    property real vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    onVolChanged: {
        if (!volSlider._dragging && !volSlider._clicking)
            volSlider.value = root.vol
    }

    // En iyi oynatıcıyı bul (Playing > Paused)
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

    Component.onCompleted: {
        findBestPlayer()
        if (player) _trackPosition = player.position
    }

    // Kombine timer: oynatıcı bul + pozisyon takibi (direkt D-Bus)
    Timer {
        interval: 250
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            findBestPlayer()
            if (player && !_dragging) {
                var p = player.position
                if (p >= 0) _trackPosition = p
                if (_trackPosition < 0) _trackPosition = 0
                if (len > 0 && _trackPosition > len) _trackPosition = len
            }
        }
    }

    // Oynatıcı değişince pozisyonu senkronize et
    onPlayerChanged: {
        if (player) {
            _trackPosition = player.position
        }
    }

    function formatTime(s) {
        if (s <= 0) return "0:00"
        var totalSec = Math.floor(s)
        var h = Math.floor(totalSec / 3600)
        var m = Math.floor((totalSec % 3600) / 60)
        var sec = totalSec % 60
        if (h > 0)
            return h + ":" + (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec
        return m + ":" + (sec < 10 ? "0" : "") + sec
    }

    anchors.fill: parent

    // Popup arkaplanı
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgPopupBlur : "#b231112d"
        radius: theme ? theme.popupRadius : 12
        border.color: theme ? theme.border : "#6675376d"; border.width: 1
    }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: theme?.popupPad ?? 12 }
        spacing: 10

        // Şarkı bilgisi
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                width: 56; height: 56
                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: theme ? theme.empty : "#793370"

                    ColorizedIcon {
                        anchors.centerIn: parent
                        source: root._icons + "music-note-symbolic.svg"
                        iconSize: 28
                        iconColor: root.isPlaying
                            ? (theme ? theme.active : "#dda6d5")
                            : (theme ? theme.text : "#c6c2c5")
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.trackTitle
                    color: theme ? theme.textBright : "#f7f7f7"
                    font.pixelSize: 14
                    font.bold: true
                    font.family: theme ? theme.fontFamily : "monospace"
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.trackArtist || "\u2014"
                    color: theme ? theme.text : "#c6c2c5"
                    font.pixelSize: 11
                    font.family: theme ? theme.fontFamily : "monospace"
                    elide: Text.ElideRight
                }
            }
        }

        // İlerleme çubuğu
        Item {
            Layout.fillWidth: true
            implicitHeight: 26

            Rectangle {
                id: progressTrack
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 2
                height: 8
                radius: height / 2
                color: theme ? theme.border : "#6675376d"

                transform: Scale { origin.y: 4; yScale: root._progressScaleY }

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * root.displayProgress
                    radius: parent.radius
                    color: theme ? theme.active : "#dda6d5"

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        width: parent.width * 0.8
                        height: parent.height * 0.3
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, 0.15)
                        visible: parent.width > 2
                    }
                }
            }

            // Süre bilgisi
            Text {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -10
                text: root.formatTime(root.displayPos)
                color: theme ? theme.text : "#c6c2c5"
                font.pixelSize: 11
                font.family: theme ? theme.fontFamily : "monospace"
            }

            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -10
                text: root.formatTime(root.len)
                color: theme ? theme.text : "#c6c2c5"
                font.pixelSize: 11
                font.family: theme ? theme.fontFamily : "monospace"
            }

            // İlerleme çubuğu fare etkileşimi
            MouseArea {
                id: seekArea
                anchors.fill: progressTrack
                anchors.topMargin: -8; anchors.bottomMargin: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: root.hasPlayer && root.len > 0

                onClicked: (mouse) => {
                    if (!root.hasPlayer || !root.player || root.len <= 0) return
                    root._dragLen = root.len
                    root._dragRatio = Math.max(0, Math.min(1, mouse.x / progressTrack.width))
                    var target = root._dragRatio * root._dragLen
                    root._trackPosition = target
                    root.player.position = target
                }
                onPressed: (mouse) => {
                    if (!root.hasPlayer || !root.player || root.len <= 0) return
                    root._dragLen = root.len
                    root._dragging = true
                    root._dragRatio = Math.max(0, Math.min(1, mouse.x / progressTrack.width))
                }
                onPositionChanged: (mouse) => {
                    if (pressed && root.hasPlayer && root.len > 0) {
                        root._dragRatio = Math.max(0, Math.min(1, mouse.x / progressTrack.width))
                    }
                }
                onReleased: (mouse) => {
                    if (!root.hasPlayer || !root.player || root._dragLen <= 0) return
                    root._dragging = false
                    var target = root._dragRatio * root._dragLen
                    root._trackPosition = target
                    root.player.position = target
                }
            }
        }

        // Kontrol düğmeleri
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 14

            // Önceki
            Item {
                width: 28; height: 28
                property real _s: prevMa.containsMouse ? 1.15 : 1.0
                scale: _s
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                ColorizedIcon {
                    anchors.centerIn: parent
                    source: root._icons + "media-skip-backward-symbolic.svg"
                    iconSize: 22
                    iconColor: root.hasPlayer
                        ? (theme ? theme.active : "#dda6d5")
                        : (theme ? theme.empty : "#793370")
                }

                MouseArea {
                    id: prevMa
                    anchors.fill: parent; anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.hasPlayer
                    onClicked: { if (root.player) root.player.previous() }
                }
            }

            // Oynat/Duraklat
            Item {
                width: 36; height: 36
                property real _s: playMa.containsMouse ? 1.12 : 1.0
                scale: _s
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                ColorizedIcon {
                    anchors.centerIn: parent
                    source: root.isPlaying
                        ? root._icons + "media-playback-pause-symbolic.svg"
                        : root._icons + "media-playback-start-symbolic.svg"
                    iconSize: 30
                    iconColor: root.hasPlayer
                        ? (theme ? theme.active : "#dda6d5")
                        : (theme ? theme.empty : "#793370")
                }

                MouseArea {
                    id: playMa
                    anchors.fill: parent; anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.hasPlayer
                    onClicked: { if (root.player) root.player.togglePlaying() }
                }
            }

            // Sonraki
            Item {
                width: 28; height: 28
                property real _s: nextMa.containsMouse ? 1.15 : 1.0
                scale: _s
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                ColorizedIcon {
                    anchors.centerIn: parent
                    source: root._icons + "media-skip-forward-symbolic.svg"
                    iconSize: 22
                    iconColor: root.hasPlayer
                        ? (theme ? theme.active : "#dda6d5")
                        : (theme ? theme.empty : "#793370")
                }

                MouseArea {
                    id: nextMa
                    anchors.fill: parent; anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.hasPlayer
                    onClicked: { if (root.player) root.player.next() }
                }
            }
        }

        // Ses slider'ı
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColorizedIcon {
                source: (Pipewire.defaultAudioSink?.audio?.muted ?? false)
                    ? root._icons + "audio-volume-muted-symbolic.svg"
                    : root._icons + "audio-volume-high-symbolic.svg"
                iconSize: 14
                iconColor: (Pipewire.defaultAudioSink?.audio?.muted ?? false)
                    ? (theme ? theme.warn : "#d09caa")
                    : (theme ? theme.text : "#c6c2c5")
            }

            // Ses slider'ı
            Item {
                id: volSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 24

                property real value: root.vol
                readonly property real _pos: Math.min(value, 1.0)
                property bool _dragging: false
                property bool _clicking: false
                property bool _hovered: false
                property real _scaleY: _hovered || _dragging ? 1.0 : 0.75
                Behavior on _scaleY { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

                onValueChanged: {
                    if (_dragging || _clicking) {
                        var a = Pipewire.defaultAudioSink?.audio
                        if (a) a.volume = value
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 8
                    radius: height / 2
                    color: theme ? theme.border : "#6675376d"

                    transform: Scale { origin.y: 4; yScale: volSlider._scaleY }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * volSlider._pos
                        radius: parent.radius
                        color: theme ? theme.active : "#dda6d5"

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 1
                            width: parent.width * 0.8
                            height: parent.height * 0.3
                            radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.15)
                            visible: parent.width > 2
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: volSlider._hovered = true
                    onExited: volSlider._hovered = false

                    onPressed: (mouse) => {
                        volSlider._dragging = true
                        volSlider._clicking = true
                        volSlider.value = Math.max(0, Math.min(1, mouse.x / width))
                    }

                    onPositionChanged: (mouse) => {
                        if (volSlider._dragging && pressed) {
                            volSlider.value = Math.max(0, Math.min(1, mouse.x / width))
                        }
                    }

                    onReleased: {
                        volSlider._dragging = false
                        volSlider._clicking = false
                    }
                }
            }
        }
    }
}
