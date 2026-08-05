//
//  TaskSessionViewModel.swift
//  Supernova
//

import SwiftUI
import Combine
import SwiftData

/// Student-friendly ViewModel controlling focus/break task sessions and single timer logic.
@MainActor
final class TaskSessionViewModel: ObservableObject {
    let task: HomeworkTask
    private var modelContext: ModelContext?
    
    @Published var phase: TaskSessionPhase
    @Published var currentSubtaskIndex: Int
    @Published var focusSecondsRemaining: Int
    @Published var breakSecondsRemaining: Int
    
    private var timer: Timer?
    private var secondsSinceLastSave: Int = 0
    
    init(task: HomeworkTask, modelContext: ModelContext? = nil) {
        self.task = task
        self.modelContext = modelContext
        
        self.phase = task.phase
        self.currentSubtaskIndex = task.currentSubtaskIndex
        self.focusSecondsRemaining = task.focusSecondsRemaining
        self.breakSecondsRemaining = task.breakSecondsRemaining
    }
    
    /// Set or update the SwiftData ModelContext for persistence
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// Returns sorted subtasks from the task
    var sortedSubtasks: [HomeworkSubtask] {
        task.sortedSubtasks
    }
    
    /// Returns currently active subtask
    var currentSubtask: HomeworkSubtask? {
        if currentSubtaskIndex >= 0 && currentSubtaskIndex < sortedSubtasks.count {
            return sortedSubtasks[currentSubtaskIndex]
        }
        return nil
    }
    
    var isFirstSubtask: Bool {
        currentSubtaskIndex == 0
    }
    
    var isLastSubtask: Bool {
        currentSubtaskIndex >= (sortedSubtasks.count - 1)
    }
    
    var isCurrentSubtaskCompleted: Bool {
        currentSubtask?.isCompleted ?? false
    }
    
    var canAdvance: Bool {
        isCurrentSubtaskCompleted
    }
    
    var primaryButtonTitle: String {
        isLastSubtask ? "إنهاء المهمة" : "المهمة التالية"
    }
    
    var isFocusPaused: Bool {
        phase == .focusPaused
    }
    
    /// Formatted time MM:SS for current active timer (Focus or Break)
    var formattedTime: String {
        let totalSeconds = (phase == .breakTime) ? breakSecondsRemaining : focusSecondsRemaining
        let minutes = max(0, totalSeconds) / 60
        let seconds = max(0, totalSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Timer progress fraction from 0.0 to 1.0
    var progress: Double {
        if phase == .breakTime {
            return task.breakDurationSeconds > 0 ? Double(breakSecondsRemaining) / Double(task.breakDurationSeconds) : 1.0
        } else {
            return task.focusDurationSeconds > 0 ? Double(focusSecondsRemaining) / Double(task.focusDurationSeconds) : 1.0
        }
    }
    
    // MARK: - Session Lifecycle & Timer Management
    
    /// Initializes or resumes session on view appear
    func startOrResumeSession() {
        if task.phase == .notStarted {
            // First Entry: reset all initial values
            currentSubtaskIndex = 0
            focusSecondsRemaining = task.focusDurationSeconds
            breakSecondsRemaining = task.breakDurationSeconds
            phase = .focus
            
            task.currentSubtaskIndex = 0
            task.focusSecondsRemaining = task.focusDurationSeconds
            task.breakSecondsRemaining = task.breakDurationSeconds
            task.phase = .focus
            saveContext()
            startTimer()
        } else if task.phase == .focus {
            // Resume Focus: restore as focusPaused so child presses "متابعة"
            phase = .focusPaused
            task.phase = .focusPaused
            saveContext()
        } else if task.phase == .breakTime {
            // Resume Break: restore break screen and start break countdown
            phase = .breakTime
            startTimer()
        }
    }
    
    /// Starts single 1-second countdown timer interval
    private func startTimer() {
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.handleTimerTick()
            }
        }
    }
    
    /// Stops and invalidates active timer
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Handles 1-second tick logic
    private func handleTimerTick() {
        if phase == .focus {
            if focusSecondsRemaining > 0 {
                focusSecondsRemaining -= 1
                task.focusSecondsRemaining = focusSecondsRemaining
                task.totalFocusSecondsCompleted += 1
                secondsSinceLastSave += 1
                
                if secondsSinceLastSave >= 10 {
                    saveContext()
                    secondsSinceLastSave = 0
                }
            } else {
                // Focus time completed -> transition to Break
                phase = .breakTime
                task.phase = .breakTime
                breakSecondsRemaining = task.breakDurationSeconds
                task.breakSecondsRemaining = breakSecondsRemaining
                saveContext()
            }
        } else if phase == .breakTime {
            if breakSecondsRemaining > 0 {
                breakSecondsRemaining -= 1
                task.breakSecondsRemaining = breakSecondsRemaining
                secondsSinceLastSave += 1
                
                if secondsSinceLastSave >= 10 {
                    saveContext()
                    secondsSinceLastSave = 0
                }
            } else {
                // Break time completed -> transition back to Focus
                phase = .focus
                task.phase = .focus
                focusSecondsRemaining = task.focusDurationSeconds
                task.focusSecondsRemaining = focusSecondsRemaining
                saveContext()
            }
        }
    }
    
    // MARK: - Actions
    
    func toggleFocusPause() {
        if phase == .focus {
            stopTimer()
            phase = .focusPaused
            task.phase = .focusPaused
            saveContext()
        } else if phase == .focusPaused {
            phase = .focus
            task.phase = .focus
            saveContext()
            startTimer()
        }
    }
    
    func toggleCurrentSubtaskCompletion() {
        if let subtask = currentSubtask {
            subtask.isCompleted.toggle()
            saveContext()
        }
    }
    
    func moveToPreviousSubtask() {
        if currentSubtaskIndex > 0 {
            currentSubtaskIndex -= 1
            task.currentSubtaskIndex = currentSubtaskIndex
            saveContext()
        }
    }
    
    func moveToNextSubtask() {
        if isCurrentSubtaskCompleted && !isLastSubtask {
            currentSubtaskIndex += 1
            task.currentSubtaskIndex = currentSubtaskIndex
            saveContext()
        }
    }
    
    func skipBreak() {
        stopTimer()
        phase = .focus
        task.phase = .focus
        focusSecondsRemaining = task.focusDurationSeconds
        task.focusSecondsRemaining = focusSecondsRemaining
        saveContext()
        startTimer()
    }
    
    func finishTask() {
        stopTimer()
        phase = .completed
        task.phase = .completed
        task.isCompleted = true
        task.completedAt = .now
        saveContext()
    }
    
    func leaveAndSave() {
        stopTimer()
        saveContext()
    }
    
    func saveContext() {
        task.lastSavedAt = .now
        if let modelContext = modelContext {
            try? modelContext.save()
        }
    }
}
