# CachyOS Control Center — Quickshell + QML

Dark, violet-accented system control panel for Wayland compositors.  
Matches the CachyOS aesthetic shown in the reference screenshot.

## Features

| Section | Details |
|---|---|
| **Header** | Month/year, settings & power buttons |
| **Quick Toggles** | Wi-Fi, Bluetooth, Airplane mode, DND |
| **Sliders** | Brightness (`brightnessctl`) · Volume (Pipewire) |
| **Media Player** | MPRIS2 — any player (Spotify, MPD, VLC…) |
| **System Stats** | CPU load · RAM usage (live from `/proc`) |
| **Power Card** | Battery % (UPower) · Power mode (`powerprofilesctl`) |
| **Footer** | Uptime · Edit config · Logout |

## Dependencies

```
quickshell          # https://quickshell.outfoxxed.me
qt6-declarative
qt6-wayland
brightnessctl
networkmanager      # nmcli
bluez-utils         # bluetoothctl
pipewire
mako  OR  dunst     # for DND toggle
power-profiles-daemon
```

Install on CachyOS / Arch:
```bash
yay -S quickshell-git brightnessctl networkmanager bluez-utils \
       pipewire mako power-profiles-daemon
```

## Running

```bash
quickshell -p /path/to/control-center
```

Or add to your Hyprland / Sway startup:
```
# hyprland.conf
exec-once = quickshell -p ~/.config/quickshell/control-center
```

## File Structure

```
control-center/
├── shell.qml           # Quickshell entry point (ShellRoot)
├── qmldir              # QML module manifest
├── ControlCenter.qml   # Root panel widget
├── HeaderBar.qml       # Date + icon buttons
├── ToggleTile.qml      # Reusable toggle card
├── SliderRow.qml       # Brightness / volume slider
├── MediaPlayer.qml     # MPRIS now-playing card
├── MediaButton.qml     # Prev / play / next buttons
├── SystemStatCard.qml  # CPU + RAM bars
├── PowerCard.qml       # Battery + power mode
├── FooterBar.qml       # Uptime + session buttons
├── IconButton.qml      # Generic circular icon button
├── NetworkInfo.qml     # Wi-Fi singleton (nmcli)
├── BluetoothInfo.qml   # Bluetooth singleton
├── BrightnessInfo.qml  # Brightness singleton
├── NotifInfo.qml       # DND singleton (mako)
└── SystemInfo.qml      # CPU / RAM / uptime / power mode
```

## Customisation

All colours are defined as `readonly property color` aliases at the top of  
`ControlCenter.qml` — change them there and every child component picks them up.

```qml
readonly property color accentViolet: "#7c6af7"   // violet highlight
readonly property color accentGreen:  "#4ade80"   // RAM / battery green
readonly property color bg:           "#14151e"   // panel background
```

Panel position is controlled in `shell.qml`:
```qml
anchors { top: true; right: true }   // top-right (default)
// anchors { top: true; left: true } // top-left
```
