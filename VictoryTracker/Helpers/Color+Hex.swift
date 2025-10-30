import SwiftUI

extension Color {
    init(hex: String, default defaultColor: Color = .gray) {
        let r, g, b, a: Double
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }

        var value: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&value) else {
            self = defaultColor
            return
        }

        switch hexSanitized.count {
        case 6:
            r = Double((value & 0xFF0000) >> 16) / 255.0
            g = Double((value & 0x00FF00) >> 8) / 255.0
            b = Double(value & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = Double((value & 0xFF000000) >> 24) / 255.0
            g = Double((value & 0x00FF0000) >> 16) / 255.0
            b = Double((value & 0x0000FF00) >> 8) / 255.0
            a = Double(value & 0x000000FF) / 255.0
        default:
            self = defaultColor
            return
        }

        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}


