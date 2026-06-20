// ============================================================
// MEDIA PLAYER POPUP — Apple-style compact media player
// Album artwork, track info, progress bar, controls, volume
// ============================================================
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import qs.components

Item {
    id: root
    property Item theme: null
    property bool open: false

    readonly property int _frameRadius: 8
    readonly property int _imgRadius: 8

    readonly property string _icons: Quickshell.shellDir + "/bar/icons/"

    property var player: null

    property real _trackPosition: 0

    readonly property bool hasPlayer: player !== null
    readonly property string trackTitle: hasPlayer ? player.trackTitle : ""
    readonly property string trackArtist: hasPlayer ? player.trackArtist : ""
    readonly property bool isPlaying: hasPlayer ? player.isPlaying : false
    readonly property string coverUrl: _coverUrl || ""
    readonly property bool hasCover: coverUrl !== ""

    property string _coverUrl: ""

    readonly property real pos: _trackPosition
    readonly property real len: hasPlayer ? player.length : 0
    readonly property real progress: len > 0 ? pos / len : 0
    readonly property real displayProgress: _dragging ? _dragRatio : progress
    readonly property real displayPos: _dragging ? _dragRatio * len : pos

    property bool _dragging: false
    property real _dragRatio: 0
    property int _titleMarqueeX: 0
    readonly property bool _shouldMarquee: titleText && titleText.width > 0 && titleText.parent && titleText.width > titleText.parent.width

    property real _progressScaleY: seekArea.containsMouse || _dragging ? 1.0 : 0.75
    Behavior on _progressScaleY { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

    property real vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    onVolChanged: {
        if (!volSlider._dragging)
            volSlider.value = root.vol
    }

    property real _volScaleY: volSlider._hovered || volSlider._dragging ? 1.0 : 0.75
    Behavior on _volScaleY { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

    property string _coverTrackTitle: ""

    function updateCoverUrl() {
        if (!hasPlayer) {
            _coverUrl = ""
            _coverTrackTitle = ""
            _ytVideoId = ""
            return
        }

        var currentTitle = player.trackTitle || ""

        // Mevcut şarkı için zaten URL aldıysak dokunma (Timer'ın üstüne yazmasını engelle)
        if (_coverUrl !== "" && currentTitle === _coverTrackTitle) {
            return
        }

        // Yeni şarkı geldi → temizle
        if (currentTitle !== _coverTrackTitle) {
            _coverUrl = ""
            _ytVideoId = ""
        }

        // MPRIS doğrudan artUrl veriyorsa onu kullan (Spotify, local player vb.)
        // Ama eğer zaten bir YouTube URL'imiz varsa buna geçme
        if (player.trackArtUrl && player.trackArtUrl !== "" && _ytVideoId === "") {
            _coverUrl = player.trackArtUrl
            _coverTrackTitle = currentTitle
            return
        }

        if (!_coverUrl || _coverUrl === "") {
            _coverTrackTitle = currentTitle
            var name = player.dbusName || ""
            if (name) {
                var pname = name
                var prefix = "org.mpris.MediaPlayer2."
                if (pname.substring(0, prefix.length) === prefix)
                    pname = pname.substring(prefix.length)
                root._lastPlayerName = pname
                coverProc.command = ["playerctl", "--player", pname, "metadata", "mpris:artUrl"]
            } else {
                root._lastPlayerName = ""
                coverProc.command = ["playerctl", "metadata", "mpris:artUrl"]
            }
            coverProc.running = true
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
        var arr = Mpris.players.values

        // If current player exists, keep it unless another is actively Playing
        if (player) {
            var found = false
            for (var i = 0; i < arr.length; i++) {
                if (arr[i] === player) { found = true; break }
            }
            if (found) {
                if (player.playbackState !== MprisPlaybackState.Playing) {
                    for (var i = 0; i < arr.length; i++) {
                        if (arr[i] !== player && arr[i].playbackState === MprisPlaybackState.Playing) {
                            player = arr[i]
                            return
                        }
                    }
                }
                return
            }
        }

        // Current player is gone, find the best one
        var best = null
        var bestPri = -1
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
            updateCoverUrl()
            if (player && !_dragging) {
                var p = player.position
                if (p >= 0) _trackPosition = p
                if (_trackPosition < 0) _trackPosition = 0
                if (len > 0 && _trackPosition > len) _trackPosition = len
            }
        }
    }

    onPlayerChanged: {
        if (player) {
            _trackPosition = player.position
            _coverUrl = ""
            _coverTrackTitle = ""
            _ytVideoId = ""
        }
    }

    property string _lastPlayerName: ""

    Process {
        id: coverProc
        command: ["true"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var url = line.trim()
                if (url && url !== "") {
                    _coverUrl = url
                }
            }
        }
        onExited: {
            if (!_coverUrl || _coverUrl === "") {
                var pname = root._lastPlayerName
                if (pname) {
                    ytFallbackProc.command = ["playerctl", "--player", pname, "metadata", "xesam:url"]
                } else {
                    ytFallbackProc.command = ["playerctl", "metadata", "xesam:url"]
                }
                ytFallbackProc.running = true
            }
        }
    }

    // YouTube thumbnail kalite sırası:
    // maxresdefault (1280x720) → sddefault (640x480 kare) → mqdefault (320x180) → hqdefault (480x360)
    property string _ytVideoId: ""

    Process {
        id: ytFallbackProc
        command: ["true"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var url = line.trim()
                if (url && url !== "") {
                    var vid = ""
                    // youtube.com/watch?v=... veya youtu.be/... formatlarını destekle
                    var idx = url.indexOf("v=")
                    if (idx >= 0) {
                        var end = url.indexOf("&", idx)
                        if (end < 0) end = url.length
                        vid = url.substring(idx + 2, end)
                    } else {
                        // youtu.be/VIDEO_ID formatı
                        var beIdx = url.indexOf("youtu.be/")
                        if (beIdx >= 0) {
                            var start = beIdx + 9
                            var end2 = url.indexOf("?", start)
                            if (end2 < 0) end2 = url.length
                            vid = url.substring(start, end2)
                        }
                    }
                    if (vid) {
                        root._ytVideoId = vid
                        // En yüksek kaliteden başla
                        root._coverUrl = "https://i.ytimg.com/vi/" + vid + "/maxresdefault.jpg"
                    }
                }
            }
        }
    }

    onTrackTitleChanged: {
        root._titleMarqueeX = titleText && titleText.parent ? titleText.parent.width : 260
    }

    Timer {
        id: marqueeTimer
        interval: 30
        running: root.visible && root.hasPlayer && root.trackTitle !== "" && root._shouldMarquee
        repeat: true
        onTriggered: {
            root._titleMarqueeX = root._titleMarqueeX - 1
            var tw = titleText ? titleText.width : 0
            if (root._titleMarqueeX + tw < 0) {
                root._titleMarqueeX = root._titleMarqueeX + tw + 60
            }
        }
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
        anchors { fill: parent; margins: 20 }
        spacing: 0

        // === ALBUM ARTWORK (Apple-style nested radii) ===
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 260

            // Fallback background
            Rectangle {
                anchors.fill: parent
                radius: root._frameRadius
                color: root.hasCover ? "transparent" : (theme ? theme.empty : "#793370")
            }

            // Inner image (fills frame, rounded via mask)
            Item {
                id: imgWrap
                anchors.fill: parent
                visible: root.hasCover

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: imgWrap.width; height: imgWrap.height
                        radius: root._imgRadius
                        color: "#ffffff"
                    }
                }

                Image {
                    anchors.fill: parent
                    source: root.coverUrl
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    cache: false
                    onStatusChanged: {
                        if (!root._ytVideoId) return
                        var vid = root._ytVideoId
                        var url = root._coverUrl

                        if (status === Image.Error) {
                            // Hata aldık → bir sonraki kaliteye geç
                            if (url.indexOf("maxresdefault") >= 0) {
                                // maxresdefault yok → sddefault dene (640x480, kare görünüm)
                                root._coverUrl = "https://i.ytimg.com/vi/" + vid + "/sddefault.jpg"
                            } else if (url.indexOf("sddefault") >= 0) {
                                // sddefault yok → mqdefault dene (320x180)
                                root._coverUrl = "https://i.ytimg.com/vi/" + vid + "/mqdefault.jpg"
                            } else if (url.indexOf("mqdefault") >= 0) {
                                // mqdefault yok → son çare hqdefault (480x360)
                                root._coverUrl = "https://i.ytimg.com/vi/" + vid + "/hqdefault.jpg"
                            }
                        } else if (status === Image.Ready) {
                            // Yüklendi ama çok küçük mü? (YouTube "thumbnail yok" görseli = 120px)
                            if (sourceSize.width > 0 && sourceSize.width <= 120) {
                                if (url.indexOf("maxresdefault") >= 0) {
                                    root._coverUrl = "https://i.ytimg.com/vi/" + vid + "/sddefault.jpg"
                                } else if (url.indexOf("sddefault") >= 0) {
                                    root._coverUrl = "https://i.ytimg.com/vi/" + vid + "/mqdefault.jpg"
                                } else if (url.indexOf("mqdefault") >= 0) {
                                    root._coverUrl = "https://i.ytimg.com/vi/" + vid + "/hqdefault.jpg"
                                }
                            }
                        }
                    }
                }
            }

            // Fallback icon
            ColorizedIcon {
                anchors.centerIn: parent
                source: root._icons + "music-note-symbolic.svg"
                iconSize: 64
                iconColor: theme ? theme.text : "#c6c2c5"
                visible: !root.hasCover
            }
        }

        // === TRACK INFO (marquee) ===
        Item {
            id: titleClip
            Layout.fillWidth: true
            Layout.topMargin: 12
            Layout.preferredHeight: 22
            clip: !root._shouldMarquee
            layer.enabled: root._shouldMarquee
            layer.effect: OpacityMask {
                maskSource: LinearGradient {
                    width: titleClip.width
                    height: titleClip.height
                    start: Qt.point(0, 0)
                    end: Qt.point(titleClip.width, 0)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.15; color: "white" }
                        GradientStop { position: 0.85; color: "white" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
            }

            Text {
                id: titleText
                x: root._shouldMarquee ? root._titleMarqueeX : 0
                anchors.verticalCenter: parent.verticalCenter
                text: root.trackTitle || "No Track"
                color: theme ? theme.textBright : "#f7f7f7"
                font.pixelSize: 17
                font.weight: Font.Bold
                font.family: theme ? theme.fontFamily : "monospace"
            }

            Text {
                x: titleText.x + titleText.width + 60
                anchors.verticalCenter: parent.verticalCenter
                text: root.trackTitle || "No Track"
                color: theme ? theme.textBright : "#f7f7f7"
                font.pixelSize: 17
                font.weight: Font.Bold
                font.family: theme ? theme.fontFamily : "monospace"
                visible: root._shouldMarquee
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.trackArtist || "\u2014"
            color: theme ? theme.textMuted : "#c6c2c5"
            font.pixelSize: 13
            font.family: theme ? theme.fontFamily : "monospace"
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.topMargin: 2
        }

        Item { Layout.preferredHeight: 10 }

        // === PROGRESS BAR ===
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 32

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

    }
}
