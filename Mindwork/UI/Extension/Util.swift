//
//  Util.swift
//  Mindwork
//
//  Created by Yakup Kavak on 2.08.2025.
//

import Foundation
import SwiftUICore
import UIKit

func getLocalizedString(_ key: LocalizedStringKey) -> String {
    let mirror = Mirror(reflecting: key)
    if let value = mirror.children.first?.value as? String {
        return NSLocalizedString(value, comment: "")
    }
    return ""
}

enum AlertType {
    case success, error
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}
import SwiftUI

// MARK: - Kontrast hesaplama (WCAG luminance yaklaşımı)
extension Color {
    fileprivate var uiColor: UIColor {
        UIColor(self)
    }

    // 0 (siyah) - 1 (beyaz) algılanan parlaklık
    fileprivate var perceivedLuminance: CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        func toLinear(_ c: CGFloat) -> CGFloat {
            (c <= 0.03928) ? (c / 12.92) : pow((c + 0.055) / 1.055, 2.4)
        }
        let R = toLinear(r), G = toLinear(g), B = toLinear(b)
        return 0.2126 * R + 0.7152 * G + 0.0722 * B
    }

    var contrastTextColor: Color {
        perceivedLuminance > 0.6 ? .black : .white
    }

    // Rengi gerçek anlamda biraz koyulaştır (Color -> Color)
    func darkened(by amount: CGFloat = 0.15) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
        if uiColor.getHue(&h, saturation: &s, brightness: &v, alpha: &a) {
            return Color(hue: Double(h),
                         saturation: Double(s),
                         brightness: Double(max(v - amount, 0)),
                         opacity: Double(a))
        } else {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            return Color(red: Double(max(r - amount, 0)),
                         green: Double(max(g - amount, 0)),
                         blue: Double(max(b - amount, 0)),
                         opacity: Double(a))
        }
    }

    // Çok açık renkleri biraz koyulaştır (CAST YOK!)
    var adjustedForLightBackground: Color {
        perceivedLuminance > 0.9 ? self.darkened(by: 0.15) : self
    }

    var adaptiveBorder: Color {
        perceivedLuminance > 0.85 ? Color.gray.opacity(0.5) : Color.clear
    }
}


// MARK: - Renkli cevap butonu
struct ColorAnswerButton: View {
    let title: LocalizedStringKey
    let color: Color
    let action: () -> Void

    var body: some View {
        let displayColor = color.adjustedForLightBackground
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(minWidth: 120)
                .background(displayColor)
                .foregroundColor(displayColor.contrastTextColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(displayColor.adaptiveBorder, lineWidth: 1)
                )
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
    }
}
