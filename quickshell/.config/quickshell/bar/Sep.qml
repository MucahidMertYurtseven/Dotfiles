// ============================================================
// AYRAÇ — bar modülleri arasında dikey çizgi
// ============================================================
import QtQuick

Item {
    property Item theme: null
    width: 1; height: 22

    Rectangle {
        anchors.centerIn: parent
        width: 1; height: 22
        color: theme ? theme.border : "#6675376d"
        opacity: 0.6
    }
}
