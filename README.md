<img src="OpenTuner/Assets.xcassets/AppIcon.appiconset/icon.png" width="96" alt="Open Tuner icon: a hummingbird whose beak points at the in-tune mark">

# Open Tuner

A simple, free iPhone tuner and metronome. No ads, no accounts, no tracking.

<p>
  <img src="appstore/screenshots-6.3/1-tuner.png" width="240" alt="Tuner showing A4, in tune">
  <img src="appstore/screenshots-6.3/2-tuner-flat.png" width="240" alt="Tuner showing A2, 40 cents flat">
  <img src="appstore/screenshots-6.3/3-metronome.png" width="240" alt="Metronome at 100 BPM">
</p>

- **Tuner** — chromatic, works for any instrument or voice (~38 Hz to 2 kHz). Shows note, octave, frequency and a cents needle; adjustable reference pitch (A4 = 430–450 Hz). Pitch detection uses the YIN algorithm.
- **Metronome** — 30–260 BPM, 1–7 beats per bar with an accented downbeat, tap tempo, keeps playing with the screen locked.

Built with SwiftUI and AVAudioEngine. Requires iOS 17+.

## Install on your iPhone

1. Open `OpenTuner.xcodeproj` in Xcode.
2. Select the **OpenTuner** target → *Signing & Capabilities* → choose your team and change the bundle identifier to something unique.
3. Plug in your iPhone, pick it as the run destination, and press ⌘R.

## License

MIT
