//
//  SupernovaApp.swift
//  Supernova
//

import SwiftUI

@main
struct SupernovaApp: App {
    let sampleTask = HomeworkTask.createFromTaskCreation(
        title: "واجب الرياضيات",
        focusDurationMinutes: 10,
        breakDurationMinutes: 5,
        validityDays: 1,
        stepTitles: ["أكمل المسائل الفردية فقط", "حل سؤال ٤", "تأكد من حلك"],
        requiresCompletionPIN: false
    )!
    
    var body: some Scene {
        WindowGroup {
            TaskFlowView(
                task: sampleTask,
                onExitToMain: {}
            )
        }
    }
}
