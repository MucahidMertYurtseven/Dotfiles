import QtQuick
import QtQuick.Controls
import Quickshell.Wayland
import Quickshell.Io

Rectangle {
	id: root
	required property LockContext context

	readonly property color brightColor:  "#ffffff"
	readonly property color mutedColor:   "#7e8099"
	readonly property color accentColor:  "#b0b0b0"
	readonly property color warnColor:    "#f38ba8"
	readonly property color borderColor:  "#323232"
	readonly property color checkColor:   "#f0c040"
	readonly property string fontFamily:  "MesloLGS Nerd Font"
	readonly property string clockFont:   "Fira Sans"

	color: "#101010"

	Image {
		id: bgImage
		anchors.fill: parent
		source: "file:///tmp/lock_blur.png"
		fillMode: Image.PreserveAspectCrop
		opacity: 0
		Behavior on opacity {
			NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
		}
		onStatusChanged: {
			if (status === Image.Ready) opacity = 1
		}
		Timer {
			interval: 300
			running: true
			repeat: true
			onTriggered: {
				if (bgImage.status === Image.Error) {
					bgImage.source = ""
					bgImage.source = "file:///tmp/lock_blur.png"
				} else if (bgImage.status === Image.Ready) {
					running = false
				}
			}
		}
	}

	Rectangle {
		anchors.fill: parent
		color: "#a0101010"
		opacity: 0
		Behavior on opacity {
			NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
		}
		Component.onCompleted: opacity = 1
	}

	Item {
		anchors.fill: parent
		focus: true
		Keys.onPressed: (event) => {
			if (event.key === Qt.Key_Escape) {
				_sleepProc.running = true
				event.accepted = true
			}
		}
		Process { id: _sleepProc; command: ["systemctl", "suspend"] }
	}

	Item {
		id: content
		anchors.fill: parent
		opacity: 0
		Behavior on opacity {
			NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
		}
		Component.onCompleted: opacity = 1

		Text {
			id: clock
			property var date: new Date()
			anchors {
				horizontalCenter: parent.horizontalCenter
				top: parent.top; topMargin: 120
			}
			renderType: Text.NativeRendering
			font.pointSize: 72; font.family: fontFamily
			font.bold: true; color: brightColor
			Timer {
				running: true; repeat: true; interval: 1000
				onTriggered: clock.date = new Date()
			}
			text: {
				var h = clock.date.getHours().toString().padStart(2, "0")
				var m = clock.date.getMinutes().toString().padStart(2, "0")
				return h + ":" + m
			}
		}

		Text {
			anchors {
				horizontalCenter: parent.horizontalCenter
				top: clock.bottom; topMargin: 6
			}
			text: {
				var d = new Date()
				var months = ["Ocak","Şubat","Mart","Nisan","Mayıs","Haziran","Temmuz","Ağustos","Eylül","Ekim","Kasım","Aralık"]
				var days = ["Pazar","Pazartesi","Salı","Çarşamba","Perşembe","Cuma","Cumartesi"]
				return days[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()] + " " + d.getFullYear()
			}
			color: mutedColor; font.pixelSize: 13; font.family: fontFamily
		}

		Item {
			id: pwContainer
			anchors {
				horizontalCenter: parent.horizontalCenter
				top: parent.verticalCenter; topMargin: -10
			}
			width: 320; height: 52

			// fade_on_empty: empty → 0.35, focus → 0.7, typing → 1.0
			readonly property real emptyAlpha: 0.35
			opacity: {
				if (root.context.unlockInProgress) return 1
				if (passwordBox.text.length > 0) return 1
				if (passwordBox.activeFocus) return 0.7
				return emptyAlpha
			}
			Behavior on opacity {
				NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
			}

			transform: Translate { x: pwContainer.shakeX }

			// Shake on failure
			property real shakeX: 0
			SequentialAnimation {
				id: shakeAnim
				loops: 1
				PropertyAction { target: pwContainer; property: "shakeX"; value: 0 }
				NumberAnimation { target: pwContainer; property: "shakeX"; to: -10; duration: 50 }
				NumberAnimation { target: pwContainer; property: "shakeX"; to: 10;  duration: 50 }
				NumberAnimation { target: pwContainer; property: "shakeX"; to: -8;  duration: 45 }
				NumberAnimation { target: pwContainer; property: "shakeX"; to: 8;   duration: 45 }
				NumberAnimation { target: pwContainer; property: "shakeX"; to: -5;  duration: 40 }
				NumberAnimation { target: pwContainer; property: "shakeX"; to: 5;   duration: 40 }
				NumberAnimation { target: pwContainer; property: "shakeX"; to: -3;  duration: 35 }
				NumberAnimation { target: pwContainer; property: "shakeX"; to: 3;   duration: 35 }
				NumberAnimation { target: pwContainer; property: "shakeX"; to: 0;   duration: 30 }
			}

			TextField {
				id: passwordBox
				width: parent.width; height: 52; padding: 0
				focus: true
				enabled: !root.context.unlockInProgress
				echoMode: TextInput.Password
				passwordCharacter: " "
				inputMethodHints: Qt.ImhSensitiveData
				color: "transparent"
				placeholderText: ""
				font.pixelSize: 1

				readonly property color stateColor: {
					if (root.context.showFailure) return warnColor
					if (root.context.unlockInProgress) return checkColor
					if (passwordBox.activeFocus) return accentColor
					return borderColor
				}

				background: Rectangle {
					radius: 26
					color: "#222222"
					border.color: passwordBox.stateColor
					border.width: passwordBox.activeFocus ? 2 : 1
					Behavior on border.color {
						ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
					}

					// Pulse glow while checking
					Rectangle {
						anchors.fill: parent; radius: 26
						color: "transparent"
						border.color: checkColor; border.width: 2
						opacity: root.context.unlockInProgress ? 0.4 : 0
						Behavior on opacity { NumberAnimation { duration: 200 } }

						SequentialAnimation on opacity {
							running: root.context.unlockInProgress
							loops: Animation.Infinite
							NumberAnimation { from: 0.25; to: 0.6; duration: 600; easing.type: Easing.InOutCubic }
							NumberAnimation { from: 0.6; to: 0.25; duration: 600; easing.type: Easing.InOutCubic }
						}
					}
				}

				onTextChanged: root.context.currentText = this.text
				onAccepted: root.context.tryUnlock()

				Connections {
					target: root.context
					function onShowFailureChanged() {
						if (root.context.showFailure) shakeAnim.start()
					}
				}

				// Bullets — fixed model, only newest fades in
				Item {
					anchors.fill: parent
					clip: true

					Row {
						id: bulletRow
						anchors.verticalCenter: parent.verticalCenter
						x: (parent.width - width) / 2
						layoutDirection: Qt.LeftToRight; spacing: 12

						Behavior on x {
							NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
						}

						Repeater {
							model: 32

							Text {
								width: implicitWidth
								text: "●"
								font.pixelSize: 26
								font.family: fontFamily
								color: brightColor
								horizontalAlignment: Text.AlignHCenter

								readonly property bool active: index < passwordBox.text.length
								opacity: active ? 1 : 0
								visible: active || opacity > 0

								Behavior on opacity {
									NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
								}
							}
						}
					}
				}

				Text {
					anchors { top: parent.bottom; topMargin: 10; horizontalCenter: parent.horizontalCenter }
					visible: root.context.showFailure
					text: root.context.failMessage || "Yanlış şifre"
					color: warnColor; font.pixelSize: 11; font.family: fontFamily
					opacity: root.context.showFailure ? 1 : 0
					Behavior on opacity { NumberAnimation { duration: 200 } }
				}

				Text {
					anchors { top: parent.bottom; topMargin: root.context.showFailure ? 26 : 10; horizontalCenter: parent.horizontalCenter }
					visible: root.context.unlockInProgress
					text: "Doğrulanıyor..."
					color: mutedColor; font.pixelSize: 10; font.family: fontFamily
					opacity: root.context.unlockInProgress ? 1 : 0
					Behavior on opacity { NumberAnimation { duration: 200 } }
				}

				Connections {
					target: root.context
					function onCurrentTextChanged() {
						passwordBox.text = root.context.currentText
					}
				}
			}
		}
	}
}
