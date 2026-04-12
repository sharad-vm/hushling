import SwiftUI

// MARK: - Theme

enum Theme {
    // Night sky palette
    static let moonYellow     = Color(hex: "#FFD166")   // warm moon glow
    static let starWhite      = Color(hex: "#EEEAF8")   // slightly purple-tinted white
    static let lavender       = Color(hex: "#B8A9D9")   // muted secondary text
    static let accentPurple   = Color(hex: "#9B6DFF")   // focused input ring
    static let cardBackground = Color(hex: "#1C1645")   // glass card base (use .opacity)
    static let cardBorder     = Color(hex: "#2E2560")   // subtle card outline
    static let divider        = Color(hex: "#2A2358")   // section divider
    static let buttonText     = Color(hex: "#190A3F")   // text on yellow button
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }
}
