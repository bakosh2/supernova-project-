//
//  TaskSessionView.swift
//  Supernova
//

import SwiftUI
import SwiftData

/// Main Focus and Break task session view for iPadOS landscape.
struct TaskSessionView: View {
    let task: HomeworkTask
    var onExit: () -> Void = {}
    var onPINRequired: (HomeworkTask) -> Void = { _ in }
    var onTaskCompleted: (UUID) -> Void = { _ in }
    var verifyCompletionPIN: (String) -> Bool = { _ in false }
    
    @StateObject private var viewModel: TaskSessionViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var showLeaveConfirmation: Bool = false
    
    @State private var showPINCard: Bool = false
    @State private var enteredPIN: String = ""
    @State private var pinHasError: Bool = false
    
    init(
        task: HomeworkTask,
        onExit: @escaping () -> Void = {},
        onPINRequired: @escaping (HomeworkTask) -> Void = { _ in },
        onTaskCompleted: @escaping (UUID) -> Void = { _ in },
        verifyCompletionPIN: @escaping (String) -> Bool = { _ in false }
    ) {
        self.task = task
        self.onExit = onExit
        self.onPINRequired = onPINRequired
        self.onTaskCompleted = onTaskCompleted
        self.verifyCompletionPIN = verifyCompletionPIN
        
        let vm = TaskSessionViewModel(task: task)
        vm.onPINRequired = onPINRequired
        vm.onTaskCompleted = onTaskCompleted
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            ZStack(alignment: .topTrailing) {
                // Shared space background
                SpaceBackgroundView()
                
                // Main Focus or Break Session Layout
                HStack(spacing: max(screenWidth * 0.04, 32)) {
                    if viewModel.phase == .breakTime {
                        // --- BREAK SESSION LAYOUT ---
                        // Left Side: Encouragement Card
                        BreakEncouragementCard()
                            .frame(width: min(screenWidth * 0.44, 520))
                        
                        // Right Side: Break Timer & Skip Button
                        VStack(spacing: 28) {
                            Spacer()
                            
                            SessionTimerRing(
                                title: "وقت الراحة",
                                formattedTime: viewModel.formattedTime,
                                progress: viewModel.progress,
                                isBreak: true
                            )
                            
                            SkipBreakButton(action: { viewModel.skipBreak() })
                            
                            Spacer()
                        }
                        .frame(width: min(screenWidth * 0.38, 440))
                    } else {
                        // --- FOCUS SESSION LAYOUT (.focus, .focusPaused, .notStarted) ---
                        // Left Side: Task Card
                        FocusTaskCard(
                            taskTitle: task.title,
                            subtaskTitle: viewModel.currentSubtask?.title ?? "",
                            isSubtaskCompleted: viewModel.isCurrentSubtaskCompleted,
                            subtasks: viewModel.sortedSubtasks,
                            currentIndex: viewModel.currentSubtaskIndex,
                            isFirstSubtask: viewModel.isFirstSubtask,
                            actionButtonTitle: viewModel.primaryButtonTitle,
                            canAdvance: viewModel.canAdvance,
                            onToggleCheck: { viewModel.toggleCurrentSubtaskCompletion() },
                            onPreviousSubtask: { viewModel.moveToPreviousSubtask() },
                            onPrimaryAction: {
                                if viewModel.isLastSubtask {
                                    if task.requiresCompletionPIN {
                                        viewModel.stopTimer()
                                        showPINCard = true
                                    } else {
                                        viewModel.requestTaskCompletion()
                                    }
                                } else {
                                    viewModel.moveToNextSubtask()
                                }
                            }
                        )
                        .frame(width: min(screenWidth * 0.46, 540))
                        
                        // Right Side: Focus Timer & Pause/Resume Button
                        VStack(spacing: 28) {
                            Spacer()
                            
                            SessionTimerRing(
                                title: "وقت التركيز",
                                formattedTime: viewModel.formattedTime,
                                progress: viewModel.progress,
                                isBreak: false
                            )
                            
                            FocusPauseButton(
                                isPaused: viewModel.isFocusPaused,
                                action: { viewModel.toggleFocusPause() }
                            )
                            
                            Spacer()
                        }
                        .frame(width: min(screenWidth * 0.38, 440))
                    }
                }
                .padding(.horizontal, max(screenWidth * 0.04, 36))
                .padding(.top, max(screenHeight * 0.10, 60))
                .padding(.bottom, max(screenHeight * 0.05, 30))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Upper-Right Navigation Capsule Button (Leave Session)
                SessionNavigationButton(action: { showLeaveConfirmation = true })
                .padding(.top, max(screenHeight * 0.04, 28))
                .padding(.trailing, max(screenWidth * 0.04, 36))
                
                // Parent PIN Card Modal Overlay
                if showPINCard {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture {
                            closePINCard()
                        }
                    
                    ParentPINCard(
                        enteredPIN: $enteredPIN,
                        pinHasError: $pinHasError,
                        onClose: closePINCard,
                        onDigitPressed: { digit in addPINDigit(digit) },
                        onDeletePressed: { deletePINDigit() }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showPINCard)
        .onAppear {
            viewModel.setModelContext(modelContext)
            viewModel.startOrResumeSession()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .inactive || scenePhase == .background {
                viewModel.leaveAndSave()
            }
        }
        .onDisappear {
            viewModel.leaveAndSave()
        }
        .confirmationDialog(
            "الخروج من المهمة؟",
            isPresented: $showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("الخروج وحفظ التقدم", role: .destructive) {
                viewModel.leaveAndSave()
                onExit()
            }
            Button("البقاء", role: .cancel) {}
        } message: {
            Text("سيتم حفظ وقتك وتقدمك، ويمكنك المتابعة لاحقًا.")
        }
        .fullScreenCover(isPresented: $viewModel.shouldShowCompletion) {
            TaskCompletionView(task: task) {
                viewModel.shouldShowCompletion = false
                onExit()
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    // MARK: - Parent PIN Actions
    
    private func addPINDigit(_ digit: String) {
        if pinHasError {
            pinHasError = false
        }
        guard enteredPIN.count < 4 else { return }
        enteredPIN.append(digit)
        
        if enteredPIN.count == 4 {
            checkPIN()
        }
    }
    
    private func deletePINDigit() {
        if !enteredPIN.isEmpty {
            enteredPIN.removeLast()
        }
    }
    
    private func closePINCard() {
        enteredPIN = ""
        pinHasError = false
        showPINCard = false
    }
    
    private func checkPIN() {
        if verifyCompletionPIN(enteredPIN) {
            enteredPIN = ""
            pinHasError = false
            showPINCard = false
            viewModel.completeTaskAfterAuthorization()
        } else {
            enteredPIN = ""
            pinHasError = true
        }
    }
}

// MARK: - Previews

#Preview("1. Focus Session - Unchecked") {
    let sampleTask = HomeworkTask.createFromTaskCreation(
        title: "واجب الرياضيات",
        focusDurationMinutes: 10,
        breakDurationMinutes: 5,
        validityDays: 1,
        stepTitles: ["أكمل المسائل الفردية فقط", "حل سؤال ٤", "تأكد من حلك"],
        requiresCompletionPIN: false
    )!
    
    TaskSessionView(task: sampleTask)
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDevice(PreviewDevice(rawValue: "iPad Air 11-inch (M4)"))
}

#Preview("2. Break Session") {
    let sampleTask = HomeworkTask.createFromTaskCreation(
        title: "واجب الرياضيات",
        focusDurationMinutes: 10,
        breakDurationMinutes: 5,
        validityDays: 1,
        stepTitles: ["أكمل المسائل الفردية فقط", "حل سؤال ٤"],
        requiresCompletionPIN: false
    )!
    sampleTask.phase = .breakTime
    sampleTask.breakSecondsRemaining = 300
    
    return TaskSessionView(task: sampleTask)
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDevice(PreviewDevice(rawValue: "iPad Air 11-inch (M4)"))
}

#Preview("3. Single Subtask Task") {
    let sampleTask = HomeworkTask.createFromTaskCreation(
        title: "قراءة القصة",
        focusDurationMinutes: 15,
        breakDurationMinutes: 3,
        validityDays: 1,
        stepTitles: ["قراءة الفصل الأول"],
        requiresCompletionPIN: false
    )!
    
    return TaskSessionView(task: sampleTask)
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDevice(PreviewDevice(rawValue: "iPad Air 11-inch (M4)"))
}

#Preview("4. Fast 1-Min Focus & 1-Min Break Test") {
    let sampleTask = HomeworkTask.createFromTaskCreation(
        title: "اختبار دقيقة واحدة",
        focusDurationMinutes: 1,
        breakDurationMinutes: 1,
        validityDays: 1,
        stepTitles: ["أكمل المسائل الفردية فقط", "حل سؤال ٤", "تأكد من حلك"],
        requiresCompletionPIN: false
    )!
    
    return TaskSessionView(task: sampleTask)
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDevice(PreviewDevice(rawValue: "iPad Air 11-inch (M4)"))
}

#Preview("5. Task Requiring Parent PIN (PIN: 1234)") {
    let sampleTask = HomeworkTask.createFromTaskCreation(
        title: "واجب الرياضيات المعزز بـ PIN",
        focusDurationMinutes: 10,
        breakDurationMinutes: 5,
        validityDays: 1,
        stepTitles: ["أكمل السؤال الأخير"],
        requiresCompletionPIN: true
    )!
    
    return TaskSessionView(
        task: sampleTask,
        verifyCompletionPIN: { pin in pin == "1234" }
    )
    .previewInterfaceOrientation(.landscapeLeft)
    .previewDevice(PreviewDevice(rawValue: "iPad Air 11-inch (M4)"))
}
