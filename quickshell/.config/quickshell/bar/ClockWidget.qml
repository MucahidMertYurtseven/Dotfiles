// ============================================================
// BAR SAAT WIDGET'I — ortada görünen saat ve medya bilgisi
// Tıklayınca takvim/medya popup'ını açar, scroll ile geçiş yapar
// Medya çalarken görselleştirici ve kayan yazı gösterir
// ============================================================
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris
import qs.services

Rectangle {
    id: root
    property Item theme: null
    signal clicked()

    property bool _showMedia: false       // saat mi medya mı görünsün

    property var player: null

    readonly property string _trackTitle: player ? player.trackTitle : ""
    readonly property string _trackArtist: player ? player.trackArtist : ""
    readonly property bool _isPlaying: player ? player.isPlaying : false
    readonly property string _dispText: {
        if (player) {
            var t = player.trackTitle
            var a = player.trackArtist
            if (t && a) return t + " - " + a
            if (t) return t
            if (a) return a
        }
        return _showMedia ? "♫ No Player" : ""
    }

    // Kayan yazı (marquee) pozisyonu
    property int _marqueeX: 320

    // Görselleştirici çubuk yükseklikleri
    property variant _barHeights: []
    property bool _barInit: false
    property int _visTime: 0

    height: 32
    clip: true

    color: theme ? theme.bgBar : "#7f31112d"
    radius: 14
    border.color: theme ? theme.border : "#6675376d"
    border.width: 1
    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }

    property int _clockWidth: text.implicitWidth + 32
    property int _targetWidth: _showMedia ? 320 : _clockWidth
    width: _targetWidth
    Behavior on width {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    // Sayıları iki basamaklı yap (ör: 09)
    function pad(n) { return n < 10 ? "0" + n : n }

    // En uygun MPRIS oynatıcıyı bul (Playing > Paused)
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

    Component.onCompleted: findBestPlayer()

    // Her saniye en iyi oynatıcıyı kontrol et
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: findBestPlayer()
    }

    // -- Saat görünümü --
    Item {
        anchors.fill: parent
        x: _showMedia ? -parent.width : 0
        opacity: _showMedia ? 0 : 1
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            id: text
            anchors.centerIn: parent
            color: root.theme ? root.theme.text : "#c5c5c5"
            font.pixelSize: 14; font.bold: true
            font.family: root.theme ? root.theme.fontFamily : "monospace"

            // Her saniye güncelle
            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: {
                    var d = new Date()
                    text.text = pad(d.getHours()) + ":" + pad(d.getMinutes())
                        + "  \u2502  " + Qt.formatDate(d, "dd MMMM yyyy")
                }
            }
        }
    }

    // -- Medya oynatıcı görünümü --
    Item {
        anchors.fill: parent
        x: _showMedia ? 0 : parent.width
        opacity: _showMedia ? 1 : 0
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
        clip: true

        // Ses görselleştirici arkaplan
        Item {
            id: visBg
            anchors.fill: parent
            clip: true
            opacity: 0.15
            Repeater {
                model: 64
                Rectangle {
                    x: index * (parent.width / 64)
                    width: parent.width / 64 - 1
                    height: _barHeights.length === 64 ? _barHeights[index] : 0
                    radius: width / 2
                    color: theme ? theme.text : "#c6c2c5"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on height {
                        NumberAnimation { duration: 30; easing.type: Easing.OutSine }
                    }
                }
            }
        }

        // Kayan yazı (marquee)
        Item {
            id: marqueeHost
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 8
            anchors.right: parent.right; anchors.rightMargin: 8
            height: 16
            clip: true
            visible: _dispText !== ""

            Text {
                id: marqueeText
                x: root._marqueeX
                anchors.verticalCenter: parent.verticalCenter
                text: root._dispText
                color: theme ? theme.text : "#c6c2c5"
                font.pixelSize: 12; font.bold: true
                font.family: theme ? theme.fontFamily : "monospace"
            }

            // Kayan yazının tekrarı (sürekli döngü için)
            Text {
                x: marqueeText.x + marqueeText.width + 80
                anchors.verticalCenter: parent.verticalCenter
                text: root._dispText
                color: theme ? theme.text : "#c6c2c5"
                font.pixelSize: 12; font.bold: true
                font.family: theme ? theme.fontFamily : "monospace"
                visible: marqueeText.width > 0
            }

            // Kayan yazı timer'ı
            Timer {
                id: marqueeLoop
                interval: 30
                running: root._showMedia && root._dispText !== ""
                repeat: true
                onTriggered: {
                    root._marqueeX -= 1
                    if (root._marqueeX + marqueeText.width < 0) {
                        root._marqueeX += marqueeText.width + 80
                    }
                }
            }
        }
    }

    on_DispTextChanged: { _marqueeX = marqueeHost ? marqueeHost.width : width }
    on_ShowMediaChanged: { if (_showMedia) _marqueeX = marqueeHost ? marqueeHost.width : width }

    // -- Ses görselleştirici animasyonu --
    Timer {
        interval: 70; running: _showMedia; repeat: true
        onTriggered: {
            var n = 64

            if (!_barInit) {
                var a = []
                for (var j = 0; j < n; j++) a[j] = 0
                _barHeights = a
                _barInit = true
            }

            var heights = _barHeights.slice()

            var left = AudioLevelService.peakLeft || 0
            var right = AudioLevelService.peakRight || 0

            var rawVol = Math.max(left, right)
            var vol = Math.pow(rawVol, 1.5) * 1.0

            var t = _visTime++

            // Çubuk yüksekliklerini hesapla
            for (var i = 0; i < n; i++) {
                if (vol < 0.05) {
                    heights[i] = heights[i] * 0.70
                    continue
                }

                var bellCurve = 1.0 + 0.3 * Math.sin((i / n) * Math.PI * 2)

                var fastWave = Math.abs(Math.sin(i * 6.0 + t * 0.9))
                var midWave  = Math.abs(Math.cos(i * 3.5 - t * 0.5))
                var slowWave = Math.abs(Math.sin(i * 1.5 + t * 0.3))
                var noise = (fastWave * 0.4) + (midWave * 0.35) + (slowWave * 0.25)

                var spike = (Math.random() > 0.7) ? 1.8 : 0.9

                var target = vol * noise * bellCurve * spike * 32
                target = Math.max(1, Math.min(30, target))

                if (target > heights[i]) {
                    heights[i] = heights[i] * 0.2 + target * 0.8
                } else {
                    heights[i] = heights[i] * 0.88 + target * 0.12
                }
            }

            _barHeights = heights
        }
    }

    // -- Tıklama ve scroll ile görünüm değiştir --
    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
        onClicked: root.clicked()
        onWheel: (wheel) => {
            _showMedia = !_showMedia
        }
    }
}
