import AppIntents

struct HomeworkAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddHomeworkIntent(),
            phrases: [
                "أضف واجب في \(.applicationName)",
                "أضيفي واجب في \(.applicationName)"
            ],
            shortTitle: "إضافة واجب",
            systemImageName: "plus.circle.fill"
        )
    }
}
