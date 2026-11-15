import AVFoundation
import SwiftUI

@main
struct OpenTunerApp: App {
    @State private var tab = UserDefaults.standard.integer(forKey: "startTab")

    init() {
        // One shared session for both tools: mic input for the tuner, speaker output for the metronome.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default,
                                 options: [.defaultToSpeaker, .allowBluetoothA2DP, .mixWithOthers])
        try? session.setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $tab) {
                TunerView()
                    .tabItem { Label("Tuner", systemImage: "tuningfork") }
                    .tag(0)
                MetronomeView()
                    .tabItem { Label("Metronome", systemImage: "metronome") }
                    .tag(1)
            }
            .preferredColorScheme(.dark)
        }
    }
}
