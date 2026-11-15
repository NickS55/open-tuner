import AVFoundation
import SwiftUI

/// State shared with the audio render thread. Plain values behind a pointer so the
/// render callback never touches Swift objects or locks.
private struct ClickState {
    var bpm: Double = 100
    var beatsPerBar: Int = 4
    var sampleRate: Double = 48_000
    var playing = false
    var samplesToNextBeat: Double = 0
    var beat: Int = -1           // beat currently sounding, 0-based
    var clickSample: Int = .max  // position inside the current click
    var accented = false
}

final class Metronome: ObservableObject {
    @Published var bpm: Double = 100 { didSet { state.pointee.bpm = bpm } }
    @Published var beatsPerBar: Int = 4 { didSet { state.pointee.beatsPerBar = beatsPerBar } }
    @Published private(set) var isPlaying = false

    private let engine = AVAudioEngine()
    private let state: UnsafeMutablePointer<ClickState>
    private var tapTimes: [Date] = []

    /// Read by the UI on each frame; a torn read of an Int is harmless here.
    var currentBeat: Int { isPlaying ? state.pointee.beat : -1 }

    init() {
        state = .allocate(capacity: 1)
        state.initialize(to: ClickState())

        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        state.pointee.sampleRate = sampleRate > 0 ? sampleRate : 48_000
        let format = AVAudioFormat(standardFormatWithSampleRate: state.pointee.sampleRate, channels: 1)!

        let s = state
        let source = AVAudioSourceNode(format: format) { _, _, frameCount, bufferList in
            let out = UnsafeMutableAudioBufferListPointer(bufferList)[0].mData!
                .assumingMemoryBound(to: Float.self)
            let sr = s.pointee.sampleRate
            let clickLength = Int(sr * 0.035)
            for i in 0..<Int(frameCount) {
                guard s.pointee.playing else { out[i] = 0; continue }
                if s.pointee.samplesToNextBeat <= 0 {
                    s.pointee.beat = (s.pointee.beat + 1) % max(1, s.pointee.beatsPerBar)
                    s.pointee.accented = s.pointee.beat == 0
                    s.pointee.clickSample = 0
                    s.pointee.samplesToNextBeat += sr * 60 / s.pointee.bpm
                }
                s.pointee.samplesToNextBeat -= 1

                let n = s.pointee.clickSample
                if n < clickLength {
                    let t = Double(n) / sr
                    let freq = s.pointee.accented ? 1760.0 : 1100.0
                    let env = exp(-t * 120)
                    out[i] = Float(sin(2 * .pi * freq * t) * env * (s.pointee.accented ? 0.9 : 0.6))
                    s.pointee.clickSample = n + 1
                } else {
                    out[i] = 0
                }
            }
            return noErr
        }
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
    }

    deinit {
        engine.stop()
        state.deinitialize(count: 1)
        state.deallocate()
    }

    func toggle() { isPlaying ? stop() : start() }

    func start() {
        guard !isPlaying else { return }
        state.pointee.beat = -1
        state.pointee.samplesToNextBeat = 0
        state.pointee.clickSample = .max
        state.pointee.playing = true
        do {
            try engine.start()
            isPlaying = true
            UIApplication.shared.isIdleTimerDisabled = true
        } catch {
            state.pointee.playing = false
        }
    }

    func stop() {
        state.pointee.playing = false
        engine.pause()
        isPlaying = false
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func tap() {
        let now = Date()
        if let last = tapTimes.last, now.timeIntervalSince(last) > 2 { tapTimes.removeAll() }
        tapTimes.append(now)
        if tapTimes.count > 5 { tapTimes.removeFirst() }
        guard tapTimes.count >= 2 else { return }
        let interval = tapTimes.last!.timeIntervalSince(tapTimes.first!) / Double(tapTimes.count - 1)
        bpm = (60 / interval).rounded().clamped(to: 30...260)
    }
}
