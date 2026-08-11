//
//  TodaysMissionsView.swift
//  Today's Missions – ADHD-friendly kids learning screen (iPad)
//

import SwiftUI
import SwiftData

struct TodaysMissionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HomeworkTask.createdAt, order: .forward) private var queriedTasks: [HomeworkTask]
    
    // MARK: - AppStorage Persisted State
    @AppStorage("totalStarsCollected") private var totalStarsCollected: Int = 0

    // Which constellation the child is currently working on.
    @AppStorage("currentConstellationIndex") private var currentConstellationIndex: Int = 0

    // Each star is saved automatically, so leaving and returning to this page
    // does not reset the current constellation.
    @AppStorage("constellationStar0Filled") private var star0Filled = false
    @AppStorage("constellationStar1Filled") private var star1Filled = false
    @AppStorage("constellationStar2Filled") private var star2Filled = false
    @AppStorage("constellationStar3Filled") private var star3Filled = false
    @AppStorage("constellationStar4Filled") private var star4Filled = false
    
    // Optional passed tasks for preview / testing
    var passedTasks: [HomeworkTask]? = nil
    var onBackToParent: () -> Void = {}
    var onTaskDeleted: ((HomeworkTask) -> Void)? = nil
    
    // MARK: - Mission Data & UI State
    @State private var astronautFloat = false
    @State private var floating = false
    @State private var selectedTaskForFlow: HomeworkTask? = nil
    
    // MARK: - Constellation Data
    private struct Constellation {
        let grayImage: String
        let completeImage: String
        let canvasSize: CGSize
        let points: [CGPoint]
    }

    private let constellations: [Constellation] = [
        Constellation(
            grayImage: "rocket_gray",
            completeImage: "rocket_complete",
            canvasSize: CGSize(width: 1365, height: 2048),
            points: [
                CGPoint(x: 0.7637, y: 0.1135), // top
                CGPoint(x: 0.1168, y: 0.7286), // far left
                CGPoint(x: 0.3147, y: 0.6633), // middle left
                CGPoint(x: 0.5989, y: 0.7289), // middle right
                CGPoint(x: 0.7068, y: 0.8666)  // bottom right
            ]
        ),
        Constellation(
            grayImage: "crown_gray",
            completeImage: "crown_complete",
            canvasSize: CGSize(width: 2048, height: 2038),
            points: [
                CGPoint(x: 0.4948, y: 0.1882), // top center
                CGPoint(x: 0.0981, y: 0.3565), // upper left
                CGPoint(x: 0.8850, y: 0.3555), // upper right
                CGPoint(x: 0.2174, y: 0.7663), // bottom left
                CGPoint(x: 0.7677, y: 0.7658)  // bottom right
            ]
        )
    ]

    private var currentConstellation: Constellation {
        let safeIndex = max(0, min(currentConstellationIndex, constellations.count - 1))
        return constellations[safeIndex]
    }

    private let constellationStarSize: CGFloat = 52
    @State private var nodePulse: [CGFloat] = [1, 1, 1, 1, 1]

    @State private var constellationCenter: CGPoint = .zero
    @State private var constellationSize: CGSize = CGSize(width: 1, height: 1)

    @State private var draggingTaskId: UUID? = nil
    @State private var dragPoint: CGPoint = .zero
    @State private var starWiggle = false
    @State private var showCelebration = false
    
    // MARK: - Theme Constants
    private let navyTop     = Color(red: 0.05, green: 0.07, blue: 0.20)
    private let navyMid     = Color(red: 0.15, green: 0.13, blue: 0.4)
    private let purple      = Color(red: 0.7, green: 0.30, blue: 0.9)
    private let turquoise   = Color(red: 0.20, green: 0.70, blue: 0.8)
    private let gold        = Color(red: 1.00, green: 0.82, blue: 0.30)
    private let groundColor = Color(red: 0.04, green: 0.05, blue: 0.1)
    private let cardFill    = Color(red: 0.12, green: 0.10, blue: 0.28)
    private let cardCorner: CGFloat = 24
    private let sidebarCorner: CGFloat = 28
    
    // MARK: - Task Lists
    private var allTasks: [HomeworkTask] {
        passedTasks ?? Array(queriedTasks)
    }
    
    /// Active tasks visible on child dashboard
    var visibleTaskCards: [HomeworkTask] {
        allTasks.filter { task in
            (!task.isCompleted || !task.isRewardCollected)
        }
    }
    
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
                
                // Dragged Reward Star Overlay
                if draggingTaskId != nil {
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
                constellationSize = constellationDisplaySize(for: rootGeo.size)
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    starWiggle = true
                }
            }
            .onChange(of: rootGeo.size) { newSize in
                constellationCenter = CGPoint(x: newSize.width * 0.63, y: newSize.height * 0.45)
                constellationSize = constellationDisplaySize(for: newSize)
            }
        }
        .ignoresSafeArea()
        .coordinateSpace(name: "dashboard")
        .background(groundColor.ignoresSafeArea())
        .fullScreenCover(item: $selectedTaskForFlow) { task in
            TaskFlowView(
                task: task,
                onExitToMain: {
                    selectedTaskForFlow = nil
                }
            )
        }
    }
    
    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            starBalanceCapsule
            Spacer()
            
            Text("مهام اليوم")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.65, green: 0.80, blue: 1.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Spacer()
            
            Button(action: onBackToParent) {
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
                Text("x\(totalStarsCollected)")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundColor(gold)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.black.opacity(0.25)))
        .overlay(Capsule().stroke(gold.opacity(0.6), lineWidth: 2))
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: totalStarsCollected)
    }
    
    // MARK: - Sidebar (Translucent task panel)
    private var sidebar: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                ForEach(visibleTaskCards) { task in
                    missionCard(task)
                        .transition(
                            .scale(scale: 0.85)
                            .combined(with: .opacity)
                        )
                }
            }
            .padding(.vertical, 10)
        }
        .animation(.easeInOut(duration: 0.4), value: visibleTaskCards.count)
        .padding(20)
        .frame(width: 300)
        .frame(maxHeight: 520)
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
    
    // MARK: - Task Card Rendering
    private func missionCard(_ task: HomeworkTask) -> some View {
        let completed = task.isCompleted
        let showsReward = completed && !task.isRewardCollected
        
        return VStack(alignment: .trailing, spacing: 10) {
            Text(task.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            if showsReward {
                // Draggable Reward Star
                rewardStar(size: 42)
                    .opacity(draggingTaskId == task.id ? 0 : 1)
                    .scaleEffect(starWiggle ? 1.08 : 1.0)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .padding(.vertical, 4)
                    .gesture(
                        DragGesture(minimumDistance: 2, coordinateSpace: .named("dashboard"))
                            .onChanged { value in
                                draggingTaskId = task.id
                                dragPoint = value.location
                            }
                            .onEnded { value in
                                tryFillNode(for: task, at: value.location)
                                draggingTaskId = nil
                            }
                    )
            } else {
                progressBar(progress: task.progress, isComplete: completed)
                    .frame(height: 5)
                
                if !completed {
                    Button(action: {
                        selectedTaskForFlow = task
                    }) {
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
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
        .animation(.easeInOut(duration: 0.35), value: completed)
        .contentShape(Rectangle())
        .onTapGesture {
            if !completed {
                selectedTaskForFlow = task
            }
        }
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
    
    // MARK: - Constellation Helpers

    private func constellationDisplaySize(for screenSize: CGSize) -> CGSize {
        let height = screenSize.height * 0.55
        let ratio = currentConstellation.canvasSize.width / currentConstellation.canvasSize.height
        let width = height * ratio
        return CGSize(width: width, height: height)
    }

    private func isStarFilled(_ index: Int) -> Bool {
        switch index {
        case 0: return star0Filled
        case 1: return star1Filled
        case 2: return star2Filled
        case 3: return star3Filled
        case 4: return star4Filled
        default: return false
        }
    }

    private func fillStar(_ index: Int) {
        switch index {
        case 0: star0Filled = true
        case 1: star1Filled = true
        case 2: star2Filled = true
        case 3: star3Filled = true
        case 4: star4Filled = true
        default: break
        }
    }

    private func resetStars() {
        star0Filled = false
        star1Filled = false
        star2Filled = false
        star3Filled = false
        star4Filled = false
        nodePulse = [1, 1, 1, 1, 1]
    }

    private var allStarsFilled: Bool {
        star0Filled &&
        star1Filled &&
        star2Filled &&
        star3Filled &&
        star4Filled
    }

    private func moveToNextConstellation() {
        currentConstellationIndex =
            (currentConstellationIndex + 1) % constellations.count

        resetStars()

        // Keep the same displayed height, but update the width for the new image ratio.
        let ratio = currentConstellation.canvasSize.width / currentConstellation.canvasSize.height
        constellationSize.width = constellationSize.height * ratio
    }

    // MARK: - Constellation View
    private var constellation: some View {
        ZStack {
            Image(
                allStarsFilled
                    ? currentConstellation.completeImage
                    : currentConstellation.grayImage
            )
            .resizable()
            .scaledToFit()
            .frame(
                width: constellationSize.width,
                height: constellationSize.height
            )

            // SwiftUI stars always stay above the PNG.
            ForEach(currentConstellation.points.indices, id: \.self) { i in
                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: constellationStarSize,
                        height: constellationStarSize
                    )
                    .foregroundColor(
                        isStarFilled(i) ? gold : Color.gray
                    )
                    .shadow(
                        color: isStarFilled(i) ? gold.opacity(0.9) : .clear,
                        radius: isStarFilled(i) ? 12 : 0
                    )
                    .scaleEffect(nodePulse[i])
                    .position(
                        x: currentConstellation.points[i].x * constellationSize.width,
                        y: currentConstellation.points[i].y * constellationSize.height
                    )
            }
        }
        .frame(
            width: constellationSize.width,
            height: constellationSize.height
        )
    }

    // MARK: - Drag & Drop Logic
    private func tryFillNode(for task: HomeworkTask, at point: CGPoint) {
        guard task.isCompleted else { return }
        guard !task.isRewardCollected else { return }
        

        // Find the top-left corner of the constellation on the dashboard.
        let constellationOrigin = CGPoint(
            x: constellationCenter.x - constellationSize.width / 2,
            y: constellationCenter.y - constellationSize.height / 2
        )

        // Check each unfilled star.
        for i in currentConstellation.points.indices where !isStarFilled(i) {
            let starPosition = CGPoint(
                x: constellationOrigin.x + currentConstellation.points[i].x * constellationSize.width,
                y: constellationOrigin.y + currentConstellation.points[i].y * constellationSize.height
            )

            let distance = hypot(
                starPosition.x - point.x,
                starPosition.y - point.y
            )

            // The child only has to drop reasonably close to the star.
            guard distance < 44 else { continue }

            fillStar(i)

            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                nodePulse[i] = 1.35
            }

            task.isRewardCollected = true
            totalStarsCollected += 1
            onTaskDeleted?(task)
            modelContext.delete(task)
            try? modelContext.save()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.25)) {
                    nodePulse[i] = 1.0
                }
            }

            checkCelebration()
            return
        }
    }

    private func checkCelebration() {
        guard allStarsFilled else { return }

        withAnimation(.easeInOut(duration: 0.8)) {
            showCelebration = true
        }

        // Let the child see the completed constellation, then move to the next one.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 0.6)) {
                showCelebration = false
            }

            moveToNextConstellation()
        }
    }
    
    // MARK: - Background & Placeholder Illustrations
    private func background(in size: CGSize) -> some View {
        ZStack {
            LinearGradient(colors: [navyTop, navyMid, purple], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ForEach(0..<40, id: \.self) { i in
                let x = CGFloat((i * 53) % 100) / 100 * size.width
                let y = CGFloat((i * 37) % 100) / 100 * size.height * 0.65
                let starSize = CGFloat(1 + (i % 3))
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: starSize, height: starSize)
                    .position(x: x, y: y)
            }
            
            Path { path in
                let rect = CGRect(origin: .zero, size: size)
                path.move(to: CGPoint(x: 0, y: rect.height + 200)) // Extend past bottom safe area
                path.addLine(to: CGPoint(x: 0, y: rect.height * 0.86))
                path.addCurve(
                    to: CGPoint(x: rect.width, y: rect.height * 0.86),
                    control1: CGPoint(x: rect.width * 0.35, y: rect.height * 0.72),
                    control2: CGPoint(x: rect.width * 0.65, y: rect.height * 0.99)
                )
                path.addLine(to: CGPoint(x: rect.width, y: rect.height + 200)) // Extend past bottom safe area
                path.closeSubpath()
            }
            .fill(groundColor)
        }
        .ignoresSafeArea()
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
                .onAppear { floating = true }
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
    
    // MARK: - Celebration Overlay
    private var celebration: some View {
        VStack {
            Spacer()
            Text("احسنت!")
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
#Preview(traits: .landscapeLeft) {
    let sampleTasks = [
        HomeworkTask.createFromTaskCreation(
            title: "قراءة قصة",
            focusDurationMinutes: 15,
            breakDurationMinutes: 3,
            stepTitles: ["قراءة الفصل الأول"],
            requiresCompletionPIN: false
        )!,
        HomeworkTask.createFromTaskCreation(
            title: "حل واجب الرياضيات",
            focusDurationMinutes: 10,
            breakDurationMinutes: 5,
            stepTitles: ["أكمل المسائل الفردية فقط", "حل سؤال ٤", "تأكد من حلك"],
            requiresCompletionPIN: false
        )!
    ]
    return TodaysMissionsView(passedTasks: sampleTasks)
}
