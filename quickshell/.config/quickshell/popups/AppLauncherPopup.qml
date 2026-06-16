import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services

Item {
    id: root
    property Item theme: null
    property bool open: false

    readonly property string _script: Quickshell.shellDir + "/scripts/list_apps.py"

    property var _allApps: []
    property var _favorites: []
    property var _filteredApps: []
    property int _selectedIndex: 0

    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgPopupBlur : "#8c0c1a33"
        radius: theme ? theme.popupRadius : 12
        border.color: theme ? theme.border : "#66374d75"
        border.width: 1
        clip: true
    }

    onVisibleChanged: {
        if (visible) _loadApps()
    }
    Component.onCompleted: _loadApps()

    function _loadApps() {
        listProc.running = true
    }

    Process {
        id: listProc
        command: ["python3", root._script]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    var data = JSON.parse(line)
                    root._allApps = data.apps || []
                    root._favorites = data.favorites || []
                    root._filter()
                } catch(e) {}
            }
        }
    }

    Process {
        id: favProc
        command: []
        running: false
        onExited: { _loadApps() }
    }

    function _toggleFav(file) {
        favProc.command = ["python3", root._script, "favorite", file]
        favProc.running = true
    }

    function _filter() {
        var q = searchField.text.toLowerCase().trim()
        var favSet = {}
        for (var fi = 0; fi < root._favorites.length; fi++)
            favSet[root._favorites[fi]] = true

        var result = []
        for (var i = 0; i < root._allApps.length; i++) {
            var a = root._allApps[i]
            if (q === "" || a.name.toLowerCase().indexOf(q) >= 0 || a.comment.toLowerCase().indexOf(q) >= 0) {
                result.push(a)
            }
        }

        result.sort(function(a, b) {
            var af = favSet[a.file] ? 1 : 0
            var bf = favSet[b.file] ? 1 : 0
            if (af !== bf) return bf - af
            return a.name.localeCompare(b.name)
        })

        root._filteredApps = result
        root._selectedIndex = 0
    }

    function _launchSelected() {
        if (_selectedIndex >= 0 && _selectedIndex < root._filteredApps.length) {
            var app = root._filteredApps[_selectedIndex]
            if (app.exec) {
                var cmd = app.exec
                cmd = cmd.replace(/%[a-zA-Z]/g, "")
                cmd = cmd.replace(/%%/g, "%")
                cmd = cmd.trim()
                Quickshell.execDetached(["sh", "-c", cmd])
                AppState.activePopup = ""
            }
        }
    }

    ColumnLayout {
        anchors { fill: parent; margins: theme?.popupPad ?? 12 }
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 6
            color: theme ? theme.hover : "#5376b6"

            TextInput {
                id: searchField
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                verticalAlignment: Text.AlignVCenter
                color: theme ? theme.textBright : "#f7f7f7"
                font.pixelSize: 13
                font.family: theme ? theme.fontFamily : "monospace"
                clip: true

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 0
                    text: "Uygulama ara..."
                    color: theme ? theme.textMuted : "#7f95bc"
                    font: parent.font
                    visible: parent.text === ""
                }

                onTextChanged: root._filter()
                Keys.onUpPressed: (event) => {
                    if (root._selectedIndex > 0) root._selectedIndex--
                    event.accepted = true
                }
                Keys.onDownPressed: (event) => {
                    if (root._selectedIndex < root._filteredApps.length - 1) root._selectedIndex++
                    event.accepted = true
                }
                Keys.onReturnPressed: (event) => {
                    root._launchSelected()
                    event.accepted = true
                }
                Keys.onEscapePressed: (event) => {
                    AppState.activePopup = ""
                    event.accepted = true
                }
                Component.onCompleted: forceActiveFocus()
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 1
            color: theme ? theme.border : "#66374d75"
            opacity: 0.6
        }

        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root._filteredApps
            currentIndex: root._selectedIndex
            spacing: 2

            onCurrentIndexChanged: {
                root._selectedIndex = currentIndex
            }

            delegate: Rectangle {
                id: delegateRoot
                width: appList.width
                implicitHeight: 38
                radius: 6
                color: {
                    if (index === root._selectedIndex) return theme ? theme.hover : "#5376b6"
                    if (ma.containsMouse) return theme ? theme.hover : "#5376b6"
                    return "transparent"
                }

                Behavior on color { ColorAnimation { duration: 80 } }

                // Main click handler (defined first so it's behind the star)
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root._selectedIndex = index
                        root._launchSelected()
                    }
                    onEntered: { root._selectedIndex = index }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8; anchors.rightMargin: 8
                    spacing: 6

                    Image {
                        id: iconImg
                        source: modelData.icon ? "file://" + modelData.icon : ""
                        sourceSize { width: 48; height: 48 }
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: status === Image.Ready
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "\u2699"
                        color: theme ? theme.text : "#c2c3c6"
                        font.pixelSize: 18
                        visible: !iconImg.visible
                        Layout.preferredWidth: 28
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: modelData.name
                        color: index === root._selectedIndex
                            ? (theme ? theme.textBright : "#f7f7f7")
                            : (theme ? theme.text : "#c2c3c6")
                        font.pixelSize: 12
                        font.family: theme ? theme.fontFamily : "monospace"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: {
                            var favSet = {}
                            for (var fi = 0; fi < root._favorites.length; fi++)
                                favSet[root._favorites[fi]] = true
                            return favSet[modelData.file] ? "\u2605" : "\u2606"
                        }
                        color: {
                            var favSet = {}
                            for (var fi = 0; fi < root._favorites.length; fi++)
                                favSet[root._favorites[fi]] = true
                            return favSet[modelData.file] ? (theme ? theme.warn : "#d09caa") : (theme ? theme.textMuted : "#7f95bc")
                        }
                        font.pixelSize: 20
                        Layout.preferredWidth: 28
                        Layout.alignment: Qt.AlignVCenter

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root._toggleFav(modelData.file)
                                root._selectedIndex = index
                            }
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root._filteredApps.length + " uygulama"
            color: theme ? theme.textMuted : "#7f95bc"
            font.pixelSize: 10
            font.family: theme ? theme.fontFamily : "monospace"
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
