//
//  TaskSessionPhase.swift
//  Supernova
//

import Foundation

/// Represents the current phase of a task session.
enum TaskSessionPhase: String, Codable {
    case notStarted
    case focus
    case focusPaused
    case breakTime
    case completed
}
