//
//  TaskSessionView.swift
//  Supernova
//

import SwiftUI
import SwiftData

// MARK: - Navigation Capsule Button
struct SessionNavigationButton: View {
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
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Subtask Completion Check Control
struct SubtaskCompletionControl: View {
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.purpleCheckbox)
                    .clipShape(Circle())
            } else {
                Circle()
                    .stroke(Color.purpleCheckbox, lineWidth: 2.5)
                    .frame(width: 36, height: 36)
            }
        }
    }
}

// MARK: - Disconnected Subtask Progress Segments (RTL Visual Progression)
struct SubtaskProgressSegments: View {
    let subtasks: [HomeworkSubtask]
    let currentIndex: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(subtasks.indices.reversed()), id: \.self) { index in
                let isCurrent = (index == currentIndex)
                let isDone = (index < subtasks.count && subtasks[index].isCompleted)
                let color: Color = isCurrent ? Color.purpleCheckbox : (isDone ? Color.purpleCheckbox.opacity(0.75) : Color.gray.opacity(0.22))
                
                Capsule()
                    .fill(color)
                    .frame(height: 6)
            }
        }
    }
}

// MARK: - Previous Subtask Button
struct PreviousSubtaskButton: View {
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isDisabled ? Color.white.opacity(0.6) : .white)
                .frame(width: 36, height: 36)
                .background(isDisabled ? Color(hex: "#D1D1D4") : Color.purpleCheckbox)
                .clipShape(Circle())
        }
        .disabled(isDisabled)
    }
}

// MARK: - Focus Task Card (Left Side)
struct FocusTaskCard: View {
    let taskTitle: String
    let subtaskTitle: String
    let isSubtaskCompleted: Bool
    let subtasks: [HomeworkSubtask]
    let currentIndex: Int
    let isFirstSubtask: Bool
    let actionButtonTitle: String
    let canAdvance: Bool
    
    let onToggleCheck: () -> Void
    let onPreviousSubtask: () -> Void
    let onPrimaryAction: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 20) {
            // Task Title
            Text(taskTitle)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#1E264F"))
                .environment(\.layoutDirection, .rightToLeft)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            Spacer()
            
            // Current Subtask Row (Arabic text aligned right, check control on the right)
            HStack(spacing: 16) {
                Spacer()
                
                Text(subtaskTitle)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "#1E264F"))
                    .multilineTextAlignment(.trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                
                SubtaskCompletionControl(
                    isCompleted: isSubtaskCompleted,
                    onTap: onToggleCheck
                )
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            // Progress Segments (Left) & Previous Button (Right) in explicit LTR container
            HStack(spacing: 12) {
                SubtaskProgressSegments(
                    subtasks: subtasks,
                    currentIndex: currentIndex
                )
                
                PreviousSubtaskButton(
                    isDisabled: isFirstSubtask,
                    action: onPreviousSubtask
                )
            }
            .environment(\.layoutDirection, .leftToRight)
            .padding(.bottom, 12)
            
            // Primary Action Button ("المهمة التالية" / "إنهاء المهمة")
            Button(action: onPrimaryAction) {
                Text(actionButtonTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(canAdvance ? .white : Color.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(canAdvance ? Color.tealPrimary : Color.disabledButtonGray)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(
                        color: canAdvance ? Color.tealPrimary.opacity(0.4) : Color.clear,
                        radius: canAdvance ? 8 : 0,
                        x: 0,
                        y: canAdvance ? 3 : 0
                    )
            }
            .disabled(!canAdvance)
        }
        .padding(32)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Session Timer Ring Component
struct SessionTimerRing: View {
    let title: String
    let formattedTime: String
    let progress: Double
    let isBreak: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .environment(\.layoutDirection, .rightToLeft)
            
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.rowBackgroundDark.opacity(0.8), lineWidth: 12)
                
                // Progress Arc
                Circle()
                    .trim(from: 0, to: max(0, min(1, progress)))
                    .stroke(
                        isBreak ? Color.tealPrimary : Color.purpleCheckbox,
                        lineWidth: 12
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.8), value: progress)
                
                // MM:SS Time Text
                Text(formattedTime)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 280, height: 280)
        }
    }
}

// MARK: - Focus Pause / Resume Button
struct FocusPauseButton: View {
    let isPaused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 18, weight: .bold))
                
                Text(isPaused ? "متابعة" : "إيقاف مؤقت")
                    .font(.system(size: 22, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(Color.tealPrimary)
            .clipShape(Capsule())
            .shadow(color: Color.tealPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Break Encouragement Card (Left Side in Break Phase)
struct BreakEncouragementCard: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("أحسنت!")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(Color(hex: "#1E264F"))
                .environment(\.layoutDirection, .rightToLeft)
            
            // Stretching star illustration asset
            Image("stretching_star")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 400)
            
            Text("حان الوقت ليرتاح عقلك قليلًا.")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(Color(hex: "#1E264F"))
                .multilineTextAlignment(.center)
                .lineSpacing(12)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Skip Break Button
struct SkipBreakButton: View {
    let action: () -> Void
    
    var body: some View {
        Button("تخطي وقت الراحة", action: action)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(Color.tealPrimary)
            .clipShape(Capsule())
            .shadow(color: Color.tealPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Parent PIN Card Modal Component
struct ParentPINCard: View {
    @Binding var enteredPIN: String
    @Binding var pinHasError: Bool
    let onClose: () -> Void
    let onDigitPressed: (String) -> Void
    let onDeletePressed: () -> Void
    
    private let rows = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"]
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header Bar: Title and Upper-Right Teal Close Button
            ZStack(alignment: .topTrailing) {
                // Title & Subtitle
                VStack(spacing: 8) {
                    Text("رمز الوالدين")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .environment(\.layoutDirection, .rightToLeft)
                    
                    Text("أدخل رمز PIN المكوّن من ٤ أرقام للتحقق من الهوية")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: "#B39DDB"))
                        .environment(\.layoutDirection, .rightToLeft)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                
                // Upper-Right Close Button
                Button(action: onClose) {
                    ZStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.tealPrimary, Color(hex: "#43A8A0")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 110, height: 46)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Four White PIN Display Boxes
            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(hex: "#F5F6FC"))
                            .frame(width: 85, height: 95)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(
                                        pinHasError ? Color.red : Color.white.opacity(0.4),
                                        lineWidth: pinHasError ? 3 : 1
                                    )
                            )
                        
                        if index < enteredPIN.count {
                            Circle()
                                .fill(Color(hex: "#1E264F"))
                                .frame(width: 22, height: 22)
                        }
                    }
                }
            }
            .padding(.vertical, 6)
            
            // Keypad Grid (1-9, 0, Delete)
            VStack(spacing: 14) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 24) {
                        ForEach(row, id: \.self) { digit in
                            Button(action: { onDigitPressed(digit) }) {
                                Text(digit)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 78, height: 78)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                
                // Bottom Keypad Row: Empty Spacer, 0, Delete
                HStack(spacing: 24) {
                    Spacer()
                        .frame(width: 78, height: 78)
                    
                    Button(action: { onDigitPressed("0") }) {
                        Text("0")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 78, height: 78)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    Button(action: onDeletePressed) {
                        Image(systemName: "delete.left")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 78, height: 78)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .frame(width: 660)
        .background(Color(hex: "#1B224B"))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.tealPrimary.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 12)
    }
}

// MARK: - Main TaskSessionView Screen

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
