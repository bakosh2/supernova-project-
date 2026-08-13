//
//  TodaysMissionsView.swift
//  Today's Missions – ADHD-friendly kids learning screen (iPad)
//

import SwiftUI
import SwiftData

struct TodaysMissionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HomeworkTask.createdAt, order: .forward) private var queriedTasks: [HomeworkTask]
    
    // MARK: - AppStorage Persisted State
    @AppStorage("totalStarsCollected") private var totalStarsCollected: Int = 0
    /// The code used for a protected task is always the parent's saved code.
    @AppStorage("savedParentPin") private var savedParentPin = ""

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
    /// Supplied when the dashboard is opened from the parent area. When it is
    /// opened from the child journey, the normal NavigationStack dismissal is
    /// used instead.
    var onBackToParent: (() -> Void)? = nil
    var onTaskDeleted: ((HomeworkTask) -> Void)? = nil
    
    // MARK: - Mission Data & UI State
    @State private var astronautFloat = false
    @State private var floating = false
    @State private var isAnimating = false
    @State private var selectedTaskForFlow: HomeworkTask? = nil
    
    // MARK: - Constellation Data
    private struct Constellation {
        struct Link: Identifiable {
            let id = UUID()
            let startStar: Int
            let endStar: Int
            /// Normalized points that trace the exact bend of the illustration.
            let points: [CGPoint]
        }

        let grayImage: String
        let completeImage: String
        let canvasSize: CGSize
        let points: [CGPoint]
        /// New illustration assets already contain their precise curves and
        /// line breaks. Render them directly rather than approximating them
        /// with straight SwiftUI segments.
        let usesArtwork: Bool
        /// The order in which stars are awarded traces the drawing itself.
        let collectionOrder: [Int]
        let links: [Link]
    }

    private let allConstellations: [Constellation] = [
        // The original interactive rocket: its outline is drawn by the app so
        // every dotted segment can light up progressively as stars are added.
        Constellation(
            grayImage: "interactive_rocket",
            completeImage: "interactive_rocket",
            canvasSize: CGSize(width: 1365, height: 2048),
            points: [
                CGPoint(x: 0.7637, y: 0.1135),
                CGPoint(x: 0.1168, y: 0.7286),
                CGPoint(x: 0.3147, y: 0.6633),
                CGPoint(x: 0.5989, y: 0.7289),
                CGPoint(x: 0.7068, y: 0.8666)
            ],
            usesArtwork: false,
            collectionOrder: [1, 2, 0, 3, 4],
            links: [
                .init(startStar: 1, endStar: 2, points: [CGPoint(x: 0.1168, y: 0.7286), CGPoint(x: 0.3147, y: 0.6633)]),
                .init(startStar: 2, endStar: 0, points: [CGPoint(x: 0.3147, y: 0.6633), CGPoint(x: 0.3050, y: 0.5850), CGPoint(x: 0.3500, y: 0.4300), CGPoint(x: 0.4700, y: 0.2850), CGPoint(x: 0.6200, y: 0.1900), CGPoint(x: 0.7637, y: 0.1135)]),
                .init(startStar: 0, endStar: 3, points: [CGPoint(x: 0.7637, y: 0.1135), CGPoint(x: 0.7900, y: 0.2300), CGPoint(x: 0.7800, y: 0.3800), CGPoint(x: 0.7200, y: 0.5400), CGPoint(x: 0.6500, y: 0.6500), CGPoint(x: 0.5989, y: 0.7289)]),
                .init(startStar: 3, endStar: 4, points: [CGPoint(x: 0.5989, y: 0.7289), CGPoint(x: 0.6550, y: 0.8000), CGPoint(x: 0.7068, y: 0.8666)])
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
            ],
            usesArtwork: false,
            collectionOrder: [3, 1, 0, 2, 4],
            links: [
                .init(startStar: 3, endStar: 1, points: [CGPoint(x: 0.2174, y: 0.7663), CGPoint(x: 0.0981, y: 0.3565)]),
                .init(startStar: 1, endStar: 0, points: [CGPoint(x: 0.0981, y: 0.3565), CGPoint(x: 0.3350, y: 0.5500), CGPoint(x: 0.4948, y: 0.1882)]),
                .init(startStar: 0, endStar: 2, points: [CGPoint(x: 0.4948, y: 0.1882), CGPoint(x: 0.6500, y: 0.5500), CGPoint(x: 0.8850, y: 0.3555)]),
                .init(startStar: 2, endStar: 4, points: [CGPoint(x: 0.8850, y: 0.3555), CGPoint(x: 0.7677, y: 0.7658)]),
                .init(startStar: 3, endStar: 4, points: [CGPoint(x: 0.2174, y: 0.7663), CGPoint(x: 0.7677, y: 0.7658)])
            ]
        ),
        // The boat drawing added in Assets.xcassets. It keeps the same reward
        // behaviour as the rocket and crown, but only needs its three stars.
        Constellation(
            grayImage: "boat_gray",
            completeImage: "boat_complete",
            canvasSize: CGSize(width: 2165, height: 2155),
            points: [
                CGPoint(x: 0.50, y: 0.145), // mast-top star
                CGPoint(x: 0.14, y: 0.700), // left hull star
                CGPoint(x: 0.85, y: 0.700)  // right hull star
            ],
            usesArtwork: false,
            collectionOrder: [1, 0, 2],
            links: [
                .init(startStar: 1, endStar: 0, points: [CGPoint(x: 0.14, y: 0.700), CGPoint(x: 0.50, y: 0.145)]),
                .init(startStar: 0, endStar: 2, points: [CGPoint(x: 0.50, y: 0.145), CGPoint(x: 0.85, y: 0.700)]),
                .init(startStar: 1, endStar: 2, points: [CGPoint(x: 0.14, y: 0.700), CGPoint(x: 0.85, y: 0.700)])
            ]
        ),
        // House: the new supplied artwork, with the same star-reward flow.
        Constellation(
            grayImage: "house_gray",
            completeImage: "house_complete",
            canvasSize: CGSize(width: 2048, height: 2048),
            points: [
                CGPoint(x: 0.500, y: 0.145),
                CGPoint(x: 0.105, y: 0.490),
                CGPoint(x: 0.895, y: 0.490),
                CGPoint(x: 0.105, y: 0.930),
                CGPoint(x: 0.895, y: 0.930)
            ],
            // Draw the supplied house as an interactive constellation, not as
            // a static picture underneath it. This avoids duplicate stars and
            // lines while retaining the same reward animation as before.
            usesArtwork: false,
            collectionOrder: [3, 0, 2, 1, 4],
            links: [
                .init(startStar: 3, endStar: 1, points: [CGPoint(x: 0.105, y: 0.930), CGPoint(x: 0.105, y: 0.490)]),
                .init(startStar: 1, endStar: 0, points: [CGPoint(x: 0.105, y: 0.490), CGPoint(x: 0.500, y: 0.145)]),
                .init(startStar: 0, endStar: 2, points: [CGPoint(x: 0.500, y: 0.145), CGPoint(x: 0.895, y: 0.490)]),
                .init(startStar: 2, endStar: 4, points: [CGPoint(x: 0.895, y: 0.490), CGPoint(x: 0.895, y: 0.930)]),
                .init(startStar: 3, endStar: 4, points: [CGPoint(x: 0.105, y: 0.930), CGPoint(x: 0.895, y: 0.930)])
            ]
        ),
        // The new rocket illustration keeps the current drag-and-reward flow.
        Constellation(
            grayImage: "rocket2_gray",
            completeImage: "rocket2_complete",
            canvasSize: CGSize(width: 2048, height: 2048),
            points: [
                CGPoint(x: 0.500, y: 0.085),
                CGPoint(x: 0.110, y: 0.575),
                CGPoint(x: 0.890, y: 0.575),
                CGPoint(x: 0.350, y: 0.775),
                CGPoint(x: 0.650, y: 0.775)
            ],
            usesArtwork: false,
            collectionOrder: [1, 0, 2, 4, 3],
            links: [
                .init(startStar: 1, endStar: 0, points: [CGPoint(x: 0.110, y: 0.575), CGPoint(x: 0.500, y: 0.085)]),
                .init(startStar: 0, endStar: 2, points: [CGPoint(x: 0.500, y: 0.085), CGPoint(x: 0.890, y: 0.575)]),
                .init(startStar: 1, endStar: 3, points: [CGPoint(x: 0.110, y: 0.575), CGPoint(x: 0.350, y: 0.775)]),
                .init(startStar: 2, endStar: 4, points: [CGPoint(x: 0.890, y: 0.575), CGPoint(x: 0.650, y: 0.775)])
            ]
        ),
        // The new star outline is the third replacement drawing.
        Constellation(
            grayImage: "star_gray",
            completeImage: "star_complete",
            canvasSize: CGSize(width: 2048, height: 2048),
            points: [
                CGPoint(x: 0.500, y: 0.145),
                CGPoint(x: 0.095, y: 0.425),
                CGPoint(x: 0.905, y: 0.425),
                CGPoint(x: 0.260, y: 0.900),
                CGPoint(x: 0.740, y: 0.900)
            ],
            usesArtwork: false,
            collectionOrder: [3, 1, 0, 2, 4],
            links: [
                .init(startStar: 3, endStar: 1, points: [CGPoint(x: 0.260, y: 0.900), CGPoint(x: 0.095, y: 0.425)]),
                .init(startStar: 1, endStar: 0, points: [CGPoint(x: 0.095, y: 0.425), CGPoint(x: 0.500, y: 0.145)]),
                .init(startStar: 0, endStar: 2, points: [CGPoint(x: 0.500, y: 0.145), CGPoint(x: 0.905, y: 0.425)]),
                .init(startStar: 2, endStar: 4, points: [CGPoint(x: 0.905, y: 0.425), CGPoint(x: 0.740, y: 0.900)]),
                .init(startStar: 4, endStar: 3, points: [CGPoint(x: 0.740, y: 0.900), CGPoint(x: 0.260, y: 0.900)])
            ]
        )
    ]

    // The original rocket is retired; the three newly supplied drawings are
    // used instead alongside the existing crown and boat.
    private var constellations: [Constellation] {
        allConstellations
    }

    private var currentConstellation: Constellation {
        let safeIndex = max(0, min(currentConstellationIndex, constellations.count - 1))
        return constellations[safeIndex]
    }

    private let constellationStarSize: CGFloat = 52
    @State private var nodePulse: [CGFloat] = [1, 1, 1, 1, 1]
    @State private var dottedLinePhase: CGFloat = 0
    @State private var litLinksGlow = false
    @State private var constellationCompletionProgress: CGFloat = 0

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

    private func goBack() {
        if let onBackToParent {
            onBackToParent()
        } else {
            dismiss()
        }
    }
    
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
                        .padding(.top, 82)
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
                        // Keep the praise directly above the constellation,
                        // rather than centred over the whole dashboard.
                        .position(x: rootGeo.size.width * 0.63, y: rootGeo.size.height * 0.16)
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
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                    dottedLinePhase = 12
                }
                withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                    litLinksGlow = true
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
        // The child dashboard supplies its own green back button. Hide the
        // automatic translucent NavigationStack button to avoid duplicates.
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(item: $selectedTaskForFlow) { task in
            TaskFlowView(
                task: task,
                onExitToMain: {
                    selectedTaskForFlow = nil
                },
                verifyCompletionPIN: { enteredPin in
                    !savedParentPin.isEmpty && enteredPin == savedParentPin
                }
            )
        }
    }
    
    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            BackCapsuleButton(action: goBack)
            Spacer()
            starBalanceCapsule
        }
        .padding(.horizontal, AppHeaderLayout.horizontal)
        .padding(.top, AppHeaderLayout.top)
    }

    private var starBalanceCapsule: some View {
        HStack(spacing: 10) {
            Text("رصيد النجوم")
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 21))
                    .foregroundColor(gold)
                Text("\(totalStarsCollected)")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundColor(gold)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Capsule().fill(Color.black.opacity(0.25)))
        .overlay(Capsule().stroke(gold.opacity(0.6), lineWidth: 2))
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: totalStarsCollected)
    }
    
    // MARK: - Sidebar (Translucent task panel)
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("مهام اليوم")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.65, green: 0.80, blue: 1.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(maxWidth: .infinity, alignment: .center)

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
            .frame(width: 340)
            .frame(maxHeight: 575)
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
        .frame(width: 340)
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
                            .supernovaGlassCapsule()
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
        constellationCompletionProgress = 0
    }

    private var allStarsFilled: Bool {
        // Some drawings, such as the boat, intentionally have fewer than
        // five stars. Completion therefore follows the current drawing only.
        currentConstellation.points.indices.allSatisfy(isStarFilled)
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
            // Keep the supplied drawing as the source of truth for the new
            // butterfly, fish and bunny routes. Its original curved outline
            // remains visible beneath the interactive stars.
            if currentConstellation.usesArtwork {
                Image(allStarsFilled ? currentConstellation.completeImage : currentConstellation.grayImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: constellationSize.width, height: constellationSize.height)
                    .opacity(allStarsFilled ? min(0.45 + constellationCompletionProgress * 0.55, 1) : 0.62)
                    .animation(.easeInOut(duration: 0.35), value: allStarsFilled)
            }

            // Interactive paths follow the current reward order: neutral
            // dotted segments first, then glowing segments as stars connect.
            if currentConstellation.grayImage == "interactive_rocket" {
                rocketDecoration
            } else if currentConstellation.grayImage == "boat_gray" {
                boatDecoration
            }

            if !currentConstellation.usesArtwork {
                ForEach(Array(currentConstellation.links.enumerated()), id: \.element.id) { index, link in
                let linkIsLit = isStarFilled(link.startStar) && isStarFilled(link.endStar)
                let reveal = min(max(constellationCompletionProgress * CGFloat(currentConstellation.links.count) - CGFloat(index), 0), 1)

                if allStarsFilled {
                    constellationPath(for: link)
                        .trim(from: 0, to: reveal)
                        .stroke(gold, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                        .shadow(color: gold.opacity(0.9), radius: 7)
                } else {
                    constellationPath(for: link)
                        .stroke(
                            linkIsLit ? gold.opacity(litLinksGlow ? 1 : 0.65) : Color.white.opacity(0.30),
                            style: StrokeStyle(
                                lineWidth: linkIsLit ? 2.2 : 1.4,
                                lineCap: .round,
                                lineJoin: .round,
                                dash: [0.8, 6],
                                dashPhase: dottedLinePhase
                            )
                        )
                        .shadow(color: linkIsLit ? gold.opacity(litLinksGlow ? 0.95 : 0.35) : .clear, radius: linkIsLit ? 7 : 0)
                        .animation(.easeInOut(duration: 0.35), value: linkIsLit)
                }
                }
            }

            // SwiftUI stars always stay above the PNG.
            ForEach(currentConstellation.points.indices, id: \.self) { i in
                Group {
                    if isStarFilled(i) {
                        rewardStar(size: constellationStarSize)
                    } else {
                        Image(systemName: "star.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: constellationStarSize, height: constellationStarSize)
                            .foregroundColor(.gray)
                    }
                }
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

    private func constellationPath(for link: Constellation.Link) -> Path {
        Path { path in
            guard let first = link.points.first else { return }
            path.move(to: CGPoint(x: first.x * constellationSize.width, y: first.y * constellationSize.height))
            for point in link.points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x * constellationSize.width, y: point.y * constellationSize.height))
            }
        }
    }

    /// The original rocket's fins and window follow the same dotted-to-gold
    /// animation as its star connections.
    private var rocketDecoration: some View {
        let path = Path { path in
            path.move(to: CGPoint(x: constellationSize.width * 0.12, y: constellationSize.height * 0.70))
            path.addLine(to: CGPoint(x: constellationSize.width * 0.16, y: constellationSize.height * 0.58))
            path.addLine(to: CGPoint(x: constellationSize.width * 0.30, y: constellationSize.height * 0.49))

            path.move(to: CGPoint(x: constellationSize.width * 0.61, y: constellationSize.height * 0.64))
            path.addLine(to: CGPoint(x: constellationSize.width * 0.73, y: constellationSize.height * 0.80))
            path.addLine(to: CGPoint(x: constellationSize.width * 0.70, y: constellationSize.height * 0.90))

            path.addEllipse(in: CGRect(
                x: constellationSize.width * 0.42,
                y: constellationSize.height * 0.39,
                width: constellationSize.width * 0.19,
                height: constellationSize.height * 0.12
            ))
        }

        return path
            .trim(from: 0, to: allStarsFilled ? constellationCompletionProgress : 1)
            .stroke(
                allStarsFilled ? gold : Color.white.opacity(0.30),
                style: StrokeStyle(
                    lineWidth: allStarsFilled ? 2.2 : 1.4,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: allStarsFilled ? [] : [0.8, 6],
                    dashPhase: dottedLinePhase
                )
            )
            .shadow(color: allStarsFilled ? gold.opacity(0.85) : .clear, radius: allStarsFilled ? 7 : 0)
    }

    /// Mast and curved hull for the boat illustration. Like the rocket,
    /// neutral dots turn into a solid glowing drawing once all its stars are
    /// collected.
    private var boatDecoration: some View {
        let path = Path { path in
            // Mast.
            path.move(to: CGPoint(x: constellationSize.width * 0.50, y: constellationSize.height * 0.23))
            path.addLine(to: CGPoint(x: constellationSize.width * 0.50, y: constellationSize.height * 0.70))

            // Curved lower hull.
            path.move(to: CGPoint(x: constellationSize.width * 0.14, y: constellationSize.height * 0.76))
            path.addLine(to: CGPoint(x: constellationSize.width * 0.30, y: constellationSize.height * 0.90))
            path.addLine(to: CGPoint(x: constellationSize.width * 0.70, y: constellationSize.height * 0.90))
            path.addLine(to: CGPoint(x: constellationSize.width * 0.85, y: constellationSize.height * 0.76))
        }

        return path
            .trim(from: 0, to: allStarsFilled ? constellationCompletionProgress : 1)
            .stroke(
                allStarsFilled ? gold : Color.white.opacity(0.30),
                style: StrokeStyle(
                    lineWidth: allStarsFilled ? 2.2 : 1.4,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: allStarsFilled ? [] : [0.8, 6],
                    dashPhase: dottedLinePhase
                )
            )
            .shadow(color: allStarsFilled ? gold.opacity(0.85) : .clear, radius: allStarsFilled ? 7 : 0)
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

        // Award stars in the order of the illustrated constellation path.
        for i in currentConstellation.collectionOrder where !isStarFilled(i) {
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

        // Reveal the final solid line from the first segment to the last.
        constellationCompletionProgress = 0
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 1.8)) {
                constellationCompletionProgress = 1
            }
        }

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

    private var stars: some View {
        Image("Star")
            .resizable()
            .scaledToFit()
            .frame(width: 96, height: 96)
            .opacity(isAnimating ? 1.0 : 0.35)
            .scaleEffect(isAnimating ? 1.06 : 0.94)
            .animation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
    
    private var astronaut: some View {
        Image("astronaut 2")
            .resizable()
            .scaledToFit()
            .frame(width: 390, height: 400)
            .offset(y: astronautFloat ? -14 : 0)
            .rotationEffect(.degrees(astronautFloat ? 3 : -3), anchor: .bottom)
            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: astronautFloat ? 4 : 14)
    }
    
    // MARK: - Celebration Overlay
    private var celebration: some View {
        Text("احسنت!")
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(Capsule().fill(cardFill.opacity(0.85)))
            .overlay(Capsule().stroke(gold, lineWidth: 1.5))
            .shadow(color: gold.opacity(0.5), radius: 20)
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
