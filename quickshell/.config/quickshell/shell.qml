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

    // Canlı tema — JSON dosyası değişince güncellenir, reload olmaz
    Item {
        id: liveTheme

        property color bgDark:      "#242424"
        Behavior on bgDark      { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }
        property color bgBar:       "#40242424"
        Behavior on bgBar       { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }
        property color bgPopup:     "#2e2e2e"
        Behavior on bgPopup     { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }
        property color bgPopupBlur: "#99242424"
        Behavior on bgPopupBlur { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }
        property color text:        "#c5c5c5"
        Behavior on text        { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }
        property color textBright:  "#f7f7f7"
        Behavior on textBright  { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }
        property color textMuted:   "#808080"
        Behavior on textMuted   { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }
        property color border:      "#66343434"
        Behavior on border      { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }
        property color hover:       "#626262"
        Behavior on hover       { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }
        property color active:      "#b0b0b0"
        Behavior on active      { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }
        property color activeText:  "#272727"
        Behavior on activeText  { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }
        property color empty:       "#434343"
        Behavior on empty       { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }
        property color warn:        "#f38ba8"
        Behavior on warn        { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }
        property color green:       "#4ade80"
        Behavior on green       { ColorAnimation { duration: 1200; easing.type: Easing.OutQuart } }

        readonly property color base:     liveTheme.bgDark
        readonly property color mantle:   liveTheme.bgPopup
        readonly property color surface1: liveTheme.empty
        readonly property color surface2: liveTheme.hover

        readonly property int barHeight:    50
        readonly property int moduleRadius: 8
        readonly property int moduleHeight: 16
        readonly property int popupRadius:  12
        readonly property int popupPad:     12
        readonly property int popupWidth:   320

        readonly property string fontFamily: "JetBrainsMono Nerd Font"

        Component.onCompleted: {
            var comp = Qt.createComponent("./bar/Theme.qml")
            if (comp.status === Component.Ready) {
                var t = comp.createObject(null)
                liveTheme.bgDark      = t.bgDark
                liveTheme.bgBar       = t.bgBar
                liveTheme.bgPopup     = t.bgPopup
                liveTheme.bgPopupBlur = t.bgPopupBlur
                liveTheme.text        = t.text
                liveTheme.textBright  = t.textBright
                liveTheme.textMuted   = t.textMuted
                liveTheme.border      = t.border
                liveTheme.hover       = t.hover
                liveTheme.active      = t.active
                liveTheme.empty       = t.empty
                liveTheme.activeText  = t.activeText
                liveTheme.warn        = t.warn
                liveTheme.green       = t.green
                t.destroy()
            }
            // Başlangıçta her zaman en güncel JSON temasını oku
            themeApplyProc.running = true
        }

        property int revision: 0
    }

    // Tema JSON dosyasını izle — generate_theme.py --live bu dosyayı yazar
    // inotifywait ile event-driven izleme: dosya değişince anında (≤10ms) tetiklenir,
    // polling yok, CPU yükü sıfır.
    property string _lastThemeJson: ""
    property bool _preloadedWallpaper: false
    Timer {
        running: true
        interval: 4000
        onTriggered: root._preloadedWallpaper = true
    }

    // inotifywait: /tmp/qs_theme.json dosyası her yazıldığında bir satır basar
    // → themeApplyProc okur ve temayı anında günceller
    Process {
        id: themeWatcher
        command: ["sh", "-c",
            // Dosya yoksa önce oluştur (inotifywait var olan dosyayı izler)
            "mkdir -p /tmp && touch /tmp/qs_theme.json; " +
            "inotifywait -m -q -e close_write --format '%f' /tmp/qs_theme.json 2>/dev/null"
        ]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                // Dosya yazıldı sinyali geldi — hemen oku
                themeApplyProc.running = true
            }
        }
        // inotifywait çökürlerse yeniden başlat
        onRunningChanged: {
            if (!running) {
                watcherRestartTimer.restart()
            }
        }
    }
    // inotifywait crash/exit durumunda 2sn sonra yeniden başlat
    Timer {
        id: watcherRestartTimer
        interval: 2000
        repeat: false
        onTriggered: { themeWatcher.running = true }
    }

    // Gerçek tema okuyucu — inotifywait sinyal verince çalışır
    Process {
        id: themeApplyProc
        command: ["sh", "-c", "cat /tmp/qs_theme.json 2>/dev/null || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = this.text.trim()
                if (!raw || raw === root._lastThemeJson) return
                root._lastThemeJson = raw
                try {
                    var p = JSON.parse(raw)
                    var changed = 0
                    if (p.bgDark      !== undefined) { liveTheme.bgDark      = p.bgDark;      changed++ }
                    if (p.bgBar       !== undefined) { liveTheme.bgBar       = p.bgBar;       changed++ }
                    if (p.bgPopup     !== undefined) { liveTheme.bgPopup     = p.bgPopup;     changed++ }
                    if (p.bgPopupBlur !== undefined) { liveTheme.bgPopupBlur = p.bgPopupBlur; changed++ }
                    if (p.text        !== undefined) { liveTheme.text        = p.text;        changed++ }
                    if (p.textBright  !== undefined) { liveTheme.textBright  = p.textBright;  changed++ }
                    if (p.textMuted   !== undefined) { liveTheme.textMuted   = p.textMuted;   changed++ }
                    if (p.border      !== undefined) { liveTheme.border      = p.border;      changed++ }
                    if (p.hover       !== undefined) { liveTheme.hover       = p.hover;       changed++ }
                    if (p.active      !== undefined) { liveTheme.active      = p.active;      changed++ }
                    if (p.activeText  !== undefined) { liveTheme.activeText  = p.activeText;  changed++ }
                    if (p.empty       !== undefined) { liveTheme.empty       = p.empty;       changed++ }
                    if (p.warn        !== undefined) { liveTheme.warn        = p.warn;        changed++ }
                    if (p.green       !== undefined) { liveTheme.green       = p.green;       changed++ }
                    liveTheme.revision++
                    console.log("Theme updated (inotify):", changed, "props, rev:", liveTheme.revision)
                } catch (e) {
                    console.log("Theme parse error:", String(e))
                }
            }
        }
    }

    // Aktif popup'ı kapat (AppState üzerinden)
    function closeActivePopup() {
        AppState.activePopup = ""
    }

    // Popup aç/kapat — aynı isme tekrar tıklanırsa kapat
    function openPopup(name) {
        AppState.activePopup = AppState.activePopup === name ? "" : name
    }

    // File-based launcher trigger via inotifywait (Sıfır CPU Kullanımı!)
    Process {
        id: launcherWatcher
        command: ["sh", "-c", "touch /tmp/quickshell-launcher; inotifywait -m -q -e attrib --format '%w' /tmp/quickshell-launcher 2>/dev/null"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                root.openPopup("launcher")
            }
        }
        onRunningChanged: if(!running) restartTimerLauncher.restart()
    }
    Timer { id: restartTimerLauncher; interval: 2000; onTriggered: launcherWatcher.running = true }

    // File-based wallpaper trigger via inotifywait (Sıfır CPU Kullanımı!)
    Process {
        id: wallpaperWatcher
        command: ["sh", "-c", "touch /tmp/quickshell-wallpaper; inotifywait -m -q -e attrib --format '%w' /tmp/quickshell-wallpaper 2>/dev/null"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                root.openPopup("wallpaper")
            }
        }
        onRunningChanged: if(!running) restartTimerWallpaper.restart()
    }
    Timer { id: restartTimerWallpaper; interval: 2000; onTriggered: wallpaperWatcher.running = true }

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
            case "weather": return 620
            case "launcher": return 400
            case "wallpaper": return Screen.width * 0.60
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
            case "weather": return 525
            case "launcher": return 450
            case "wallpaper": return Screen.height * 0.50
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
                    WorkspaceIndicator { theme: liveTheme }
                    WeatherWidget {
                        theme: liveTheme
                        onClicked: root.openPopup("weather")
                    }
                    SysResourceWidget { theme: liveTheme }
                }

                // Orta bölüm: Saat / Medya bilgisi
                ClockWidget {
                    id: clockWidget
                    theme: liveTheme
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
                        theme: liveTheme
                        onNotifyClicked: root.openPopup("notifications")
                    }
                    NetworkWidget {
                        theme: liveTheme
                        onWifiClicked: root.openPopup("wifi")
                        onBluetoothClicked: root.openPopup("bluetooth")
                    }
                    SystemControlsWidget {
                        theme: liveTheme
                        onBatteryClicked: root.openPopup("battery")
                        onBrightnessClicked: root.openPopup("brightness")
                        onVolumeClicked: root.openPopup("volume")
                    }
                    PowerButtonWidget {
                        theme: liveTheme
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
            visible: AppState.activePopup !== "" || AppState.citySearchOpen
            anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
            margins.top: 48
            color: "transparent"
            WlrLayershell.namespace: "quickshell:popup"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: AppState.activePopup !== "" || AppState.citySearchOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            // Popup dışına tıklayınca kapat
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (AppState.citySearchOpen) AppState.citySearchOpen = false
                    else root.closeActivePopup()
                }
            }

            // Popup içerik kutusu
            Item {
                id: popupItem
                width: popupWidth(AppState.activePopup) || 1
                height: popupHeight(AppState.activePopup) || 1
                anchors.top: parent.top; anchors.topMargin: AppState.activePopup === "wallpaper" ? (parent.height - height) / 2 : 0
                x: {
                    var p = AppState.activePopup
                    var w = popupWidth(p) || 1
                    if (p === "weather") {
                        return 15
                    }
                    if (p === "" || p === "calendar" || p === "media" || p === "launcher" || p === "wallpaper") {
                        return Math.floor((parent.width - w) / 2)
                    }
                    return parent.width - w - 15
                }
                opacity: 0
                scale: 0.88
                transformOrigin: Item.Top

                // ActivePopup değişince animasyonu tetikle
                Connections {
                    target: AppState
                    function onActivePopupChanged() {
                        if (AppState.activePopup !== "") {
                            popupCloseAnim.stop()
                            // Wallpaper popup manages its own animation
                            if (AppState.activePopup !== "wallpaper") {
                                popupOpenAnim.restart()
                            } else {
                                popupItem.scale = 1
                                popupItem.opacity = 1
                            }
                        } else {
                            popupOpenAnim.stop()
                            popupCloseAnim.restart()
                        }
                    }
                }

                // Açılma animasyonu (QML tarafındaki animasyonlar kapatıldı)
                SequentialAnimation {
                    id: popupOpenAnim
                    running: false
                    PropertyAction { target: popupItem; property: "scale"; value: 1 }
                    PropertyAction { target: popupItem; property: "opacity"; value: 1 }
                }

                // Kapanma animasyonu
                SequentialAnimation {
                    id: popupCloseAnim
                    running: false
                    PropertyAction { target: popupItem; property: "scale"; value: 1 }
                    PropertyAction { target: popupItem; property: "opacity"; value: 0 }
                }

                // Popup içerikleri — Loader ile sync yüklenir, animasyon başlamadan hazır olur
                Loader {
                    anchors.fill: parent
                    active: true
                    sourceComponent: CalendarPopup {
                        visible: AppState.activePopup === "calendar"
                        theme: liveTheme
                        open: true
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: true
                    sourceComponent: NotificationPopup {
                        visible: AppState.activePopup === "notifications"
                        theme: liveTheme
                        open: true
                        dnd: AppState.dndEnabled
                        notificationModel: notifModel
                        onDismissNotif: function(id) { root._dismissNotif(id) }
                        onClearAll: root._clearAllNotifs()
                        onToggleDnd: AppState.dndEnabled = !AppState.dndEnabled
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: true
                    sourceComponent: WifiPopup {
                        visible: AppState.activePopup === "wifi"
                        theme: liveTheme
                        open: true
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: true
                    sourceComponent: BluetoothPopup {
                        visible: AppState.activePopup === "bluetooth"
                        theme: liveTheme
                        open: true
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: true
                    sourceComponent: VolumePopup {
                        visible: AppState.activePopup === "volume"
                        theme: liveTheme
                        open: true
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: true
                    sourceComponent: BrightnessPopup {
                        visible: AppState.activePopup === "brightness"
                        theme: liveTheme
                        open: true
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: true
                    sourceComponent: PowerPopup {
                        visible: AppState.activePopup === "battery"
                        theme: liveTheme
                        open: true
                        mode: PowerService.mode
                        batteryPct: UPower.displayDevice?.ready ? Math.round((UPower.displayDevice.percentage || 0) * 100) : 0
                        charging: UPower.displayDevice?.state === 1 || UPower.displayDevice?.state === 4
                        onModeSelected: function(m) { PowerService.setMode(m) }
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: true
                    sourceComponent: PowerMenuPopup {
                        visible: AppState.activePopup === "power"
                        theme: liveTheme
                        open: true
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: true
                    sourceComponent: MediaPopup {
                        visible: AppState.activePopup === "media"
                        theme: liveTheme
                        open: true
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: true
                    sourceComponent: AppLauncherPopup {
                        visible: AppState.activePopup === "launcher"
                        theme: liveTheme
                        open: true
                    }
                }
                Loader {
                    id: weatherLoader
                    anchors.fill: parent
                    active: true
                    sourceComponent: WeatherPopup {
                        visible: AppState.activePopup === "weather"
                        theme: liveTheme
                        open: true
                    }
                }
                Loader {
                    id: wallpaperLoader
                    anchors.fill: parent
                    active: root._preloadedWallpaper || AppState.activePopup === "wallpaper"
                    asynchronous: true
                    sourceComponent: WallpaperPopup {
                        visible: AppState.activePopup === "wallpaper"
                        palette: liveTheme
                    }
                    onLoaded: wallpaperLoader.active = true
                }

                // ESC tuşu ile popup kapat
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        if (AppState.citySearchOpen) AppState.citySearchOpen = false
                        else root.closeActivePopup()
                        event.accepted = true
                    }
                }
                Keys.priority: Keys.BeforeItem
            }

            Item {
                id: citySearchContainer
                visible: AppState.citySearchOpen
                width: 320
                height: (AppState.activePopup === "weather" && weatherLoader.item) ? weatherLoader.item.implicitHeight : popupItem.height
                anchors.top: parent.top
                x: popupItem.x + popupItem.width + 15
                opacity: visible ? 1 : 0
                scale: visible ? 1 : 0.88
                transformOrigin: Item.Top
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

                Loader {
                    anchors.fill: parent
                    active: true
                    sourceComponent: CitySearchPopup {
                        visible: AppState.citySearchOpen
                        theme: liveTheme
                        open: AppState.citySearchOpen
                    }
                }
            }

            // Kısayol: Alt+Space ile uygulama başlatıcı
            Shortcut {
                sequence: "Alt+Space"
                onActivated: {
                    root.openPopup("launcher")
                }
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
                        theme: liveTheme
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
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                // OSD arkaplan
                Rectangle {
                    id: osdBg
                    anchors.fill: parent
                    radius: 12
                    color: liveTheme ? liveTheme.bgPopupBlur : "#202020"
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
                        iconColor: liveTheme.text
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
                        color: liveTheme.text
                        font.pixelSize: 18
                        font.bold: true
                        font.family: liveTheme.fontFamily
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
