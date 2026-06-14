import Quickshell
import Quickshell.Wayland

ShellRoot {
	LockContext {
		id: lockContext

		onUnlocked: {
			lock.locked = false
			Qt.callLater(() => Qt.quit())
		}
	}

	WlSessionLock {
		id: lock
		locked: true

		WlSessionLockSurface {
			LockSurface {
				anchors.fill: parent
				context: lockContext
			}
		}
	}
}
