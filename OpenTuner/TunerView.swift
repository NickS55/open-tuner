import SwiftUI

struct TunerView: View {
    @StateObject private var tuner = Tuner()
    @Environment(\.scenePhase) private var scenePhase

    private var inTune: Bool { abs(tuner.cents ?? 99) <= 5 }
    private var accent: Color {
        guard let cents = tuner.cents else { return .secondary }
        switch abs(cents) {
        case ...5: return .green
        case ...15: return .yellow
        default: return .orange
        }
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(tuner.noteName ?? "–")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                if let octave = tuner.octave {
                    Text("\(octave)")
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 140)
            .contentTransition(.numericText())
            .animation(.snappy, value: tuner.nearestMidi)

            CentsGauge(cents: tuner.cents, color: accent)
                .frame(height: 70)
                .padding(.horizontal)

            VStack(spacing: 4) {
                Text(tuner.cents.map { String(format: "%+.0f cents", $0) } ?? "Play a string")
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(inTune ? .green : .primary)
                Text(tuner.frequency.map { String(format: "%.1f Hz", $0) } ?? " ")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if tuner.permissionDenied {
                Text("Microphone access is off. Enable it in Settings › Open Tuner.")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Stepper(value: $tuner.referenceA, in: 430...450, step: 1) {
                Text("A4 = \(Int(tuner.referenceA)) Hz").monospacedDigit()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .task { await tuner.start() }
        .onDisappear { tuner.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await tuner.start() } } else { tuner.stop() }
        }
    }
}

private struct CentsGauge: View {
    let cents: Double?
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let x = w / 2 + CGFloat((cents ?? 0).clamped(to: -50...50) / 50) * (w / 2 - 6)
            ZStack {
                ForEach(-10...10, id: \.self) { i in
                    let major = i % 5 == 0
                    Rectangle()
                        .fill(i == 0 ? Color.green : Color.white.opacity(major ? 0.5 : 0.2))
                        .frame(width: i == 0 ? 3 : 2, height: major ? h * 0.6 : h * 0.35)
                        .position(x: w / 2 + CGFloat(i) / 10 * (w / 2 - 6), y: h / 2)
                }
                Capsule()
                    .fill(cents == nil ? Color.clear : color)
                    .frame(width: 6, height: h)
                    .position(x: x, y: h / 2)
                    .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.8), value: cents)
            }
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self { min(max(self, range.lowerBound), range.upperBound) }
}
