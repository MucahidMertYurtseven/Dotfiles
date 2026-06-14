// ============================================================
// ANA GİRİŞ DOSYASI (ShellRoot)
// Tüm bar, popup, toast ve OSD bileşenlerini yönetir.
// Quickshell oturum başlatıldığında bu dosya çalıştırılır.
// ============================================================
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import "./bar"
import "./popups"
import qs.services
import qs.components

ShellRoot {
    id: root

    // Tema nesnesi — tüm bileşenler buradan renk/font alır
    Theme { id: theme }

    // Aktif popup'ı kapat (AppState üzerinden)
    function closeActivePopup() {
        AppState.activePopup = ""
    }

    // Popup aç/kapat — aynı isme tekrar tıklanırsa kapat
    function openPopup(name) {
        AppState.activePopup = AppState.activePopup === name ? "" : name
    }

    // Her popup tipi için genişlik döndür
    function popupWidth(type) {
        if (!type) return 1
        switch (type) {
            case "calendar": return 280
            case "notifications": return 320
            case "wifi": return 320
            case "bluetooth": return 320
            case "volume": return 320
            case "brightness": return 320
            case "battery": return 320
            case "power": return 320
            case "media": return 320
            default: return 1
        }
    }
    // Her popup tipi için yükseklik döndür
    function popupHeight(type) {
        if (!type) return 1
        switch (type) {
            case "calendar": return 340
            case "notifications": return 300
            case "wifi": return 340
            case "bluetooth": return 340
            case "volume": return 160
            case "brightness": return 160
            case "battery": return 190
            case "power": return 225
            case "media": return 200
            default: return 1
        }
    }

    // ============================================================
    // BİLDİRİM YÖNETİMİ (ListModel tabanlı)
    // ============================================================

    // Bildirim listesi — ListModel kullanarak Repeater ile uyumlu
    ListModel { id: notifModel }

    // Tek bir bildirimi kaldır
    function _dismissNotif(id) {
        for (var i = 0; i < notifModel.count; i++) {
            if (notifModel.get(i).id === id) {
                var item = notifModel.get(i)
                if (item.ref) {
                    try { item.ref.dismiss() } catch (e) {} // hata yut
                }
                notifModel.remove(i)
                break
            }
        }
    }

    // Tüm bildirimleri temizle
    function _clearAllNotifs() {
        for (var i = notifModel.count - 1; i >= 0; i--) {
            var item = notifModel.get(i)
            if (item.ref) {
                try { item.ref.dismiss() } catch (e) {}
            }
        }
        notifModel.clear()
    }

    // NotificationServer — DBus üzerinden gelen bildirimleri yönetir
    NotificationServer {
        id: notifSvc
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true

        // Yeni bildirim geldiğinde
        onNotification: function(notification) {
            notification.tracked = true

            // ListModel'e en başa ekle (en yeni en üstte)
            notifModel.insert(0, {
                id: notification.id,
                summary: notification.summary || "",
                body: notification.body || "",
                urgency: notification.urgency || 0,
                ref: notification
            })

            // Bildirim kapatıldığında geçmişe ekle
            notification.closed.connect(function(reason) {
                var h = notifHistory.slice()
                h.unshift({
                    summary: notification.summary || "",
                    body: notification.body || "",
                    urgency: notification.urgency || 0
                })
                if (h.length > 20) h = h.slice(0, 20)
                notifHistory = h
            })

            // Rahatsız etmeyin açıksa direkt kapat, değilse toast göster
            if (AppState.dndEnabled) {
                notification.dismiss()
            } else {
                root._addToast({
                    toastId: notification.id,
                    summary: notification.summary || "",
                    body: notification.body || "",
                    urgency: notification.urgency || 0
                })
            }
        }

        // Geçmiş bildirimler (son 20)
        property var notifHistory: []

        // Takip edilen bildirim değiştiğinde AppState'i güncelle
        onTrackedNotificationsChanged: {
            AppState.hasNotifs = trackedNotifications.length > 0
        }
    }

    // ============================================================
    // TOAST (KISA SÜRELİ BİLDİRİM PENECERESİ) YÖNETİMİ
    // ============================================================
    ListModel { id: toastModel }

    // Toast kuyruğuna yeni bildirim ekle
    function _addToast(data) {
        toastModel.insert(0, data)
    }

    // Toast'u kaldır (id ile)
    function _dismissToast(toastId) {
        for (var i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).toastId === toastId) {
                toastModel.remove(i)
                break
            }
        }
    }

    // ============================================================
    // BAR (ÜST PANEL) — her ekran için ayrı
    // ============================================================
    Variants { model: Quickshell.screens;
        PanelWindow {
            property var modelData; screen: modelData
            anchors.top: true; anchors.left: true; anchors.right: true
            margins.top: 2; margins.left: 15; margins.right: 15
            implicitHeight: 44; color: "transparent"
            WlrLayershell.namespace: "quickshell:bar"
            WlrLayershell.layer: WlrLayer.Top

            Item {
                anchors.fill: parent

                // ESC tuşu ile popup kapatma
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        root.closeActivePopup()
                        event.accepted = true
                    }
                }

                // Boş alana tıklayınca popup kapat
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closeActivePopup()
                }

                // Sol bölüm: Çalışma alanları + sistem kaynakları
                Row {
                    id: leftSection
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    WorkspaceIndicator { theme: theme }
                    SysResourceWidget { theme: theme }
                }

                // Orta bölüm: Saat / Medya bilgisi
                ClockWidget {
                    id: clockWidget
                    theme: theme
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        root.openPopup(clockWidget._showMedia ? "media" : "calendar")
                    }
                }

                // Sağ bölüm: Bildirim, Ağ, Ses/Pil, Güç
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    NotificationWidget {
                        theme: theme
                        onNotifyClicked: root.openPopup("notifications")
                    }
                    NetworkWidget {
                        theme: theme
                        onWifiClicked: root.openPopup("wifi")
                        onBluetoothClicked: root.openPopup("bluetooth")
                    }
                    SystemControlsWidget {
                        theme: theme
                        onBatteryClicked: root.openPopup("battery")
                        onBrightnessClicked: root.openPopup("brightness")
                        onVolumeClicked: root.openPopup("volume")
                    }
                    PowerButtonWidget {
                        theme: theme
                        onPowerClicked: root.openPopup("power")
                    }
                }
            }
        }
    }

    // ============================================================
    // POPUP KATMANI — tam ekran overlay, dış tıklamada kapanır
    // ============================================================
    Variants { model: Quickshell.screens;
        PanelWindow {
            property var modelData; screen: modelData
            visible: AppState.activePopup !== ""
            anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
            color: "transparent"
            WlrLayershell.namespace: "quickshell:popup"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: AppState.activePopup !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            // Popup dışına tıklayınca kapat
            MouseArea {
                anchors.fill: parent
                onClicked: root.closeActivePopup()
            }

            // Popup içerik kutusu
            Item {
                id: popupItem
                width: popupWidth(AppState.activePopup) || 1
                height: popupHeight(AppState.activePopup) || 1
                anchors.top: parent.top; anchors.topMargin: 48
                anchors.right: parent.right; anchors.rightMargin: {
                    var p = AppState.activePopup
                    var w = popupWidth(p) || 1
                    if (p === "" || p === "calendar" || p === "media") {
                        return Math.floor((parent.width - w) / 2)
                    }
                    return 15
                }
                opacity: 0
                scale: 0.85
                transformOrigin: Item.Top
                layer.enabled: true
                layer.samplerName: "linear"

                // ActivePopup değişince animasyonu tetikle
                Connections {
                    target: AppState
                    function onActivePopupChanged() {
                        if (AppState.activePopup !== "") {
                            popupCloseAnim.stop()
                            popupOpenAnim.restart()
                        } else {
                            popupOpenAnim.stop()
                            popupCloseAnim.restart()
                        }
                    }
                }

                // Açılma animasyonu (scale bounce + fade)
                SequentialAnimation {
                    id: popupOpenAnim
                    running: false
                    PropertyAction { target: popupItem; property: "scale"; value: 0.85 }
                    PropertyAction { target: popupItem; property: "opacity"; value: 0 }
                    ParallelAnimation {
                        NumberAnimation {
                            target: popupItem; property: "scale"; duration: 450
                            to: 1; easing.type: Easing.OutBack; easing.overshoot: 2.8
                        }
                        NumberAnimation { target: popupItem; property: "opacity"; duration: 350; to: 1; easing.type: Easing.OutCubic }
                    }
                }

                // Kapanma animasyonu
                SequentialAnimation {
                    id: popupCloseAnim
                    running: false
                    ParallelAnimation {
                        NumberAnimation {
                            target: popupItem; property: "scale"; duration: 450
                            to: 0.85; easing.type: Easing.OutBack; easing.overshoot: 2.8
                        }
                        NumberAnimation { target: popupItem; property: "opacity"; duration: 350; to: 0; easing.type: Easing.OutCubic }
                    }
                }

                // Popup içerikleri — hangisi aktifse o görünür
                CalendarPopup    { anchors.fill: parent; visible: AppState.activePopup === "calendar";     theme: theme; open: true }
                NotificationPopup { anchors.fill: parent; visible: AppState.activePopup === "notifications"; theme: theme; open: true; dnd: AppState.dndEnabled; notificationModel: notifModel; onDismissNotif: function(id) { root._dismissNotif(id) }; onClearAll: root._clearAllNotifs(); onToggleDnd: AppState.dndEnabled = !AppState.dndEnabled }
                WifiPopup        { anchors.fill: parent; visible: AppState.activePopup === "wifi";           theme: theme; open: true }
                BluetoothPopup   { anchors.fill: parent; visible: AppState.activePopup === "bluetooth";      theme: theme; open: true }
                VolumePopup      { anchors.fill: parent; visible: AppState.activePopup === "volume";         theme: theme; open: true }
                BrightnessPopup  { anchors.fill: parent; visible: AppState.activePopup === "brightness";     theme: theme; open: true }
                PowerPopup       { anchors.fill: parent; visible: AppState.activePopup === "battery";        theme: theme; open: true; mode: PowerService.mode; batteryPct: UPower.displayDevice?.ready ? Math.round((UPower.displayDevice.percentage || 0) * 100) : 0; charging: UPower.displayDevice?.state === 1 || UPower.displayDevice?.state === 4; onModeSelected: function(m) { PowerService.setMode(m) } }
                PowerMenuPopup   { anchors.fill: parent; visible: AppState.activePopup === "power";          theme: theme; open: true }
                MediaPopup       { anchors.fill: parent; visible: AppState.activePopup === "media";          theme: theme; open: true }

                // ESC tuşu ile popup kapat
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        root.closeActivePopup()
                        event.accepted = true
                    }
                }
                Keys.priority: Keys.BeforeItem
            }
        }
    }

    // ============================================================
    // TOAST PENECERESİ — bildirimler sağ üstte kısa süreli görünür
    // ============================================================
    Variants { model: Quickshell.screens;
        PanelWindow {
            property var modelData; screen: modelData
            visible: toastModel.count > 0
            anchors.top: true
            anchors.right: true
            margins.top: 50
            margins.right: 15
            exclusiveZone: 0
            color: "transparent"
            implicitWidth: 320
            implicitHeight: toastModel.count * 68 + 80
            WlrLayershell.namespace: "quickshell:toast"
            WlrLayershell.layer: WlrLayer.Overlay

            Item {
                id: toastContainer
                anchors.fill: parent

                // Toastları listele (her biri sabit y'de, diğerleri hareket etmez)
                Repeater {
                    model: toastModel
                    delegate: NotificationToast {
                        y: index * 68
                        notifId: model.toastId
                        theme: theme
                        summary: model.summary
                        body: model.body
                        urgency: model.urgency
                        onDismissed: function(id) { root._dismissToast(id) }
                        onClicked: function(id) { root.openPopup("notifications") }
                    }
                }
            }
        }
    }

    // ============================================================
    // OSD (EKAN İÇİ GÖSTERGE) — ses/parlaklık/klavye düzeni
    // ============================================================
    Variants { model: Quickshell.screens;
        PanelWindow {
            property var modelData; screen: modelData
            visible: AppState.osdType !== ""
            anchors.bottom: true
            margins.bottom: 90
            exclusiveZone: 0
            color: "transparent"
            implicitWidth: 180
            implicitHeight: 70
            WlrLayershell.namespace: "quickshell:osd"
            WlrLayershell.layer: WlrLayer.Overlay

            Item {
                anchors { fill: parent; margins: 8 }
                transformOrigin: Item.Center
                opacity: AppState.osdType !== "" ? 1 : 0
                scale: AppState.osdType !== "" ? 1 : 0.8

                Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

                // OSD arkaplan
                Rectangle {
                    id: osdBg
                    anchors.fill: parent
                    radius: 12
                    color: theme ? theme.bgPopupBlur : "#202020"
                }

                // OSD içerik: ikon + yüzde
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    ColorizedIcon {
                        source: {
                            var icons = Quickshell.shellDir + "/bar/icons/"
                            switch (AppState.osdType) {
                                case "volume": {
                                    if (AudioService.muted) return icons + "audio-volume-muted-symbolic.svg"
                                    if (AudioService.volume === 0) return icons + "audio-volume-off-symbolic.svg"
                                    if (AudioService.volume >= 0.50) return icons + "audio-volume-high-symbolic.svg"
                                    return icons + "audio-volume-medium-symbolic.svg"
                                }
                                case "brightness": {
                                    var pct = Math.round(AppState.osdValue * 100)
                                    return icons + (pct > 60 ? "brightness-high-symbolic.svg"
                                        : pct > 20 ? "brightness-medium-symbolic.svg"
                                        : pct > 0 ? "brightness-low-symbolic.svg"
                                        : "brightness-empty-symbolic.svg")
                                }
                                case "layout": return icons + "input-keyboard-symbolic.svg"
                            }
                            return ""
                        }
                        iconSize: 22
                        iconColor: theme.text
                    }

                    Text {
                        text: {
                            switch (AppState.osdType) {
                                case "volume": return Math.round(AppState.osdValue * 100) + "%"
                                case "brightness": return Math.round(AppState.osdValue * 100) + "%"
                                case "layout": return AppState.osdValue > 0 ? "TR" : "US"
                            }
                            return ""
                        }
                        color: theme.text
                        font.pixelSize: 18
                        font.bold: true
                        font.family: theme.fontFamily
                    }
                }

                // Klavye düzeni OSD'sine tıklanınca sonraki layout'a geç
                MouseArea {
                    anchors.fill: parent
                    cursorShape: AppState.osdType === "layout" ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (AppState.osdType === "layout") {
                            Quickshell.exec(["hyprctl", "switchxkblayout", "all", "next"])
                            AppState.showOsd("layout", AppState.osdValue > 0 ? 0 : 1)
                        }
                    }
                }
            }

            // OSD'yi 1.5sn sonra gizle
            Timer {
                id: hideTimer
                interval: 1500
                repeat: false
                running: false
                onTriggered: AppState.osdType = ""
            }

            Connections {
                target: AppState
                function onOsdTimerChanged() {
                    if (AppState.osdType !== "") hideTimer.restart()
                }
            }
        }
    }

    // ============================================================
    // OSD TETİKLEYİCİLER — ses/parlaklık değişince OSD göster
    // ============================================================

    // 500ms gecikmeli başlat (başlangıçtaki ani değerleri yok say)
    property bool _osdReady: false
    Timer { interval: 500; running: true; onTriggered: _osdReady = true }

    Connections {
        target: AudioService
        function onVolumeChanged() {
            if (_osdReady && AppState.activePopup !== "volume")
                AppState.showOsd("volume", AudioService.volume)
        }
    }

    Connections {
        target: BrightnessService
        function onValueChanged() {
            if (_osdReady && AppState.activePopup !== "brightness")
                AppState.showOsd("brightness", BrightnessService.value)
        }
    }

    // ============================================================
    // KLAVYE DÜZENİ İZLEME — Hyprland event socket üzerinden
    // ============================================================

    property string _lastLayout: ""

    // Hyprland socket'ten aktif layout değişimlerini dinle
    Process {
        id: layoutMonitor
        command: ["sh", "-c", "D=$XDG_RUNTIME_DIR/hypr; I=$(ls -t $D 2>/dev/null | head -1); [ -n \"$I\" ] && socat - \"UNIX-CONNECT:$D/$I/.socket2.sock\""]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var msg = String(line).trim()
                var re = /activelayout>>[^,]+,(.+)/
                var match = re.exec(msg)
                if (match) {
                    var layout = match[1]
                    if (layout && layout !== root._lastLayout) {
                        root._lastLayout = layout
                        AppState.showOsd("layout", layout.match(/Turkish|Türkçe/)? 1 : 0)
                    }
                }
            }
        }
    }

    // Yedek: socket ölürse poll ile kontrol et
    Process {
        id: layoutPoll
        command: ["sh", "-c", "hyprctl devices -j | sed -n 's/.*\"active_keymap\": \"\\([^\"]*\\)\".*/\\1/p' | head -1"]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                var layout = String(line).trim()
                if (layout && layout !== _lastLayout) {
                    _lastLayout = layout
                    AppState.showOsd("layout", layout.match(/Turkish|Türkçe/)? 1 : 0)
                }
            }
        }
    }

    // 30sn'de bir layoutMonitor hala çalışıyor mu kontrol et
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            if (!layoutMonitor.running) {
                layoutMonitor.running = true
                layoutPoll.running = true
            }
        }
    }
}
