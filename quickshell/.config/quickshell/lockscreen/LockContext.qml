import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
	id: root
	signal unlocked()
	signal failed()

	property string currentText: ""
	property bool unlockInProgress: false
	property bool showFailure: false
	property string failMessage: ""

	onCurrentTextChanged: showFailure = false

	function tryUnlock() {
		if (currentText === "") return

		root.unlockInProgress = true
		pam.start()
	}

	PamContext {
		id: pam
		configDirectory: "pam"
		config: "password.conf"

		onPamMessage: {
			if (this.responseRequired) {
				this.respond(root.currentText)
			}
		}

		onCompleted: result => {
			if (result == PamResult.Success) {
				root.unlocked()
			} else {
				root.currentText = ""
				root.failMessage = result == PamResult.MaxTries
					? "Maksimum deneme sayısına ulaşıldı"
					: "Yanlış şifre"
				root.showFailure = true
				root.failed()
			}
			root.unlockInProgress = false
		}

		onError: (error, message) => {
			root.currentText = ""
			root.failMessage = message || "PAM hatası: " + error
			root.showFailure = true
			root.unlockInProgress = false
			root.failed()
		}
	}
}
