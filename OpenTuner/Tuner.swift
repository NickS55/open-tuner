import Accelerate
import AVFoundation
import SwiftUI

final class Tuner: ObservableObject {
    static let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]

    @Published private(set) var frequency: Double?
    @Published private(set) var isRunning = false
    @Published private(set) var permissionDenied = false
    @Published var referenceA: Double = 440

    private let engine = AVAudioEngine()
    private let analyzer = Analyzer()

    /// Fractional MIDI note number of the current pitch.
    var midi: Double? {
        frequency.map { 69 + 12 * log2($0 / referenceA) }
    }
    var nearestMidi: Int? { midi.map { Int($0.rounded()) } }
    var cents: Double? {
        guard let midi, let nearestMidi else { return nil }
        return (midi - Double(nearestMidi)) * 100
    }
    var noteName: String? { nearestMidi.map { Self.noteNames[(($0 % 12) + 12) % 12] } }
    var octave: Int? { nearestMidi.map { $0 / 12 - 1 } }

    @MainActor
    func start() async {
        guard !isRunning else { return }
        // App Store screenshots: the simulator has no microphone, so fake a reading.
        let demo = UserDefaults.standard.double(forKey: "demoFrequency")
        if demo > 0 { frequency = demo; return }
        guard await AVAudioApplication.requestRecordPermission() else {
            permissionDenied = true
            return
        }
        permissionDenied = false

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else { return }
        analyzer.reset(sampleRate: format.sampleRate)

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self, analyzer] buffer, _ in
            guard let result = analyzer.process(buffer) else { return }
            DispatchQueue.main.async { self?.frequency = result.frequency }
        }
        do {
            try engine.start()
            isRunning = true
            UIApplication.shared.isIdleTimerDisabled = true
        } catch {
            input.removeTap(onBus: 0)
        }
    }

    @MainActor
    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        frequency = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

/// Runs on the audio tap thread: keeps a sliding window and smooths the detected pitch.
private final class Analyzer {
    struct Result { let frequency: Double? }

    private let windowSize = 4096
    private var window: [Float] = []
    private var sampleRate: Double = 48_000
    private var recent: [Double] = []
    private var silentSince: Date?

    func reset(sampleRate: Double) {
        self.sampleRate = sampleRate
        window = [Float](repeating: 0, count: windowSize)
        recent = []
        silentSince = nil
    }

    /// Returns nil when there's nothing new to report.
    func process(_ buffer: AVAudioPCMBuffer) -> Result? {
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)
        let incoming = Array(UnsafeBufferPointer(start: channel, count: min(count, windowSize)))
        window.removeFirst(incoming.count)
        window.append(contentsOf: incoming)

        var rms: Float = 0
        vDSP_rmsqv(incoming, 1, &rms, vDSP_Length(incoming.count))

        if rms > 0.004, let f = PitchDetector.detect(window, sampleRate: sampleRate) {
            silentSince = nil
            // Drop the history on a jump of more than ~a semitone so new notes register instantly.
            if let last = recent.last, abs(12 * log2(f / last)) > 1.0 { recent.removeAll() }
            recent.append(f)
            if recent.count > 5 { recent.removeFirst() }
            let median = recent.sorted()[recent.count / 2]
            return Result(frequency: median)
        }

        // Hold the last reading briefly after the note fades.
        let now = Date()
        if silentSince == nil { silentSince = now }
        if let since = silentSince, now.timeIntervalSince(since) > 1.2, !recent.isEmpty {
            recent.removeAll()
            return Result(frequency: nil)
        }
        return nil
    }
}
