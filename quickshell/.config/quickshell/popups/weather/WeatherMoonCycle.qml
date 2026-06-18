import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import Quickshell

ColumnLayout {
    id: root
    property Item theme: null
    spacing: 12

    // Ay Fazı
    Rectangle {
        id: moonCard
        Layout.fillWidth: true
        Layout.preferredHeight: 125
        radius: 16
        color: theme ? theme.bgPopup : "#cc131b2e"
        border.color: theme ? theme.border : "#1affffff"; border.width: 1
        clip: true

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Sol Taraf (Bilgiler)
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 24
                    anchors.rightMargin: 16
                    spacing: 0

                    RowLayout {
                        spacing: 4
                        Layout.topMargin: 8
                        Layout.bottomMargin: 12
                        Text { text: "nights_stay"; font.family: "Material Symbols Outlined"; color: theme ? theme.text : "#9ca3af"; font.pixelSize: 12 }
                        Text { text: "AY FAZI"; color: theme ? theme.text : "#9ca3af"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.5 }
                        Item { Layout.fillWidth: true }
                    }
                    Text { 
                        text: WeatherService.moonPhaseTR
                        color: theme ? theme.textBright : "#ffffff"
                        font.pixelSize: 18
                        font.bold: true
                        font.family: "Inter"
                        Layout.fillWidth: true 
                        Layout.bottomMargin: 12
                        wrapMode: Text.WordWrap
                    }
                    RowLayout {
                        spacing: 4
                        Text { text: "routine"; font.family: "Material Symbols Outlined"; color: theme ? theme.text : "#9ca3af"; font.pixelSize: 12 }
                        Text { text: "Batış: " + WeatherService.sunrise24h; color: theme ? theme.text : "#9ca3af"; font.pixelSize: 10; font.family: "Inter" }
                    }
                }
            }

            // Sağ Taraf (Görsel)
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true

                Item {
                    id: maskItem
                    anchors.fill: parent
                    visible: false
                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: "black"
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 16
                        color: "black"
                    }
                }

                Image {
                    id: moonImg
                    source: Quickshell.shellDir + "/bar/images/moon/" + WeatherService.moonPhaseImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: moonImg
                    maskSource: maskItem
                }
                
                // Ekstra çerçeve sınırı için ayraç çizgisi
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: "#1affffff"
                }
            }
        }
    }

    Item { Layout.preferredHeight: 31 } // Ay fazı ve Döngü kartı arasını açan ekstra boşluk

    // Güneş/Ay Döngüsü
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 100
        radius: 16
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 0
            spacing: WeatherService.isDay ? 30 : 10

            RowLayout {
                Layout.topMargin: -2
                spacing: 4
                Text { text: WeatherService.isDay ? "wb_twilight" : "nights_stay"; font.family: "Material Symbols Outlined"; color: theme ? theme.text : "#9ca3af"; font.pixelSize: 12 }
                Text { text: WeatherService.isDay ? "GÜNEŞ DÖNGÜSÜ" : "AY DÖNGÜSÜ"; color: theme ? theme.text : "#9ca3af"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.5 }
            }

            Item {
                id: celestialContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 64

                function getExactSunPathY(x, W, H) {
                    if (x < H) {
                        return Math.sqrt(Math.pow(H, 2) - Math.pow(x - H, 2));
                    } else if (x > W - H) {
                        return Math.sqrt(Math.pow(H, 2) - Math.pow(x - (W - H), 2));
                    } else {
                        return H;
                    }
                }

                function getPos(prog, isDay) {
                    var W = celestialArc.width;
                    var H = celestialArc.height;
                    if (W <= 0) W = 1;
                    
                    var px = prog * W;
                    var y = getExactSunPathY(px, W, H);
                    var py = isDay ? (H - y) : y;
                    
                    return Qt.point(px, py);
                }

                // Gündüz Ufuk çizgisi (Zemin) - Arc'ın hemen altında
                Rectangle {
                    id: dayGround
                    visible: WeatherService.isDay
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#33ffffff"
                }

                // Gece Ufuk çizgisi (Zemin) - Arc'ın hemen üstünde
                Rectangle {
                    id: nightGround
                    visible: !WeatherService.isDay
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#33ffffff"
                }

                // Kesik yay
                Canvas {
                    id: celestialArc
                    anchors.left: parent.left
                    anchors.right: parent.right
                    // Gündüz: alt kısmı ground çizgisinin üstünde, Gece: normal dibe kadar
                    anchors.bottom: WeatherService.isDay ? dayGround.top : parent.bottom
                    anchors.bottomMargin: WeatherService.isDay ? 4 : 0
                    // Gece: üst kısmı ground çizgisinin altında, Gündüz: normal tepeye kadar
                    anchors.top: !WeatherService.isDay ? nightGround.bottom : parent.top
                    anchors.topMargin: !WeatherService.isDay ? 4 : 0
                    
                    property bool dayMode: WeatherService.isDay
                    onDayModeChanged: requestPaint()
                    onWidthChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.2)";
                        ctx.lineWidth = 2;
                        
                        var W = width;
                        var H = height;
                        var dashLen = 2;

                        var L_curve = Math.PI * H / 2;

                        // 1. Sol Kavis (Daha sık çentik)
                        var N_curve = Math.max(2, Math.round((L_curve + 1) / 3)); // ~1px gap
                        var gap_curve = (L_curve - N_curve * dashLen) / (N_curve - 1);
                        
                        ctx.beginPath();
                        ctx.setLineDash([dashLen, gap_curve]);
                        ctx.lineDashOffset = 0;
                        if (dayMode) {
                            ctx.arc(H, H, H, Math.PI, Math.PI * 1.5, false);
                        } else {
                            ctx.arc(H, 0, H, Math.PI, Math.PI * 0.5, true);
                        }
                        ctx.stroke();

                        // 2. Orta Düzlük (Daha seyrek çentik)
                        var L_flat = W - 2 * H;
                        if (L_flat > 0) {
                            var N_flat = Math.max(1, Math.round((L_flat - 3) / 5)); // ~3px gap
                            var gap_flat = (L_flat - N_flat * dashLen) / (N_flat + 1);
                            
                            ctx.beginPath();
                            ctx.setLineDash([dashLen, gap_flat]);
                            ctx.lineDashOffset = gap_flat; // Boşluk ile başla ki simetrik olsun
                            if (dayMode) {
                                ctx.moveTo(H, 0);
                                ctx.lineTo(W - H, 0);
                            } else {
                                ctx.moveTo(H, H);
                                ctx.lineTo(W - H, H);
                            }
                            ctx.stroke();
                        }

                        // 3. Sağ Kavis (Daha sık çentik)
                        ctx.beginPath();
                        ctx.setLineDash([dashLen, gap_curve]);
                        ctx.lineDashOffset = 0;
                        if (dayMode) {
                            ctx.arc(W - H, H, H, Math.PI * 1.5, Math.PI * 2, false);
                        } else {
                            ctx.arc(W - H, 0, H, Math.PI * 0.5, 0, true);
                        }
                        ctx.stroke();
                    }
                }

                // Gezegen noktası
                Rectangle {
                    property bool isDay: WeatherService.isDay
                    property real prog: isDay ? Math.max(0, Math.min(1, WeatherService.sunProgress)) : Math.max(0, Math.min(1, WeatherService.nightProgress))
                    property point pos: celestialContainer.getPos(prog, isDay)
                    
                    x: celestialArc.x + pos.x - width / 2
                    y: celestialArc.y + pos.y - height / 2

                    width: 16; height: 16; radius: 12
                    color: isDay ? "#fbbf24" : "#ffffff"
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: 32; height: 32; radius: 16
                        color: parent.color
                        opacity: 0.3
                        z: -1
                    }
                }

                Text {
                    id: sunriseText
                    visible: WeatherService.isDay
                    text: WeatherService.sunrise24h
                    anchors.bottom: celestialArc.bottom
                    anchors.bottomMargin: 4
                    anchors.left: celestialArc.left
                    anchors.leftMargin: 8
                    color: theme ? theme.text : "#9ca3af"
                    font.pixelSize: 11
                }
                Text {
                    id: sunsetText
                    visible: WeatherService.isDay
                    text: WeatherService.sunset24h
                    anchors.bottom: celestialArc.bottom
                    anchors.bottomMargin: 4
                    anchors.right: celestialArc.right
                    anchors.rightMargin: 8
                    color: theme ? theme.text : "#9ca3af"
                    font.pixelSize: 11
                }
                Text {
                    id: sunsetTextNight
                    visible: !WeatherService.isDay
                    text: WeatherService.sunset24h
                    anchors.top: celestialArc.top
                    anchors.topMargin: 4
                    anchors.left: celestialArc.left
                    anchors.leftMargin: 8
                    color: theme ? theme.text : "#9ca3af"
                    font.pixelSize: 11
                }
                Text {
                    id: sunriseTextNight
                    visible: !WeatherService.isDay
                    text: WeatherService.sunrise24h
                    anchors.top: celestialArc.top
                    anchors.topMargin: 4
                    anchors.right: celestialArc.right
                    anchors.rightMargin: 8
                    color: theme ? theme.text : "#9ca3af"
                    font.pixelSize: 11
                }
            }
        }
    }
}
