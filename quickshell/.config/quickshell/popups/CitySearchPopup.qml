import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services

Item {
    id: root
    property Item theme: null
    property bool open: false

    property var _allCities: []
    property var _filteredCities: []
    property int _selectedIndex: 0

    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgPopupBlur : "#b2143630"
        radius: theme ? theme.popupRadius : 12
        border.color: theme ? theme.border : "#6637756a"
        border.width: 1
        clip: true
    }

    onVisibleChanged: {
        if (visible) {
            _loadCities()
            searchField.text = ""
            searchField.forceActiveFocus()
        }
    }
    Component.onCompleted: _loadCities()

    function _loadCities() {
        if (_allCities.length > 0) {
            _filter()
            return
        }
        listProc.running = true
    }

    Process {
        id: listProc
        command: ["sh", "-c", "cat ~/.config/quickshell/cities.txt"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim() !== "") {
                    root._allCities.push(line.trim())
                }
            }
        }
        onExited: root._filter()
    }

    function _filter() {
        var q = searchField.text.toLowerCase().trim()
        
        var result = []
        for (var i = 0; i < root._allCities.length; i++) {
            var c = root._allCities[i]
            if (q === "" || c.toLowerCase().indexOf(q) >= 0) {
                result.push(c)
            }
        }

        root._filteredCities = result
        root._selectedIndex = 0
    }

    function _launchSelected() {
        if (_selectedIndex >= 0 && _selectedIndex < root._filteredCities.length) {
            var city = root._filteredCities[_selectedIndex]
            WeatherService.city = city
            saveCityProc.command = ["sh", "-c", "echo '" + city + "' > ~/.config/quickshell/weather_city.txt"]
            saveCityProc.running = true
            AppState.citySearchOpen = false
            searchField.text = ""
        } else if (searchField.text.trim() !== "") {
            // Allow custom city
            var customCity = searchField.text.trim()
            WeatherService.city = customCity
            saveCityProc.command = ["sh", "-c", "echo '" + customCity + "' > ~/.config/quickshell/weather_city.txt"]
            saveCityProc.running = true
            AppState.citySearchOpen = false
            searchField.text = ""
        }
    }

    Process {
        id: saveCityProc
        command: []
        running: false
        onExited: WeatherService.fetchWeather()
    }

    ColumnLayout {
        anchors { fill: parent; margins: theme?.popupPad ?? 12 }
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 8
            color: theme ? theme.hover : "#53b6a4"
            border.color: searchField.activeFocus ? (theme ? theme.active : "#a6ddd3") : "transparent"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text {
                    text: "search"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                    color: theme ? theme.textMuted : "#7fbcb1"
                }

                TextInput {
                    id: searchField
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                    color: theme ? theme.textBright : "#f7f7f7"
                    font.pixelSize: 14
                    font.family: "Inter"
                    clip: true

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 0
                        text: "Şehir ara veya yazın..."
                        color: theme ? theme.textMuted : "#7fbcb1"
                        font: parent.font
                        visible: parent.text === ""
                    }

                    onTextChanged: root._filter()
                    Keys.onUpPressed: (event) => {
                        if (root._selectedIndex > 0) root._selectedIndex--
                        event.accepted = true
                    }
                    Keys.onDownPressed: (event) => {
                        if (root._selectedIndex < root._filteredCities.length - 1) root._selectedIndex++
                        event.accepted = true
                    }
                    Keys.onReturnPressed: (event) => {
                        root._launchSelected()
                        event.accepted = true
                    }
                    Keys.onEscapePressed: (event) => {
                        AppState.citySearchOpen = false
                        event.accepted = true
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 1
            color: theme ? theme.border : "#6637756a"
            opacity: 0.6
        }

        ListView {
            id: cityList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root._filteredCities
            currentIndex: root._selectedIndex
            spacing: 4

            onCurrentIndexChanged: {
                root._selectedIndex = currentIndex
            }

            delegate: Rectangle {
                id: delegateRoot
                width: cityList.width
                implicitHeight: 38
                radius: 8
                color: {
                    if (index === root._selectedIndex) return theme ? theme.hover : "#53b6a4"
                    if (ma.containsMouse) return theme ? theme.hover : "#53b6a4"
                    return "transparent"
                }

                Behavior on color { ColorAnimation { duration: 100 } }

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
                    anchors.leftMargin: 12; anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "location_on"
                        font.family: "Material Symbols Outlined"
                        color: index === root._selectedIndex
                            ? (theme ? theme.active : "#a6ddd3")
                            : (theme ? theme.textMuted : "#7fbcb1")
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: modelData
                        color: index === root._selectedIndex
                            ? (theme ? theme.textBright : "#f7f7f7")
                            : (theme ? theme.text : "#c2c6c5")
                        font.pixelSize: 14
                        font.family: "Inter"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root._filteredCities.length + " sonuç"
            color: theme ? theme.textMuted : "#7fbcb1"
            font.pixelSize: 11
            font.family: "Inter"
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
