import SwiftUI

// MARK: - App Colors (use these in Assets.xcassets too)
extension Color {
    // Warm background palette matching EchoMemory design
    static let echoCream       = Color(hex: "#FDF6EC")
    static let echoSoftPeach   = Color(hex: "#FFF0E6")
    static let echoMint        = Color(hex: "#E8F8F0")
    static let echoLavender    = Color(hex: "#EEF0FB")
    static let echoSoftBlue    = Color(hex: "#E8F3FD")

    // Text
    static let echoTextPrimary   = Color(hex: "#3D2C1E")
    static let echoTextSecondary = Color(hex: "#7A6254")
    static let echoTextMuted     = Color(hex: "#B0A090")

    // Accents
    static let echoTeal    = Color(hex: "#5CBFA3")
    static let echoCoral   = Color(hex: "#F5896B")
    static let echoBlue    = Color(hex: "#6DA9E4")
    static let echoAmber   = Color(hex: "#F5C26B")
    static let echoPurple  = Color(hex: "#9B8FD9")

    // Mood
    static let moodGreen   = Color(hex: "#6DBF82")
    static let moodYellow  = Color(hex: "#F5C872")
    static let moodRed     = Color(hex: "#F28B82")

    // Card backgrounds
    static let cardWhite   = Color.white.opacity(0.92)
    static let cardSoft    = Color(hex: "#FFFAF5")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Font Extensions
extension Font {
    // Large, legible fonts for accessibility
    static let echoTitle       = Font.system(size: 34, weight: .bold, design: .rounded)
    static let echoHeadline    = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let echoSubheadline = Font.system(size: 18, weight: .medium, design: .rounded)
    static let echoBody        = Font.system(size: 17, weight: .regular, design: .rounded)
    static let echoCaption     = Font.system(size: 14, weight: .medium, design: .rounded)
    static let echoSmall       = Font.system(size: 12, weight: .regular, design: .rounded)
}

// MARK: - View Modifiers
struct EchoCardModifier: ViewModifier {
    var color: Color = .cardWhite
    var cornerRadius: CGFloat = 20
    var shadowRadius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .background(color)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.echoTextPrimary.opacity(0.07), radius: shadowRadius, x: 0, y: 4)
    }
}

extension View {
    func echoCard(color: Color = .cardWhite, cornerRadius: CGFloat = 20) -> some View {
        modifier(EchoCardModifier(color: color, cornerRadius: cornerRadius))
    }
}

// MARK: - Date Formatting
extension Date {
    var dayOfWeekSpanish: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self).capitalized
    }

    var dayMonth: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d 'de' MMMM"
        return formatter.string(from: self)
    }

    var shortDay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "EEE"
        return formatter.string(from: self).prefix(3).uppercased()
    }
}
