// ============================================================
// SES SEVİYE SERVİSİ (Singleton) — Pipewire tepe değerleri
// Görselleştirici için sol/sağ kanal peak değerlerini sağlar
// ============================================================
pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

Item {
    visible: false

    PwNodePeakMonitor {
        id: peakMonitor
        node: Pipewire.defaultAudioSink
        enabled: true
    }

    readonly property real peak: peakMonitor.peak
    readonly property var peaks: peakMonitor.peaks
    readonly property real peakLeft: peaks.length > 0 ? peaks[0] : 0
    readonly property real peakRight: peaks.length > 1 ? peaks[1] : 0
    readonly property int channelCount: peaks.length
}
