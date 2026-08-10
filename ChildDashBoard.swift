//
//  TodaysMissionsView.swift
//  Today's Missions – ADHD-friendly kids learning screen (iPad)
//
//  ملف واحد، هيكل (struct) واحد فقط: TodaysMissionsView.
//  كل البيانات والمكونات الفرعية مبنية كـ @State + دوال/متغيرات خاصة (private)
//  جوه نفس الـ struct بدل ما تكون أنواع منفصلة.
//
//  الخلفية والكوكب ورائد الفضاء أشكال بديلة placeholders فقط —
//  دورّ على تعليق "// TODO: Asset" واستبدلها بالصور تبعك.
//

import SwiftUI

struct TodaysMissionsView: View {
    
    // MARK: - Mission data (struct-of-arrays بدل ما نسوي نوع Mission منفصل)
    @State private var astronautFloat = false
    @State private var isAnimating = false
    @State private var floating = false
    @State private var missionTitles: [String] = ["قراءة قصة", "حل واجب الرياضيات", "حل واجب العلوم"]
    @State private var missionProgress: [Double] = [1.0, 0.35, 0.0]
    @State private var missionRewardClaimed: [Bool] = [false, false, false]
    private let missionSubtitle = "ينتهي خلال يوم"
    
    // MARK: - Constellation data
    
    @State private var nodeX: [CGFloat] = [0.62, 0.18, 0.75]   // نسبة أفقية 0...1
    @State private var nodeY: [CGFloat] = [0.15, 0.60, 0.70]   // نسبة رأسية 0...1
    @State private var nodeFilled: [Bool] = [false, false, false]
    @State private var nodePulse: [CGFloat] = [1, 1, 1]
    @State private var nodeSparkleOpacity: [Double] = [0, 0, 0]
    
    @State private var constellationCenter: CGPoint = .zero
    @State private var constellationSize: CGSize = CGSize(width: 1, height: 1)
    
    // MARK: - UI state
    
    @State private var starBalance: Int = 1
    @State private var draggingMissionIndex: Int?
    @State private var dragPoint: CGPoint = .zero
    @State private var starWiggle = false
    @State private var showCelebration = false
    
    // MARK: - Theme constants (ثوابت فقط، مو نوع جديد)
    
    private let navyTop     = Color(red: 0.05, green: 0.07, blue: 0.20)
    private let navyMid     = Color(red: 0.15, green: 0.13, blue: 0.4)
    private let purple      = Color(red: 0.7, green: 0.30, blue: 0.9)
    private let turquoise   = Color(red: 0.20, green: 0.70, blue: 0.8)
    private let gold        = Color(red: 1.00, green: 0.82, blue: 0.30)
    private let groundColor = Color(red: 0.04, green: 0.05, blue: 0.1)
    private let cardFill    = Color(red: 0.12, green: 0.10, blue: 0.28)
    private let cardCorner: CGFloat = 24
    private let sidebarCorner: CGFloat = 28
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { rootGeo in
            ZStack {
                background(in: rootGeo.size)
                
                planet
                    .position(x: rootGeo.size.width * 0.84, y: rootGeo.size.height * 0.26)
                
                constellation
                    .position(x: rootGeo.size.width * 0.63, y: rootGeo.size.height * 0.45)
                
                astronaut
                    .position(x: rootGeo.size.width * 0.88, y: rootGeo.size.height * 0.80)
                
                HStack {
                    sidebar
                        .padding(.leading, 24)
                        .padding(.top, 110)
                    Spacer()
                }
                
                VStack {
                    topBar
                    Spacer()
                }
                
                if draggingMissionIndex != nil {
                    rewardStar(size: 50)
                        .scaleEffect(1.1)
                        .position(dragPoint)
                        .allowsHitTesting(false)
                        .zIndex(10)
                }
                
                if showCelebration {
                    celebration
                        .zIndex(20)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                    astronautFloat = true
                }
                constellationCenter = CGPoint(x: rootGeo.size.width * 0.63, y: rootGeo.size.height * 0.45)
                constellationSize = CGSize(width: rootGeo.size.width * 0.5, height: rootGeo.size.height * 0.55)
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    starWiggle = true
                    
                }
            }
            .onChange(of: rootGeo.size) { newSize in
                constellationCenter = CGPoint(x: newSize.width * 0.63, y: newSize.height * 0.45)
                constellationSize = CGSize(width: newSize.width * 0.5, height: newSize.height * 0.55)
            }
        }
        .coordinateSpace(name: "root")
        .background(groundColor.ignoresSafeArea())
    }
    
    // MARK: - Top bar
    
    private var topBar: some View {
        HStack {
            starBalanceCapsule
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Text("مهام اليوم")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(
                       LinearGradient(
                           colors: [Color.white, Color(red: 0.65, green: 0.80, blue: 1.0)],
                           startPoint: .top,
                           endPoint: .bottom
                           ) )
            Spacer()
            Button(action: {}) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(turquoise.opacity(0.85)))
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 24)
    }

    private var starBalanceCapsule: some View {
        
        HStack(spacing: 10) {
            
            Text("رصيد النجوم")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 25))
                    .foregroundColor(gold)
                Text("x\(starBalance)")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundColor(gold)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.black.opacity(0.25)))
        .overlay(Capsule().stroke(gold.opacity(0.6), lineWidth: 2))
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: starBalance)
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        VStack(spacing: 45) {
            ForEach(missionTitles.indices, id: \.self) { index in
                if !missionRewardClaimed[index] {
                    missionCard(index)
                        .transition(
                            .scale(scale: 0.85)
                            .combined(with: .opacity)
                        )
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: missionRewardClaimed)
        .padding(20)
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: sidebarCorner, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        )
        .background(
            RoundedRectangle(cornerRadius: sidebarCorner, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: sidebarCorner, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }
    private func missionCard(_ index: Int) -> some View {
        let completed = missionProgress[index] >= 1.0
        let showsReward = completed && !missionRewardClaimed[index]
        
        return VStack(alignment: .trailing, spacing: 10) {
            Text(missionTitles[index])
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text(missionSubtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            if showsReward {
                rewardStar(size: 42)
                    .opacity(draggingMissionIndex == index ? 0 : 1)
                    .scaleEffect(starWiggle ? 1.08 : 1.0)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .padding(.vertical, 4)
                    .gesture(
                        DragGesture(minimumDistance: 2, coordinateSpace: .named("root"))
                            .onChanged { value in
                                draggingMissionIndex = index
                                dragPoint = value.location
                            }
                            .onEnded { value in
                                tryFillNode(at: value.location, missionIndex: index)
                                draggingMissionIndex = nil
                            }
                    )
            } else {
                progressBar(progress: missionProgress[index], isComplete: completed)
                    .frame(height: 5)
                
                if !completed {
                    Button(action: {}) {
                        Text("إبدأ")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(turquoise)
                            .clipShape(Capsule())
                    }
                    .frame(minHeight: 44)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.35)
        )
        .background(
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .fill(cardFill.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .stroke(completed ? gold : Color.white.opacity(0.12), lineWidth: completed ? 1.5 : 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
        .animation(.easeInOut(duration: 0.35), value: completed)
    }
    
    private func progressBar(progress: Double, isComplete: Bool) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule()
                    .fill(isComplete ? gold : turquoise)
                    .frame(width: max(4, geo.size.width * progress))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: progress)
    }
    
    private func rewardStar(size: CGFloat) -> some View {
        Image(systemName: "star.fill")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundColor(gold)
            .shadow(color: gold.opacity(0.9), radius: size * 0.35)
            .shadow(color: gold.opacity(0.5), radius: size * 0.7)
    }
    
    // MARK: - Constellation
    
    private var constellation: some View {
        ZStack {
            Path { path in
                guard nodeX.count > 1 else { return }
                let points = zip(nodeX, nodeY).map {
                    CGPoint(x: $0 * constellationSize.width, y: $1 * constellationSize.height)
                }
                path.move(to: points[0])
                for p in points.dropFirst() { path.addLine(to: p) }
            }
            .stroke(
                LinearGradient(colors: [Color.white.opacity(0.35), gold.opacity(0.45)],
                               startPoint: .leading, endPoint: .trailing),
                lineWidth: 1.5
            )
            
            ForEach(nodeX.indices, id: \.self) { i in
                constellationNode(i)
                    .position(x: nodeX[i] * constellationSize.width,
                              y: nodeY[i] * constellationSize.height)
            }
        }
        .frame(width: constellationSize.width, height: constellationSize.height)
    }
    
    private func constellationNode(_ index: Int) -> some View {
        ZStack {
            if nodeSparkleOpacity[index] > 0 {
                ForEach(0..<6, id: \.self) { i in
                    let angle = Double(i) / 6.0 * 2 * .pi
                    Circle()
                        .fill(gold)
                        .frame(width: 4, height: 4)
                        .offset(x: cos(angle) * 26, y: sin(angle) * 26)
                        .opacity(nodeSparkleOpacity[index])
                }
            }
            Image(systemName: "star.fill")
                .resizable()
                .frame(width: nodeFilled[index] ? 40: 30, height: nodeFilled[index] ? 34: 22)
                .foregroundColor(nodeFilled[index] ? gold : Color.white.opacity(0.5))
                .shadow(color: nodeFilled[index] ? gold.opacity(0.9) : .clear,
                        radius: nodeFilled[index] ? 16 : 0)
                .scaleEffect(nodePulse[index])
        }
        .frame(width: 44, height: 44) // مساحة لمس مناسبة لهدف الإفلات
        .animation(.easeOut(duration: 0.4), value: nodeSparkleOpacity[index])
    }
    
    // MARK: - Drag & drop logic
    
    private func tryFillNode(at point: CGPoint, missionIndex: Int) {
        let origin = CGPoint(x: constellationCenter.x - constellationSize.width / 2,
                             y: constellationCenter.y - constellationSize.height / 2)
        
        for i in nodeX.indices where !nodeFilled[i] {
            let nodeAbsolute = CGPoint(x: origin.x + nodeX[i] * constellationSize.width,
                                       y: origin.y + nodeY[i] * constellationSize.height)
            let distance = hypot(nodeAbsolute.x - point.x, nodeAbsolute.y - point.y)
            guard distance < 44 else { continue }
            
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                nodeFilled[i] = true
                nodePulse[i] = 1.4
            }
            nodeSparkleOpacity[i] = 1
            missionRewardClaimed[missionIndex] = true
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                starBalance += 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.3)) { nodePulse[i] = 1.0 }
                nodeSparkleOpacity[i] = 0
            }
            
            checkCelebration()
            return
        }
    }
    
    private func checkCelebration() {
        guard !nodeFilled.isEmpty, nodeFilled.allSatisfy({ $0 }) else { return }
        withAnimation(.easeInOut(duration: 0.8)) { showCelebration = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 0.6)) { showCelebration = false }
        }
    }
    
    // MARK: - Background & placeholder illustrations
    
    
    private func background(in size: CGSize) -> some View {
        ZStack {
            LinearGradient(colors: [navyTop, navyMid, purple], startPoint: .top, endPoint: .bottom)
            
            // نجوم صغيرة بتوزيع ثابت (deterministic) حتى ما تتحرك بين التحديثات
            ForEach(0..<40, id: \.self) { i in
                let x = CGFloat((i * 53) % 100) / 100 * size.width
                let y = CGFloat((i * 37) % 100) / 100 * size.height * 0.65
                let starSize = CGFloat(1 + (i % 3))
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: starSize, height: starSize)
                    .position(x: x, y: y)
            }
            
            // الأرض المنحنية بالأسفل
            Path { path in
                let rect = CGRect(origin: .zero, size: size)
                
                path.move(to: CGPoint(x: 0, y: rect.height))
                path.addLine(to: CGPoint(x: 0, y: rect.height * 0.86))
                path.addCurve(
                    to: CGPoint(x: rect.width, y: rect.height * 0.86),
                    control1: CGPoint(x: rect.width * 0.35, y: rect.height * 0.72),
                    control2: CGPoint(x: rect.width * 0.65, y: rect.height * 0.99)
                )
                path.addLine(to: CGPoint(x: rect.width, y: rect.height))
                path.closeSubpath()
            }
            .fill(groundColor)
        }
        
     
    }
    
    private var planet: some View {
        ZStack {
            Image("planet")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .offset(y: floating ? -15 : 15)
                .animation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true),
                    value: floating
                )
                .onAppear {
                    floating = true
                }
        }
    }
    
    private var stars: some View {
        //نجومنا
        Image("Stars")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .opacity(isAnimating ? 1.0 : 0.1)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
        
     
    }
    private var astronaut: some View {
        Image("astronaut")
            .resizable()
            .scaledToFit()
            .frame(width: 390, height: 400)
            .offset(y: astronautFloat ? -14 : 0)
            .rotationEffect(.degrees(astronautFloat ? 3 : -3), anchor: .bottom)
            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: astronautFloat ? 4 : 14)
    }
    // MARK: - Celebration overlay

    private var celebration: some View {
        VStack {
            Spacer()
            Text("✨ رائع! أكملت كوكبة اليوم!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(Capsule().fill(cardFill.opacity(0.85)))
                .overlay(Capsule().stroke(gold, lineWidth: 1.5))
                .shadow(color: gold.opacity(0.5), radius: 20)
            Spacer()
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}

// MARK: - Preview

#Preview {
    TodaysMissionsView()
}
