import AppKit
import SwiftUI

// MARK: - NSColor Hex Support

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }

    var hexString: String {
        guard let c = usingColorSpace(.sRGB) else { return "#000000" }
        return String(format: "#%02X%02X%02X",
                      Int(c.redComponent * 255),
                      Int(c.greenComponent * 255),
                      Int(c.blueComponent * 255))
    }

    func lightened(by amount: CGFloat) -> NSColor {
        guard let c = usingColorSpace(.sRGB) else { return self }
        let r: CGFloat = c.redComponent + (1 - c.redComponent) * amount
        let g: CGFloat = c.greenComponent + (1 - c.greenComponent) * amount
        let b: CGFloat = c.blueComponent + (1 - c.blueComponent) * amount
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - SwiftUI Color Hex Support

extension Color {
    init(hex: String) {
        self.init(nsColor: NSColor(hex: hex))
    }

    var hexString: String {
        NSColor(self).hexString
    }
}
