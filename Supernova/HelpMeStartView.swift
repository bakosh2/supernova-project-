//
//  HelpMeStartView.swift
//  Supernova
//

import SwiftUI
import Combine

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

// MARK: - ViewModel
/// ViewModel managing the state for the "ساعدني أبدأ" (Help Me Start) checklist.
@MainActor
final class HelpMeStartViewModel: ObservableObject {
    @Published var isQuietPlaceChecked: Bool = false
    @Published var hasMaterialsChecked: Bool = false
    @Published var hasWaterChecked: Bool = false
    
    /// Returns true only when all three checklist items are checked.
    var allItemsChecked: Bool {
        isQuietPlaceChecked && hasMaterialsChecked && hasWaterChecked
    }
    
    /// Toggles the quiet place state.
    func toggleQuietPlace() {
        isQuietPlaceChecked.toggle()
    }
    
    /// Toggles the materials state.
    func toggleMaterials() {
        hasMaterialsChecked.toggle()
    }
    
    /// Toggles the water state.
    func toggleWater() {
        hasWaterChecked.toggle()
    }
    
    /// Resets all checklist items to false.
    func resetChecklist() {
        isQuietPlaceChecked = false
        hasMaterialsChecked = false
        hasWaterChecked = false
    }
}

// MARK: - Components

/// Back Capsule Button
struct BackCapsuleButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 110, height: 42)
                .background(Color.tealPrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.35))
                )
        }
    }
}

/// Checklist Row Component
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
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.purpleCheckbox)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
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

/// Main Action Button ("يلا نبدأ!")
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

// MARK: - Main HelpMeStartView Screen

/// Main native SwiftUI screen for "ساعدني أبدأ" (Help Me Start) on iPadOS landscape.
struct HelpMeStartView: View {
    let task: HomeworkTask?
    var onBack: () -> Void = {}
    var onStart: (HomeworkTask) -> Void = { _ in }
    
    @StateObject private var viewModel = HelpMeStartViewModel()
    @Environment(\.dismiss) private var dismiss
    
    init(
        task: HomeworkTask? = nil,
        onBack: @escaping () -> Void = {},
        onStart: @escaping (HomeworkTask) -> Void = { _ in }
    ) {
        self.task = task
        self.onBack = onBack
        self.onStart = onStart
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            // Dynamic proportional sizing for responsive landscape iPad layout
            let contentWidth = min(screenWidth * 0.48, 540)
            let astronautWidth = min(screenWidth * 0.24, 280)
            
            ZStack(alignment: .topTrailing) {
                // Background space gradient with decorative stars
                SpaceBackgroundView()
                
                // Centered vertical content column (Title, 3 Checklist Rows, Start Button)
                VStack(spacing: 30) {
                    // Top area spacing below top bar
                    Spacer()
                        .frame(height: max(screenHeight * 0.08, 40))
                    
                    // Arabic header title "ساعدني أبدأ"
                    Text("ساعدني أبدأ")
                        .font(.system(size: min(screenWidth * 0.042, 52), weight: .bold))
                        .foregroundColor(.white)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.bottom, max(screenHeight * 0.04, 28))
                    
                    // Vertically stacked checklist rows
                    VStack(spacing: max(screenHeight * 0.02, 16)) {
                        HelpChecklistRow(
                            title: "هل مكانك هادئ؟",
                            isSelected: viewModel.isQuietPlaceChecked,
                            onTap: { viewModel.toggleQuietPlace() }
                        )
                        
                        HelpChecklistRow(
                            title: "هل معك أدواتك؟",
                            isSelected: viewModel.hasMaterialsChecked,
                            onTap: { viewModel.toggleMaterials() }
                        )
                        
                        HelpChecklistRow(
                            title: "هل معك ماء؟",
                            isSelected: viewModel.hasWaterChecked,
                            onTap: { viewModel.toggleWater() }
                        )
                    }
                    .frame(width: contentWidth)
                    .padding(.bottom, max(screenHeight * 0.04, 32))
                    
                    // Main action button ("يلا نبدأ!")
                    HelpMeStartButton(
                        isEnabled: viewModel.allItemsChecked,
                        action: {
                            if let task = task {
                                onStart(task)
                            }
                        }
                    )
                    .frame(width: min(contentWidth * 0.88, 440))
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
                // Upper-Right Back Button (Teal Capsule)
                BackCapsuleButton(action: {
                    onBack()
                })
                .padding(.top, max(screenHeight * 0.04, 28))
                .padding(.trailing, max(screenWidth * 0.04, 36))
                
                // Lower-Left Astronaut Illustration with Star
                VStack {
                    Spacer()
                    HStack {
                        ZStack(alignment: .topTrailing) {
                            Image("astronaut 2")
                                .frame(width: 350)
                                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                            
                            // Yellow star asset
                            Image("Star")
                                .frame(width: astronautWidth * 0.4)
                                .offset(x: -35, y: 60)
                        }
                        .padding(.leading, max(screenWidth * 0.03, 18))
                        .padding(.bottom, max(screenHeight * 0.04, 18))
                        
                        Spacer()
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

// MARK: - Task Flow Container

struct TaskFlowView: View {
    enum TaskFlowScreen {
        case helpMeStart
        case taskSession
        case completion
    }
    
    let task: HomeworkTask
    let onExitToMain: () -> Void
    let onPINRequired: (HomeworkTask) -> Void
    let verifyCompletionPIN: (String) -> Bool
    
    @State private var currentScreen: TaskFlowScreen
    
    init(
        task: HomeworkTask,
        onExitToMain: @escaping () -> Void,
        onPINRequired: @escaping (HomeworkTask) -> Void = { _ in },
        verifyCompletionPIN: @escaping (String) -> Bool = { pin in pin == "1234" }
    ) {
        self.task = task
        self.onExitToMain = onExitToMain
        self.onPINRequired = onPINRequired
        self.verifyCompletionPIN = verifyCompletionPIN
        
        let startingScreen: TaskFlowScreen
        if task.isCompleted {
            startingScreen = .completion
        } else if task.phase == .notStarted {
            startingScreen = .helpMeStart
        } else {
            startingScreen = .taskSession
        }
        
        _currentScreen = State(initialValue: startingScreen)
    }
    
    var body: some View {
        switch currentScreen {
        case .helpMeStart:
            HelpMeStartView(
                task: task,
                onBack: {
                    onExitToMain()
                },
                onStart: { _ in
                    currentScreen = .taskSession
                }
            )
            
        case .taskSession:
            TaskSessionView(
                task: task,
                onExit: {
                    onExitToMain()
                },
                onPINRequired: { selectedTask in
                    onPINRequired(selectedTask)
                },
                onTaskCompleted: { completedTaskID in
                    guard completedTaskID == task.id else { return }
                    currentScreen = .completion
                },
                verifyCompletionPIN: verifyCompletionPIN
            )
            
        case .completion:
            TaskCompletionView(
                task: task,
                onClose: {
                    onExitToMain()
                }
            )
        }
    }
}

// MARK: - Previews

#Preview("Help Me Start View") {
    let sampleTask = HomeworkTask.createFromTaskCreation(
        title: "واجب الرياضيات",
        focusDurationMinutes: 10,
        breakDurationMinutes: 5,
        validityDays: 1,
        stepTitles: ["حل تمارين ص ١٥"],
        requiresCompletionPIN: false
    )!
    
    return HelpMeStartView(task: sampleTask)
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDevice(PreviewDevice(rawValue: "iPad Air 11-inch (M4)"))
}

#Preview("1. Flow - New Task (Help Me Start)") {
    let sampleTask = HomeworkTask.createFromTaskCreation(
        title: "واجب العلوم",
        focusDurationMinutes: 10,
        breakDurationMinutes: 5,
        validityDays: 1,
        stepTitles: ["قراءة الدرس", "حل الأسئلة"],
        requiresCompletionPIN: false
    )!
    
    return TaskFlowView(task: sampleTask, onExitToMain: {})
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDevice(PreviewDevice(rawValue: "iPad Air 11-inch (M4)"))
}

#Preview("2. Flow - Started Focus Task") {
    let sampleTask = HomeworkTask.createFromTaskCreation(
        title: "واجب الرياضيات",
        focusDurationMinutes: 10,
        breakDurationMinutes: 5,
        validityDays: 1,
        stepTitles: ["حل تمارين ص ١٥"],
        requiresCompletionPIN: false
    )!
    sampleTask.phase = .focus
    
    return TaskFlowView(task: sampleTask, onExitToMain: {})
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDevice(PreviewDevice(rawValue: "iPad Air 11-inch (M4)"))
}

#Preview("3. Flow - Saved Break Task") {
    let sampleTask = HomeworkTask.createFromTaskCreation(
        title: "واجب لغتي",
        focusDurationMinutes: 10,
        breakDurationMinutes: 5,
        validityDays: 1,
        stepTitles: ["كتابة النص"],
        requiresCompletionPIN: false
    )!
    sampleTask.phase = .breakTime
    
    return TaskFlowView(task: sampleTask, onExitToMain: {})
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDevice(PreviewDevice(rawValue: "iPad Air 11-inch (M4)"))
}

#Preview("4. Flow - Completed Task") {
    let sampleTask = HomeworkTask.createFromTaskCreation(
        title: "واجب الإنجليزي",
        focusDurationMinutes: 10,
        breakDurationMinutes: 5,
        validityDays: 1,
        stepTitles: ["حفظ الكلمات"],
        requiresCompletionPIN: false
    )!
    sampleTask.isCompleted = true
    sampleTask.phase = .completed
    
    return TaskFlowView(task: sampleTask, onExitToMain: {})
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDevice(PreviewDevice(rawValue: "iPad Air 11-inch (M4)"))
}

#Preview("5. Flow - Future PIN Required Task") {
    let sampleTask = HomeworkTask.createFromTaskCreation(
        title: "واجب مع رمز الوالدين",
        focusDurationMinutes: 10,
        breakDurationMinutes: 5,
        validityDays: 1,
        stepTitles: ["المهمة الأولى"],
        requiresCompletionPIN: true
    )!
    
    return TaskFlowView(task: sampleTask, onExitToMain: {})
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDevice(PreviewDevice(rawValue: "iPad Air 11-inch (M4)"))
}
