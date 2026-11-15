import SwiftUI

/// Bluebird palette, shared with the app icon.
extension Color {
    /// Cream background.
    static let ground = Color(red: 0xF4 / 255, green: 0xEC / 255, blue: 0xDF / 255)
    /// Bluebird blue: in tune, primary actions.
    static let bird = Color(red: 0x24 / 255, green: 0x56 / 255, blue: 0xA4 / 255)
    /// Rust breast: the target mark, the downbeat, out of tune.
    static let rust = Color(red: 0xD2 / 255, green: 0x64 / 255, blue: 0x2A / 255)
    /// Pale sky blue: ticks, idle dots, button fills.
    static let sky = Color(red: 0x9F / 255, green: 0xB8 / 255, blue: 0xDE / 255)
    /// Deep navy for body text.
    static let ink = Color(red: 0x1B / 255, green: 0x2B / 255, blue: 0x4A / 255)
}
