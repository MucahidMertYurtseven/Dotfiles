// ============================================================
// SES SERVİSİ (Singleton) — Pipewire ses kontrolü
// Varsayılan hoparlör ve mikrofon için ses/mute yönetimi
// ============================================================
pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

Item {
    visible: false

    property bool ready: Pipewire.ready ?? false

    // Hoparlör
    property real volume: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false
    property string deviceName: Pipewire.defaultAudioSink?.description
        ?? Pipewire.defaultAudioSink?.name ?? "Ses"

    // Mikrofon
    property real micVolume: Pipewire.defaultAudioSource?.audio?.volume ?? 0
    property bool micMuted: Pipewire.defaultAudioSource?.audio?.muted ?? false
    property string micName: Pipewire.defaultAudioSource?.description
        ?? Pipewire.defaultAudioSource?.name ?? "Mikrofon"

    function setVolume(v) {
        var a = Pipewire.defaultAudioSink?.audio
        if (a) a.volume = v
    }

    function toggleMute() {
        var a = Pipewire.defaultAudioSink?.audio
        if (a) a.muted = !a.muted
    }

    function toggleMicMute() {
        var a = Pipewire.defaultAudioSource?.audio
        if (a) a.muted = !a.muted
    }

    // Varsayılan cihazları otomatik takip et
    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink, Pipewire.defaultAudioSource ]
    }
}
