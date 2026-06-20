// ============================================================
// MEDIA PLAYER POPUP — Apple-style compact media player
// Album artwork, track info, progress bar, controls, volume
// ============================================================
import QtQuick
import QtQuick.Layouts
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

    property real _trackPosition: 0

    readonly property bool hasPlayer: player !== null
    readonly property string trackTitle: hasPlayer ? player.trackTitle : ""
    readonly property string trackArtist: hasPlayer ? player.trackArtist : ""
    readonly property bool isPlaying: hasPlayer ? player.isPlaying : false
    readonly property bool hasCover: hasPlayer && player.trackCoverUrl && player.trackCoverUrl.toString() !== ""
    readonly property string coverUrl: hasCover ? player.trackCoverUrl : ""
    readonly property real pos: _trackPosition
    readonly property real len: hasPlayer ? player.length : 0
    readonly property real progress: len > 0 ? pos / len : 0
    readonly property real displayProgress: _dragging ? _dragRatio : progress
    readonly property real displayPos: _dragging ? _dragRatio * len : pos

    property bool _dragging: false
    property real _dragRatio: 0

    // Progress bar hover scale
    property real _progressScaleY: seekArea.containsMouse || _dragging ? 1.0 : 0.75
    Behavior on _progressScaleY { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

    property real vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    onVolChanged: {
        if (!volSlider._dragging)
            volSlider.value = root.vol
    }

    // Volume slider hover scale
    property real _volScaleY: volSlider._hovered || volSlider._dragging ? 1.0 : 0.75
    Behavior on _volScaleY { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

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

    function formatRemaining(s) {
        if (len <= 0) return "0:00"
        var remaining = len - s
        if (remaining <= 0) return "0:00"
        var totalSec = Math.floor(remaining)
        var h = Math.floor(totalSec / 3600)
        var m = Math.floor((totalSec % 3600) / 60)
        var sec = totalSec % 60
        return "-" + (h > 0 ? h + ":" + (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec : m + ":" + (sec < 10 ? "0" : "") + sec)
    }

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

    Timer {
        interval: 250
        running: root.visible
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

    onPlayerChanged: {
        if (player) _trackPosition = player.position
    }

    anchors.fill: parent

    // Glass background
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgPopupBlur : "#b231112d"
        radius: theme ? theme.popupRadius : 12
        border.color: theme ? theme.border : "#6675376d"
        border.width: 1
    }

    ColumnLayout {
        anchors { fill: parent; margins: theme?.popupPad ?? 12 }
        spacing: 0

        // === SPACER TOP ===
        Item { Layout.preferredHeight: 10 }

        // === ALBUM ARTWORK ===
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 240
            Layout.preferredHeight: 240

            Rectangle {
                anchors.fill: parent
                radius: 12
                clip: true
                color: theme ? theme.empty : "#793370"

                Image {
                    anchors.fill: parent
                    source: root.coverUrl
                    sourceSize { width: 480; height: 480 }
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    mipmap: true
                    visible: root.hasCover
                }

                ColorizedIcon {
                    anchors.centerIn: parent
                    source: root._icons + "music-note-symbolic.svg"
                    iconSize: 64
                    iconColor: theme ? theme.text : "#c6c2c5"
                    visible: !root.hasCover
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.15)
                border.width: 1
            }
        }

        Item { Layout.preferredHeight: 10 }

        // === TRACK INFO ===
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            text: root.trackTitle || "No Track"
            color: theme ? theme.textBright : "#f7f7f7"
            font.pixelSize: 17
            font.weight: Font.Bold
            font.family: theme ? theme.fontFamily : "monospace"
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            text: root.trackArtist || "\u2014"
            color: theme ? theme.textMuted : "#c6c2c5"
            font.pixelSize: 13
            font.family: theme ? theme.fontFamily : "monospace"
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.topMargin: 2
        }

        Item { Layout.preferredHeight: 8 }

        // === PROGRESS BAR ===
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 36

            // Slider
            Rectangle {
                id: progressTrack
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                anchors.verticalCenterOffset: -5
                height: 8
                radius: height / 2
                color: theme ? theme.border : "#6675376d"

                transform: Scale { origin.y: 4; yScale: root._progressScaleY }

                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
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

            // Time labels
            Text {
                anchors { left: parent.left; bottom: parent.bottom }
                text: root.formatTime(root.displayPos)
                color: theme ? theme.textMuted : "#c6c2c5"
                font.pixelSize: 11
                font.family: theme ? theme.fontFamily : "monospace"
            }

            Text {
                anchors { right: parent.right; bottom: parent.bottom }
                text: root.formatRemaining(root.displayPos)
                color: theme ? theme.textMuted : "#c6c2c5"
                font.pixelSize: 11
                font.family: theme ? theme.fontFamily : "monospace"
            }

            // Seek interaction
            MouseArea {
                id: seekArea
                anchors { fill: parent; topMargin: -4; bottomMargin: -4 }
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: root.hasPlayer && root.len > 0

                onClicked: (mouse) => {
                    if (!root.hasPlayer || !root.player || root.len <= 0) return
                    var ratio = Math.max(0, Math.min(1, mouse.x / progressTrack.width))
                    var target = ratio * root.len
                    root._trackPosition = target
                    root.player.position = target
                }
                onPressed: (mouse) => {
                    if (!root.hasPlayer || !root.player || root.len <= 0) return
                    root._dragging = true
                    root._dragRatio = Math.max(0, Math.min(1, mouse.x / progressTrack.width))
                }
                onPositionChanged: (mouse) => {
                    if (pressed && root.hasPlayer && root.len > 0) {
                        root._dragRatio = Math.max(0, Math.min(1, mouse.x / progressTrack.width))
                    }
                }
                onReleased: {
                    if (!root.hasPlayer || !root.player || root.len <= 0) return
                    root._dragging = false
                    var target = root._dragRatio * root.len
                    root._trackPosition = target
                    root.player.position = target
                }
            }
        }

        Item { Layout.preferredHeight: 8 }

        // === NAVIGATION CONTROLS ===
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 14

            // Previous
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

            // Play/Pause
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

            // Next
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

        Item { Layout.preferredHeight: 10 }

        // === VOLUME CONTROLS ===
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColorizedIcon {
                source: (Pipewire.defaultAudioSink?.audio?.muted ?? false)
                    ? root._icons + "audio-volume-muted-symbolic.svg"
                    : root._icons + "audio-volume-low-symbolic.svg"
                iconSize: 16
                iconColor: (Pipewire.defaultAudioSink?.audio?.muted ?? false)
                    ? (theme ? theme.warn : "#d09caa")
                    : (theme ? theme.textMuted : "#c6c2c5")
            }

            Item {
                id: volSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 28

                property real value: root.vol
                readonly property real _pos: Math.min(value, 1.0)
                property bool _dragging: false
                property bool _hovered: false

                onValueChanged: {
                    if (_dragging) {
                        var a = Pipewire.defaultAudioSink?.audio
                        if (a) a.volume = value
                    }
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                    height: 8
                    radius: height / 2
                    color: theme ? theme.border : "#6675376d"

                    transform: Scale { origin.y: 4; yScale: root._volScaleY }

                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
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
                        volSlider.value = Math.max(0, Math.min(1, mouse.x / width))
                    }

                    onPositionChanged: (mouse) => {
                        if (volSlider._dragging && pressed) {
                            volSlider.value = Math.max(0, Math.min(1, mouse.x / width))
                        }
                    }

                    onReleased: {
                        volSlider._dragging = false
                    }
                }
            }

            ColorizedIcon {
                source: root._icons + "audio-volume-high-symbolic.svg"
                iconSize: 16
                iconColor: (Pipewire.defaultAudioSink?.audio?.muted ?? false)
                    ? (theme ? theme.warn : "#d09caa")
                    : (theme ? theme.textMuted : "#c6c2c5")
            }
        }

        // === SPACER BOTTOM ===
        Item { Layout.preferredHeight: 10 }
    }
}
