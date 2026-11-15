import AVFoundation
import SwiftUI

@main
struct OpenTunerApp: App {
    init() {
        // One shared session for both tools: mic input for the tuner, speaker output for the metronome.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default,
                                 options: [.defaultToSpeaker, .allowBluetoothA2DP, .mixWithOthers])
        try? session.setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                TunerView()
                    .tabItem { Label("Tuner", systemImage: "tuningfork") }
                MetronomeView()
                    .tabItem { Label("Metronome", systemImage: "metronome") }
            }
            .preferredColorScheme(.dark)
        }
    }
}
