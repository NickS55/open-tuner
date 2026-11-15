import SwiftUI

struct MetronomeView: View {
    @StateObject private var metronome = Metronome()

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            TimelineView(.animation(paused: !metronome.isPlaying)) { _ in
                let beat = metronome.currentBeat
                HStack(spacing: 14) {
                    ForEach(0..<metronome.beatsPerBar, id: \.self) { i in
                        Circle()
                            .fill(i == beat ? (i == 0 ? Color.orange : Color.green) : Color.white.opacity(0.12))
                            .frame(width: i == 0 ? 30 : 24, height: i == 0 ? 30 : 24)
                    }
                }
                .frame(height: 40)
            }

            VStack(spacing: 0) {
                Text("\(Int(metronome.bpm))")
                    .font(.system(size: 110, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: Int(metronome.bpm))
                Text("BPM").font(.headline).foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                stepButton("minus") { metronome.bpm = max(30, metronome.bpm - 1) }
                Slider(value: $metronome.bpm, in: 30...260, step: 1)
                stepButton("plus") { metronome.bpm = min(260, metronome.bpm + 1) }
            }
            .padding(.horizontal, 24)

            Picker("Beats", selection: $metronome.beatsPerBar) {
                ForEach([1, 2, 3, 4, 5, 6, 7], id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)

            Spacer()

            HStack(spacing: 20) {
                Button("Tap") { metronome.tap() }
                    .font(.title3.bold())
                    .frame(width: 110, height: 64)
                    .background(Capsule().fill(Color.white.opacity(0.12)))

                Button { metronome.toggle() } label: {
                    Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                        .font(.title.bold())
                        .frame(width: 160, height: 64)
                        .background(Capsule().fill(metronome.isPlaying ? Color.red : Color.green))
                        .foregroundStyle(.black)
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 32)
        }
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.bold())
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }
}
