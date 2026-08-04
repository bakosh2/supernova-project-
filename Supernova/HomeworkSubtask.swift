//
//  HomeworkSubtask.swift
//  Supernova
//

import Foundation
import SwiftData

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
