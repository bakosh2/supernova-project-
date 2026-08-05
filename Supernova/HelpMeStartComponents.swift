//
//  HelpMeStartComponents.swift
//  Supernova
//

import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        if hex.count == 6 {
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        } else {
            (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
    
    static let rowBackgroundDark = Color(hex: "#26315F")
    static let tealPrimary = Color(hex: "#55BBB3")
    static let purpleCheckbox = Color(hex: "#9572D0")
    static let disabledButtonGray = Color(hex: "#D1D1D4")
}

// Back Button
struct BackCapsuleButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#1E264F"))
                .frame(width: 110, height: 42)
                .background(Color.tealPrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
        }
    }
}

// Checklist Row
struct HelpChecklistRow: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                onTap()
            }
        }) {
            HStack(spacing: 16) {
                Spacer()
                
                Text(title)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
                    .environment(\.layoutDirection, .rightToLeft)
                
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
    }
}

// Start Button
struct HelpMeStartButton: View {
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("يلا نبدأ!")
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(isEnabled ? .white : Color.white.opacity(0.85))
                .frame(maxWidth: 440)
                .frame(height: 80)
                .background(isEnabled ? Color.tealPrimary : Color.disabledButtonGray)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isEnabled ? Color.white.opacity(0.4) : Color.clear, lineWidth: 1)
                )
                .shadow(
                    color: isEnabled ? Color.tealPrimary.opacity(0.45) : Color.clear,
                    radius: isEnabled ? 10 : 0,
                    x: 0,
                    y: isEnabled ? 4 : 0
                )
        }
        .disabled(!isEnabled)
    }
}
