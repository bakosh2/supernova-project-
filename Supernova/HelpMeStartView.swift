//
//  HelpMeStartView.swift
//  Supernova
//

import SwiftUI

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
                            } else {
                                let fallbackTask = HomeworkTask.createFromTaskCreation(
                                    title: "واجب جديد",
                                    focusDurationMinutes: 10,
                                    breakDurationMinutes: 5,
                                    validityDays: 1,
                                    stepTitles: ["حل الأسئلة"],
                                    requiresCompletionPIN: false
                                )!
                                onStart(fallbackTask)
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
// A future child-main navigation will manage opening TaskFlowView.

struct TaskFlowView: View {
    enum TaskFlowScreen {
        case helpMeStart
        case taskSession
        case completion
    }
    
    let task: HomeworkTask
    let onExitToMain: () -> Void
    let onPINRequired: (HomeworkTask) -> Void
    
    @State private var currentScreen: TaskFlowScreen
    
    init(
        task: HomeworkTask,
        onExitToMain: @escaping () -> Void,
        onPINRequired: @escaping (HomeworkTask) -> Void = { _ in }
    ) {
        self.task = task
        self.onExitToMain = onExitToMain
        self.onPINRequired = onPINRequired
        
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
                }
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
    HelpMeStartView()
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
    
    TaskFlowView(task: sampleTask, onExitToMain: {})
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
