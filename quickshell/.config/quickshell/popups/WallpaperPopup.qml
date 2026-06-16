import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.services

Item {
    id: root
    property Item palette: null

    readonly property color bgColor:   palette ? palette.bgPopupBlur : "#90242424"
    readonly property color textColor: palette ? palette.text  : "#c2c3c6"
    readonly property color border:    palette ? palette.border : "#66374d75"
    readonly property string fontFamily: palette ? palette.fontFamily : "JetBrainsMono Nerd Font"

    readonly property string srcDir: {
        var d = Quickshell.env("WALLPAPER_DIR")
        if (d && d !== "") return d
        return Quickshell.env("HOME") + "/Resimler/Wallpapers"
    }
    readonly property string secondSrcDir: "/usr/share/wallpapers/hyprland_wallpapers"
    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper_picker/thumbs"

    ListModel { id: wallpaperModel }
    property bool loading: true
    property string _errMsg: ""

    Process {
        id: listProc
        command: ["sh", "-c",
            "for d in \"" + root.srcDir + "\" \"" + root.secondSrcDir + "\"; do " +
                "[ -d \"$d\" ] || continue; " +
                "find \"$d\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\) 2>/dev/null; " +
            "done | sort -u"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var text = this.text.trim()
                var lines = text === "" ? [] : text.split('\n')
                wallpaperModel.clear()
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].trim()
                    if (p === "") continue
                    var name = p.split('/').pop()
                    var thumbPath = root.thumbDir + "/" + name
                    wallpaperModel.append({path: p, thumb: "file://" + thumbPath, name: name})
                }
                root.loading = false
                if (wallpaperModel.count === 0)
                    root._errMsg = "No wallpapers found in:\n" + root.srcDir
                generateThumbs()
            }
        }
    }

    function generateThumbs() {
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p \"" + root.thumbDir + "\"; " +
            "for d in \"" + root.srcDir + "\" \"" + root.secondSrcDir + "\"; do " +
                "[ -d \"$d\" ] || continue; " +
                "find \"$d\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\) 2>/dev/null; " +
            "done | sort -u | while IFS= read -r f; do " +
                "t=\"" + root.thumbDir + "/$(basename \"$f\")\"; " +
                "[ -f \"$t\" ] && continue; " +
                "magick \"$f\" -resize 300x300^ -quality 60 \"$t\" 2>/dev/null; " +
            "done"]);
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: bgColor
        border.color: border; border.width: 1
        clip: true

        Rectangle {
            id: headerBar
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: 48
            color: "transparent"

            Text {
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: loading ? "Loading..." : "Wallpapers (" + wallpaperModel.count + ")"
                color: root.textColor
                font.family: root.fontFamily
                font.pixelSize: 16
                font.bold: true
            }

            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 32; height: 32; radius: 8
                color: "transparent"
                border.color: root.border; border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: root.textColor
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppState.activePopup = ""
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: root._errMsg || "No wallpapers"
            color: root.textColor
            font.family: root.fontFamily
            font.pixelSize: 14
            visible: !loading && wallpaperModel.count === 0
        }

        GridView {
            id: grid
            anchors.left: parent.left; anchors.right: scrollbar.left
            anchors.top: headerBar.bottom; anchors.bottom: parent.bottom
            anchors.margins: 12
            anchors.topMargin: 4

            model: wallpaperModel
            currentIndex: -1
            focus: true
            keyNavigationWraps: true
            cellWidth: (grid.width - 12 * 4) / 5
            cellHeight: cellWidth * 0.7
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: !loading && wallpaperModel.count > 0

            delegate: Item {
                width: grid.cellWidth; height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent; anchors.margins: 6
                    radius: 8
                    color: root.bgColor
                    layer.enabled: true
                    layer.smooth: true

                    Image {
                        anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                        source: model.thumb
                        sourceSize.width: 200
                    }

                    // Seçili/hover göstergesi
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: "transparent"
                        border.color: root.textColor
                        border.width: 2
                        opacity: grid.currentIndex === index ? 1.0 : (ma.containsMouse ? 0.5 : 0.0)
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            grid.currentIndex = index;
                            applyWallpaper(model.path);
                        }
                    }
                }

                Keys.onReturnPressed: (event) => {
                    grid.currentIndex = index;
                    applyWallpaper(model.path);
                }
            }

            Keys.onReturnPressed: {
                var item = wallpaperModel.get(currentIndex)
                if (item) applyWallpaper(item.path)
            }
            Keys.onSpacePressed: {
                var item = wallpaperModel.get(currentIndex)
                if (item) applyWallpaper(item.path)
            }
            Keys.onEscapePressed: (event) => {
                AppState.activePopup = ""
                event.accepted = true
            }

            onActiveFocusChanged: {
                if (activeFocus && currentIndex < 0 && wallpaperModel.count > 0)
                    currentIndex = 0;
            }
        }

        // Scrollbar (draggable, track-clickable)
        Rectangle {
            id: scrollbar
            anchors.right: parent.right; anchors.rightMargin: 4
            anchors.top: headerBar.bottom; anchors.topMargin: 12
            anchors.bottom: parent.bottom; anchors.bottomMargin: 12
            width: 8; radius: 4
            color: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.15)
            visible: !loading && wallpaperModel.count > 0 && grid.visibleArea.heightRatio < 1.0

            // Track click — jump to position
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var r = mouseY / parent.height
                    grid.contentY = r * (grid.contentHeight - grid.height)
                }
            }

            Rectangle {
                id: scrollThumb
                width: parent.width; radius: 4
                height: Math.max(24, grid.visibleArea.heightRatio * parent.height)
                y: grid.visibleArea.yPosition * (parent.height - height)
                color: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.5)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    drag.target: scrollThumb; drag.axis: Drag.YAxis
                    drag.minimumY: 0
                    drag.maximumY: scrollbar.height - scrollThumb.height
                    onPositionChanged: {
                        if (drag.active) {
                            var r = scrollThumb.y / (scrollbar.height - scrollThumb.height)
                            grid.contentY = r * (grid.contentHeight - grid.height)
                        }
                    }
                }
            }
        }
    }

    function applyWallpaper(path) {
        if (!path) return;
        AppState.activePopup = "";
        var esc = function(s) { return String(s).replace(/(["\\$`])/g, '\\$1'); };
        var log = "/tmp/quickshell/logs/wallpaper.log";
        var script = `
            cp "${esc(path)}" /tmp/qs_current_wallpaper.png 2>/dev/null || true
            echo "[$(date +'%H:%M:%S.%3N')] APPLY: ${esc(path)}" >> ${log}
            for _out in $(hyprctl monitors -j 2>/dev/null | python3 -c "import json,sys; [print(m['name']) for m in json.load(sys.stdin)]" 2>/dev/null); do
                awww img -o "$_out" "${esc(path)}" >/dev/null 2>&1 &
            done; wait
            python3 "${Quickshell.shellDir}/scripts/generate_theme.py" --image "${esc(path)}" --auto --live >> ${log} 2>&1
        `;
        Quickshell.execDetached(["bash", "-c", script]);
    }

    onVisibleChanged: {
        if (visible) grid.forceActiveFocus();
    }
    Component.onCompleted: {
        if (visible) grid.forceActiveFocus();
    }
}
