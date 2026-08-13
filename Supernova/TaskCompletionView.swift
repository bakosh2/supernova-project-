//
//  TaskCompletionView.swift
//  Supernova
//

import SwiftUI
import AVFoundation

/// شاشة الاحتفال عند إتمام المهمة: نجمة متحركة وصوت احتفال من مشروع gettingstar.
struct TaskCompletionView: View {
    var task: HomeworkTask? = nil
    let onClose: () -> Void

    @State private var starScale: CGFloat = 0.05
    @State private var starRotation: Double = -8
    @State private var burstScale: CGFloat = 0.4
    @State private var burstOpacity: Double = 0
    @State private var messageOpacity: Double = 0
    @State private var messageOffset: CGFloat = 18
    @State private var sparklesVisible = false
    @State private var sparklePlayer: AVAudioPlayer?

    private let deepBlue = Color(red: 0.05, green: 0.07, blue: 0.28)
    private let midBlue = Color(red: 0.14, green: 0.18, blue: 0.48)
    private let purple = Color(red: 0.32, green: 0.16, blue: 0.50)
    private let gold = Color(red: 1.00, green: 0.82, blue: 0.30)

    private let sparkles: [(CGFloat, CGFloat, CGFloat, Double)] = [
        (-170, -105, 17, 0.0), (155, -85, 10, 0.15),
        (-190, 35, 8, 0.3), (175, 70, 18, 0.08),
        (-100, 135, 9, 0.38), (60, 145, 12, 0.45),
        (-45, -145, 7, 0.2), (125, -150, 10, 0.5)
    ]

    var body: some View {
        GeometryReader { geo in
            let starSize = min(geo.size.width, geo.size.height) * 0.34

            ZStack(alignment: .topLeading) {
                celebrationBackground(in: geo.size)

                Circle()
                    .fill(RadialGradient(
                        colors: [.white, gold.opacity(0.7), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: starSize * 0.85
                    ))
                    .frame(width: starSize * 1.55, height: starSize * 1.55)
                    .scaleEffect(burstScale)
                    .opacity(burstOpacity)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                sparkleParticles
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                Image("star_character")
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
                    .scaleEffect(starScale)
                    .rotationEffect(.degrees(starRotation))
                    .shadow(color: gold.opacity(0.9), radius: 42)
                    .shadow(color: gold.opacity(0.45), radius: 78)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                VStack {
                    Spacer()
                    Text("تهانينا لقد فزت بنجمة!")
                        .font(.system(size: min(geo.size.width * 0.042, 46), weight: .heavy, design: .rounded))
                        .foregroundColor(gold)
                        .shadow(color: gold.opacity(0.6), radius: 10)
                        .opacity(messageOpacity)
                        .offset(y: messageOffset)
                        .padding(.bottom, max(geo.size.height * 0.12, 60))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                BackCapsuleButton(action: onClose)
                    .padding(.top, AppHeaderLayout.top)
                    .padding(.leading, AppHeaderLayout.horizontal)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: animateIn)
    }

    private func celebrationBackground(in size: CGSize) -> some View {
        RadialGradient(
            gradient: Gradient(stops: [
                .init(color: gold.opacity(0.92), location: 0),
                .init(color: gold.opacity(0.52), location: 0.06),
                .init(color: gold.opacity(0.13), location: 0.13),
                .init(color: Color(red: 0.55, green: 0.42, blue: 0.78).opacity(0.58), location: 0.22),
                .init(color: purple.opacity(0.57), location: 0.46),
                .init(color: midBlue.opacity(0.55), location: 0.72),
                .init(color: deepBlue, location: 1)
            ]),
            center: .center,
            startRadius: 4,
            endRadius: max(size.width, size.height) * 0.86
        )
        .frame(width: size.width, height: size.height)
    }

    private var sparkleParticles: some View {
        ZStack {
            ForEach(Array(sparkles.enumerated()), id: \.offset) { _, item in
                Image(systemName: "sparkle")
                    .font(.system(size: item.2, weight: .bold))
                    .foregroundColor(gold)
                    .shadow(color: gold.opacity(0.7), radius: 4)
                    .opacity(sparklesVisible ? 1 : 0)
                    .scaleEffect(sparklesVisible ? 1 : 0.15)
                    .offset(x: sparklesVisible ? item.0 : 0, y: sparklesVisible ? item.1 : 0)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true).delay(item.3), value: sparklesVisible)
            }
        }
    }

    private func animateIn() {
        withAnimation(.easeOut(duration: 0.25)) {
            burstOpacity = 1
            burstScale = 1.5
        }
        withAnimation(.easeIn(duration: 0.45).delay(0.3)) { burstOpacity = 0 }
        withAnimation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.22)) { starScale = 1 }
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(0.75)) { starRotation = 6 }
        withAnimation(.easeOut(duration: 0.6).delay(1.0)) {
            messageOpacity = 1
            messageOffset = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { playSparkleSound() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { sparklesVisible = true }
    }

    private func playSparkleSound() {
        guard let url = Bundle.main.url(forResource: "SparkleSound", withExtension: "mp3") else { return }
        sparklePlayer = try? AVAudioPlayer(contentsOf: url)
        sparklePlayer?.volume = 0.8
        sparklePlayer?.play()
    }
}

#Preview("Task Completion Screen") {
    TaskCompletionView(onClose: {})
        .previewInterfaceOrientation(.landscapeLeft)
}
