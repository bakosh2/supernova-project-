//
//  HomeworkTask.swift
//  Supernova
//

import Foundation
import SwiftData

/// SwiftData model representing a student homework task with focus/break session state.
@Model
final class HomeworkTask {
    var id: UUID
    var title: String
    //var subject: String?
    
    var focusDurationSeconds: Int
    var breakDurationSeconds: Int
    
    var validUntil: Date?
    var validityRawValue: String?
    
    var requiresCompletionPIN: Bool
    
    var currentSubtaskIndex: Int
    var sessionPhaseRawValue: String
    
    var focusSecondsRemaining: Int
    var breakSecondsRemaining: Int
    
    var totalFocusSecondsCompleted: Int
    
    var isCompleted: Bool
    var completedAt: Date?
    var lastSavedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \HomeworkSubtask.task)
    var subtasks: [HomeworkSubtask] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        //subject: String? = nil,
        focusDurationSeconds: Int,
        breakDurationSeconds: Int,
        validUntil: Date? = nil,
        validityRawValue: String? = nil,
        requiresCompletionPIN: Bool = false,
        currentSubtaskIndex: Int = 0,
        sessionPhaseRawValue: String = TaskSessionPhase.notStarted.rawValue,
        focusSecondsRemaining: Int? = nil,
        breakSecondsRemaining: Int? = nil,
        totalFocusSecondsCompleted: Int = 0,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        lastSavedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        //self.subject = subject
        self.focusDurationSeconds = focusDurationSeconds
        self.breakDurationSeconds = breakDurationSeconds
        self.validUntil = validUntil
        self.validityRawValue = validityRawValue
        self.requiresCompletionPIN = requiresCompletionPIN
        self.currentSubtaskIndex = currentSubtaskIndex
        self.sessionPhaseRawValue = sessionPhaseRawValue
        self.focusSecondsRemaining = focusSecondsRemaining ?? focusDurationSeconds
        self.breakSecondsRemaining = breakSecondsRemaining ?? breakDurationSeconds
        self.totalFocusSecondsCompleted = totalFocusSecondsCompleted
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.lastSavedAt = lastSavedAt
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
    
    /// Computed property deriving pause status from phase (avoids duplicated boolean state)
    var isFocusPaused: Bool {
        phase == .focusPaused
    }
    
    /// Returns subtasks sorted by orderIndex
    var sortedSubtasks: [HomeworkSubtask] {
        subtasks.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    /// Canonical helper method to create a HomeworkTask from TaskCreationView values.
    static func createFromTaskCreation(
        title: String,
        subject: String? = nil,
        focusDurationMinutes: Int,
        breakDurationMinutes: Int,
        validityDays: Int,
        validityRawValue: String? = nil,
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
        let validUntilDate = Calendar.current.date(byAdding: .day, value: validityDays, to: .now)
        
        let task = HomeworkTask(
            title: trimmedTitle,
            //subject: subject,
            focusDurationSeconds: focusSecs,
            breakDurationSeconds: breakSecs,
            validUntil: validUntilDate,
            validityRawValue: validityRawValue,
            requiresCompletionPIN: requiresCompletionPIN,
            currentSubtaskIndex: 0,
            sessionPhaseRawValue: TaskSessionPhase.notStarted.rawValue,
            focusSecondsRemaining: focusSecs,
            breakSecondsRemaining: breakSecs,
            totalFocusSecondsCompleted: 0,
            isCompleted: false,
            completedAt: nil,
            lastSavedAt: .now
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
