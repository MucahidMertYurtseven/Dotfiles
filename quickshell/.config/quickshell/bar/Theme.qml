// ============================================================
// TEMA — tüm bileşenlerin renk/boyut/font tanımları
// Tek bir yerden değiştirilebilir koyu tema
// ============================================================
import QtQuick

QtObject {
    readonly property color bgDark:      "#202020"  // bar arkaplanı
    readonly property color bgPopup:     "#2a2a2a"  // popup arkaplan (kullanılmıyor)
    readonly property color bgPopupBlur: "#202020"  // popup arkaplan
    readonly property color text:        "#c5c5c5"  // normal metin
    readonly property color textBright:  "#ffffff"  // parlak metin
    readonly property color textMuted:   "#7e8099"  // soluk metin
    readonly property color border:      "#323232"  // kenarlık
    readonly property color hover:       "#606060"  // hover arkaplan
    readonly property color active:      "#b0b0b0"  // aktif öğe
    readonly property color activeText:  "#262626"  // aktif öğe metni
    readonly property color empty:       "#414141"  // boş/pasif öğe
    readonly property color warn:        "#f38ba8"  // uyarı rengi
    readonly property color green:       "#4ade80"  // yeşil (bağlı/bilgi)

    readonly property int barHeight:    50
    readonly property int moduleRadius: 8
    readonly property int moduleHeight: 16
    readonly property int popupRadius:  12
    readonly property int popupPad:     12
    readonly property int popupWidth:   320

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}
