//
//  SpaceBackgroundView.swift
//  Supernova
//

import SwiftUI

/// Shared space background view used across Help Me Start, Focus Session, and Break Session.
struct SpaceBackgroundView: View {
    // Relative coordinates for background star elements (xRatio, yRatio, size, opacity, isSFStar)
    private let starPositions: [(CGFloat, CGFloat, CGFloat, Double, Bool)] = [
        (0.08, 0.12, 4, 0.7, false),
        (0.14, 0.22, 8, 0.6, true),
        (0.20, 0.45, 3, 0.5, false),
        (0.12, 0.68, 5, 0.6, false),
        (0.28, 0.82, 4, 0.5, false),
        (0.35, 0.15, 3, 0.4, false),
        (0.48, 0.08, 7, 0.6, true),
        (0.52, 0.25, 3, 0.4, false),
        (0.65, 0.12, 4, 0.6, false),
        (0.76, 0.10, 8, 0.7, true),
        (0.84, 0.22, 3, 0.4, false),
        (0.90, 0.14, 4, 0.5, false),
        (0.92, 0.40, 7, 0.6, true),
        (0.82, 0.55, 3, 0.4, false),
        (0.88, 0.75, 5, 0.6, false),
        (0.74, 0.85, 4, 0.5, false),
        (0.42, 0.90, 3, 0.4, false),
        (0.06, 0.90, 4, 0.5, false)
    ]
    
    private let gradientStops: [Gradient.Stop] = [
        .init(color: Color(hex: "#1E264F"), location: 0.00),
        .init(color: Color(hex: "#1E2651"), location: 0.36),
        .init(color: Color(hex: "#4454A9"), location: 0.61),
        .init(color: Color(hex: "#B39DDB"), location: 0.81),
        .init(color: Color(hex: "#B39DDB"), location: 1.00)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Smooth navy-to-lavender vertical linear gradient matching hex stops
                LinearGradient(
                    stops: gradientStops,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Static subtle decorative stars and dots
                ForEach(0..<starPositions.count, id: \.self) { index in
                    let item = starPositions[index]
                    let xPos = geometry.size.width * item.0
                    let yPos = geometry.size.height * item.1
                    
                    if item.4 {
                        Image(systemName: "star.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: item.2, height: item.2)
                            .foregroundColor(Color.white.opacity(item.3))
                            .position(x: xPos, y: yPos)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(item.3))
                            .frame(width: item.2, height: item.2)
                            .position(x: xPos, y: yPos)
                    }
                }
            }
        }
    }
}
