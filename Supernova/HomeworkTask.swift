//
//  HomeworkTask.swift
//  Supernova
//

import Foundation
import SwiftData

/// Represents the current phase of a task session.
enum TaskSessionPhase: String, Codable {
    case notStarted
    case focus
    case focusPaused
    case breakTime
    case completed
}

/// SwiftData model representing a subtask step within a HomeworkTask.
@Model
final class HomeworkSubtask {
    var id: UUID
    var title: String
    var orderIndex: Int
    var isCompleted: Bool
    
    var task: HomeworkTask?
    
    init(id: UUID = UUID(), title: String, orderIndex: Int, isCompleted: Bool = false, task: HomeworkTask? = nil) {
        self.id = id
        self.title = title
        self.orderIndex = orderIndex
        self.isCompleted = isCompleted
        self.task = task
    }
}

/// SwiftData model representing a student homework task with focus/break session state.
@Model
final class HomeworkTask {
    var id: UUID
    var title: String
    
    var focusDurationSeconds: Int
    var breakDurationSeconds: Int
    
    var requiresCompletionPIN: Bool
    
    var currentSubtaskIndex: Int
    var sessionPhaseRawValue: String
    
    var focusSecondsRemaining: Int
    var breakSecondsRemaining: Int
    
    var totalFocusSecondsCompleted: Int
    
    var isCompleted: Bool
    
    var isRewardCollected: Bool = false
    var createdAt: Date = Date()
    
    @Relationship(deleteRule: .cascade, inverse: \HomeworkSubtask.task)
    var subtasks: [HomeworkSubtask] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        focusDurationSeconds: Int,
        breakDurationSeconds: Int,
        requiresCompletionPIN: Bool = false,
        currentSubtaskIndex: Int = 0,
        sessionPhaseRawValue: String = TaskSessionPhase.notStarted.rawValue,
        focusSecondsRemaining: Int? = nil,
        breakSecondsRemaining: Int? = nil,
        totalFocusSecondsCompleted: Int = 0,
        isCompleted: Bool = false,
        isRewardCollected: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.focusDurationSeconds = focusDurationSeconds
        self.breakDurationSeconds = breakDurationSeconds
        self.requiresCompletionPIN = requiresCompletionPIN
        self.currentSubtaskIndex = currentSubtaskIndex
        self.sessionPhaseRawValue = sessionPhaseRawValue
        self.focusSecondsRemaining = focusSecondsRemaining ?? focusDurationSeconds
        self.breakSecondsRemaining = breakSecondsRemaining ?? breakDurationSeconds
        self.totalFocusSecondsCompleted = totalFocusSecondsCompleted
        self.isCompleted = isCompleted
        self.isRewardCollected = isRewardCollected
        self.createdAt = createdAt
    }
    
    /// Computed property for type-safe TaskSessionPhase
    var phase: TaskSessionPhase {
        get {
            TaskSessionPhase(rawValue: sessionPhaseRawValue) ?? .notStarted
        }
        set {
            sessionPhaseRawValue = newValue.rawValue
        }
    }
    
    /// Computed property deriving pause status from phase
    var isFocusPaused: Bool {
        phase == .focusPaused
    }
    
    /// Returns subtasks sorted by orderIndex
    var sortedSubtasks: [HomeworkSubtask] {
        subtasks.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    /// Safe computed property for task subtask completion progress (0.0 to 1.0)
    var progress: Double {
        let steps = sortedSubtasks
        guard !steps.isEmpty else {
            return isCompleted ? 1.0 : 0.0
        }
        let completedCount = steps.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(steps.count)
    }
    
    /// Canonical helper method to create a HomeworkTask from TaskCreationView values.
    static func createFromTaskCreation(
        title: String,
        subject: String? = nil,
        focusDurationMinutes: Int,
        breakDurationMinutes: Int,
        stepTitles: [String],
        requiresCompletionPIN: Bool
    ) -> HomeworkTask? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }
        
        let cleanStepTitles = stepTitles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !cleanStepTitles.isEmpty else { return nil }
        
        guard focusDurationMinutes > 0, breakDurationMinutes > 0 else { return nil }
        
        let focusSecs = focusDurationMinutes * 60
        let breakSecs = breakDurationMinutes * 60
        
        let task = HomeworkTask(
            title: trimmedTitle,
            focusDurationSeconds: focusSecs,
            breakDurationSeconds: breakSecs,
            requiresCompletionPIN: requiresCompletionPIN,
            currentSubtaskIndex: 0,
            sessionPhaseRawValue: TaskSessionPhase.notStarted.rawValue,
            focusSecondsRemaining: focusSecs,
            breakSecondsRemaining: breakSecs,
            totalFocusSecondsCompleted: 0,
            isCompleted: false,
            isRewardCollected: false,
            createdAt: .now
        )
        
        let createdSubtasks = cleanStepTitles.enumerated().map { index, stepTitle in
            HomeworkSubtask(
                title: stepTitle,
                orderIndex: index,
                isCompleted: false,
                task: task
            )
        }
        
        task.subtasks = createdSubtasks
        return task
    }
}
