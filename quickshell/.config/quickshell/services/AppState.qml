// ============================================================
// UYGULAMA DURUMU (Singleton) — popup/OSD/DND durumlarını
// tüm bileşenler arasında paylaşmak için merkezi state
// ============================================================
pragma Singleton
import QtQuick

QtObject {
    property string activePopup: ""          // hangi popup açık
    property bool dndEnabled: false          // rahatsız etmeyin
    property bool hasNotifs: false           // okunmamış bildirim var mı

    // OSD durumu
    property string osdType: ""      // "volume" | "brightness" | "layout"
    property real osdValue: 0
    property int osdTimer: 0

    function showOsd(type, value) {
        osdType = type
        osdValue = value
        osdTimer++
    }

    function toggleDnd() {
        dndEnabled = !dndEnabled
    }
}
