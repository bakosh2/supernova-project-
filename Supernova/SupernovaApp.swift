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
    @Environment(\.scenePhase) private var scenePhase
    @Query private var savedTasks: [HomeworkTask]
    @AppStorage("didSeedSupernovaTasks") private var didSeedTasks = false

    @State private var showSiriPinSheet = false
    @State private var showSuccessAlert = false
    @State private var alertMessage = ""

    var body: some View {
        WelcomeView()
            .task {
                seedInitialTasksIfNeeded()
                checkPendingSiriHomework()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    checkPendingSiriHomework()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: PendingSiriHomework.notificationName)) { _ in
                checkPendingSiriHomework()
            }
            .fullScreenCover(isPresented: $showSiriPinSheet) {
                ParentPinFlowView(onSuccess: {
                    showSiriPinSheet = false
                    savePendingSiriHomework()
                })
            }
            .alert("تأكيد الواجب", isPresented: $showSuccessAlert) {
                Button("حسناً", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
    }

    private func checkPendingSiriHomework() {
        guard !showSiriPinSheet else { return }
        if PendingSiriHomework.load() != nil {
            showSiriPinSheet = true
        }
    }

    private func savePendingSiriHomework() {
        guard let homework = PendingSiriHomework.load() else { return }

        let stepTitles = homework.subtasks.map(\.title)

        if let task = HomeworkTask.createFromTaskCreation(
            title: homework.title,
            focusDurationMinutes: homework.focusDuration,
            breakDurationMinutes: homework.breakDuration,
            stepTitles: stepTitles,
            requiresCompletionPIN: homework.requiresCode
        ) {
            modelContext.insert(task)
            do {
                try modelContext.save()
                PendingSiriHomework.clear()
                alertMessage = "تمت إضافة المهمة بنجاح ✨"
                showSuccessAlert = true
            } catch {
                modelContext.rollback()
                alertMessage = "فشل حفظ المهمة، يرجى المحاولة مرة أخرى."
                showSuccessAlert = true
            }
        }
    }

    private func seedInitialTasksIfNeeded() {
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
