// ============================================================
// AYRAÇ — bar modülleri arasında dikey çizgi
// ============================================================
import QtQuick

Item {
    property var theme: null
    width: 1; height: 22

    Rectangle {
        anchors.centerIn: parent
        width: 1; height: 22
        color: theme ? theme.border : "#323232"
        opacity: 0.6
    }
}
