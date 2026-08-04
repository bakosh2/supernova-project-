//
//  HelpMeStartComponents.swift
//  Supernova
//

import SwiftUI

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static let spaceGradientStops: [Gradient.Stop] = [
        .init(color: Color(hex: "#1E264F"), location: 0.00),
        .init(color: Color(hex: "#1E2651"), location: 0.36),
        .init(color: Color(hex: "#4454A9"), location: 0.61),
        .init(color: Color(hex: "#B39DDB"), location: 0.81),
        .init(color: Color(hex: "#B39DDB"), location: 1.00)
    ]
    
    static let rowBackgroundDark = Color(hex: "#26315F")
    static let tealPrimary = Color(hex: "#55BBB3")
    static let purpleCheckbox = Color(hex: "#9572D0")
    static let disabledButtonGray = Color(hex: "#D1D1D4")
}

// MARK: - Space Background View Alias
struct SpaceBackground: View {
    var body: some View {
        SpaceBackgroundView()
    }
}

// MARK: - Back Capsule Button
struct BackCapsuleButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.tealPrimary, Color(hex: "#43A8A0")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Capsule()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#1E264F"))
            }
            .frame(width: 110, height: 42)
            .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("رجوع")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Help Checklist Row Component
struct HelpChecklistRow: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    var customAccessibilityLabel: String? = nil
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                onTap()
            }
        }) {
            HStack(spacing: 16) {
                Spacer()
                
                // Arabic question title (right-aligned next to the checkbox)
                Text(title)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                
                // Right Checkbox Indicator
                ZStack {
                    if isSelected {
                        // Checked state: purple rounded square box with white checkmark
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.purpleCheckbox)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        // Unchecked state: empty circular outline
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .padding(.horizontal, 24)
            .frame(height: 88)
            .background(Color.rowBackgroundDark)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.tealPrimary : Color.clear, lineWidth: isSelected ? 2 : 0)
            )
            .shadow(
                color: isSelected ? Color.tealPrimary.opacity(0.4) : Color.black.opacity(0.1),
                radius: isSelected ? 8 : 2,
                x: 0,
                y: isSelected ? 0 : 2
            )
        }
        .buttonStyle(RowButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(customAccessibilityLabel ?? title)
        .accessibilityValue(isSelected ? "محدد" : "غير محدد")
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// Custom subtle button style for row press response
private struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Main Action Button ("يلا نبدأ!")
struct HelpMeStartButton: View {
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEnabled ? Color.tealPrimary : Color.disabledButtonGray)
                
                if isEnabled {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                }
                
                Text("يلا نبدأ!")
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .foregroundColor(isEnabled ? .white : Color.white.opacity(0.85))
            }
            .frame(maxWidth: 440)
            .frame(height: 80)
            .shadow(
                color: isEnabled ? Color.tealPrimary.opacity(0.45) : Color.clear,
                radius: isEnabled ? 10 : 0,
                x: 0,
                y: isEnabled ? 4 : 0
            )
        }
        .disabled(!isEnabled)
        .buttonStyle(ActionButtonStyle(isEnabled: isEnabled))
        .accessibilityLabel("يلا نبدأ!")
        .accessibilityHint(isEnabled ? "ابدأ الجلسة" : "أكمل عناصر الاستعداد أولًا")
        .accessibilityAddTraits(.isButton)
    }
}

private struct ActionButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isEnabled && configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
