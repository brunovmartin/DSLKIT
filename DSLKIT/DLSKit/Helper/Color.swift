import SwiftUI

// Extensão para inicializar Color a partir de uma string Hex (necessária para o código)
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            // Formato inválido
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
    
}

public func castToCGFloat(_ value: Any?) -> CGFloat? {
    if let doubleValue = value as? Double {
        return CGFloat(doubleValue)
    } else if let intValue = value as? Int {
        return CGFloat(intValue)
    } else if let cgFloatValue = value as? CGFloat {
        return cgFloatValue
    }
    return nil
}

public func parseColor(_ value: Any?) -> Color? {
    guard let colorString = value as? String else { return nil }

    if let hexColor = Color(hex: colorString) {
        return hexColor
    }

    switch colorString.lowercased() {
        case "black": return .black
        case "blue": return .blue
        case "brown": return .brown
        case "clear": return .clear
        case "cyan": return .cyan
        case "gray": return .gray
        case "green": return .green
        case "indigo": return .indigo
        case "mint": return .mint
        case "orange": return .orange
        case "pink": return .pink
        case "purple": return .purple
        case "red": return .red
        case "teal": return .teal
        case "white": return .white
        case "yellow": return .yellow
        case "primary": return .primary
        case "secondary": return .secondary
        default: return nil
    }
}
