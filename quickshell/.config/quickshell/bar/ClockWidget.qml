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
    property var theme: null
    signal clicked()

    property bool _showMedia: false       // saat mi medya mı görünsün

    property var player: null

    readonly property string _trackTitle: player ? player.trackTitle : ""
    readonly property string _trackArtist: player ? player.trackArtist : ""
    readonly property bool _isPlaying: player ? player.isPlaying : false
    readonly property string _dispText: {
        if (!player) return ""
        var t = player.trackTitle
        var a = player.trackArtist
        if (t && a) return t + " - " + a
        if (t) return t
        if (a) return a
        return ""
    }

    // Kayan yazı (marquee) pozisyonu
    property int _marqueeX: 320

    // Görselleştirici çubuk yükseklikleri
    property variant _barHeights: []
    property bool _barInit: false
    property int _visTime: 0
    readonly property int _barCount: 30

    height: 32
    clip: true

    color: theme ? theme.bgDark : "#202020"
    radius: 14
    border.color: theme ? theme.border : "#323232"
    border.width: 1

    property int _clockWidth: text.implicitWidth + 32
    property int _targetWidth: _showMedia && _trackTitle ? 320 : _clockWidth
    width: _targetWidth
    Behavior on width {
        NumberAnimation { duration: 450; easing.type: Easing.OutBack; easing.overshoot: 2.8 }
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
            opacity: 0.2
            Repeater {
                model: root._barCount
                Rectangle {
                    x: index * (parent.width / root._barCount)
                    width: parent.width / root._barCount - 2
                    height: _barHeights.length === root._barCount ? _barHeights[index] : 0
                    radius: width / 2
                    color: theme ? theme.text : "#c5c5c5"
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    Behavior on height {
                        NumberAnimation { duration: 60; easing.type: Easing.OutSine }
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
                color: theme ? theme.text : "#c5c5c5"
                font.pixelSize: 12; font.bold: true
                font.family: theme ? theme.fontFamily : "monospace"
            }

            // Kayan yazının tekrarı (sürekli döngü için)
            Text {
                x: marqueeText.x + marqueeText.width + 80
                anchors.verticalCenter: parent.verticalCenter
                text: root._dispText
                color: theme ? theme.text : "#c5c5c5"
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

    // -- Ses görselleştirici animasyonu (Apple tarzı) --
    Timer {
        interval: 50; running: _showMedia; repeat: true
        onTriggered: {
            var n = root._barCount

            if (!_barInit) {
                var a = []
                for (var j = 0; j < n; j++) a[j] = 0
                _barHeights = a
                _barInit = true
            }

            var heights = _barHeights.slice()

            // Çalmıyorsa çubukları yavaşça sıfırla
            if (!root._isPlaying) {
                for (var k = 0; k < n; k++) heights[k] = heights[k] * 0.85
                _barHeights = heights
                return
            }

            var left = AudioLevelService.peakLeft || 0
            var right = AudioLevelService.peakRight || 0

            var energy = Math.max(left, right)

            var t = _visTime++

            for (var i = 0; i < n; i++) {
                if (energy < 0.02) {
                    heights[i] = heights[i] * 0.85
                    continue
                }

                // Frekans bandı simülasyonu (her bar farklı frekans)
                var freq = (i / n) * 8
                var wave = Math.abs(Math.sin(freq * Math.PI + t * 0.04))
                var subWave = Math.abs(Math.cos(freq * 0.7 * Math.PI - t * 0.025))
                var motion = wave * 0.6 + subWave * 0.4

                // Enerjiye duyarlılık (Apple'da yumuşak)
                var amp = Math.pow(energy, 0.7) * 2.5

                // Orta frekans hafif vurgulu (Apple smile curve)
                var midBoost = 1.0 + 0.3 * Math.sin((i / n) * Math.PI)

                var target = motion * amp * midBoost * 18
                target = Math.max(1, Math.min(28, target))

                // Apple tarzı yumuşak geçiş
                if (target > heights[i]) {
                    heights[i] = heights[i] * 0.45 + target * 0.55
                } else {
                    heights[i] = heights[i] * 0.88 + target * 0.12
                }
            }

            _barHeights = heights
        }
    }

    // -- Tıklama ve scroll ile görünüm değiştir --
    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onPressed: root.clicked()
        onWheel: (wheel) => {
            if (_trackTitle) {
                _showMedia = !_showMedia
            }
        }
    }
}
