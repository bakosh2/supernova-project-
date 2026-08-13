//
//  SupernovaApp.swift
//  Supernova
//

import SwiftUI
import SwiftData

@main
struct SupernovaApp: App {
    var body: some Scene {
        WindowGroup {
            SupernovaRootView()
        }
        .modelContainer(for: [HomeworkTask.self, HomeworkSubtask.self])
    }
}

/// Creates the same initial task data once, so parent and child dashboards
/// always read from one persistent SwiftData source.
private struct SupernovaRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedTasks: [HomeworkTask]
    @AppStorage("didSeedSupernovaTasks") private var didSeedTasks = false

    var body: some View {
        WelcomeView()
            .task {
                guard !didSeedTasks, savedTasks.isEmpty else { return }
                let samples = [
                    ("حل واجب الرياضيات", 10, 5, ["أكمل المسائل الفردية فقط", "حل سؤال ٤", "تأكد من حلك"]),
                    ("قراءة صفحتين من كتابي المفضّل", 15, 3, ["قراءة الفصل الأول"]),
                    ("حل واجب العلوم", 20, 5, ["رسم الخلية النباتية", "الإجابة عن السؤال الأخير"])
                ]
                for sample in samples {
                    if let task = HomeworkTask.createFromTaskCreation(
                        title: sample.0,
                        focusDurationMinutes: sample.1,
                        breakDurationMinutes: sample.2,
                        stepTitles: sample.3,
                        requiresCompletionPIN: false
                    ) {
                        modelContext.insert(task)
                    }
                }
                try? modelContext.save()
                didSeedTasks = true
            }
    }
}
