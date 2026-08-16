import AppIntents
import Foundation

// MARK: - Siri Add Homework Intent

struct AddHomeworkIntent: AppIntent {
    static var title: LocalizedStringResource = "إضافة واجب"
    static var description = IntentDescription("إضافة واجب مدرسي جديد عبر الذكاء الاصطناعي")

    static let supportedModes: IntentModes = [
        .background,
        .foreground(.dynamic)
    ]

    @Parameter(title: "وصف الواجب", requestValueDialog: IntentDialog("ما هو الواجب؟"))
    var homeworkDescription: String

    @Parameter(title: "التغيير المطلوب")
    var requestedChange: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let service = SiriHomeworkService()

        print("[SIRI] current mode at start:", systemContext.currentMode)

        // 1. Initial Generation (isolated network catch)
        var currentHomework: GeneratedHomework
        do {
            currentHomework = try await service.generateHomework(description: homeworkDescription)
            print("[SIRI] current mode after generation:", systemContext.currentMode)
        } catch {
            print("[SIRI] generation network error:", error)
            return .result(dialog: "تعذر الاتصال بخدمة Supernova. تأكد من تشغيل الخادم وحاول مجدداً.")
        }

        // 2. Revision loop (max 3 turns)
        let addOption = IntentChoiceOption(title: "إضافة")
        let changeOption = IntentChoiceOption(title: "تغيير")
        let cancelOption = IntentChoiceOption(title: "إلغاء")

        var turnCount = 0

        while turnCount < 3 {
            turnCount += 1

            let promptDialog = choiceDialog(for: currentHomework)

            print("[SIRI] current mode before requesting choice:", systemContext.currentMode)

            let selectedChoice: IntentChoiceOption

            print("🟣 [SIRI] presenting homework choice, turn:", turnCount)
            print("🟣 [SIRI] title:", currentHomework.title)

            do {
                selectedChoice = try await requestChoice(
                    between: [
                        addOption,
                        changeOption,
                        cancelOption
                    ],
                    dialog: promptDialog
                )

                print("🟣 [SIRI] choice returned")
                
            } catch {
                print("[SIRI] choice dialog cancelled or error:", error)
                return .result(dialog: "تم الإلغاء ولم تتم إضافة المهمة.")
            }

            if selectedChoice == addOption {
                print("[SIRI] inside add branch. Mode:", systemContext.currentMode)
                do {
                    try PendingSiriHomework.save(currentHomework)
                    print("[SIRI] pending homework saved")
                } catch {
                    print("[SIRI] pending save error:", error)
                    return .result(dialog: "حدث خطأ أثناء حفظ الواجب في التطبيق.")
                }

                print("[SIRI] canContinueInForeground:", systemContext.currentMode.canContinueInForeground)

                if systemContext.currentMode.canContinueInForeground {
                    do {
                        print("[SIRI] requesting foreground")
                        try await continueInForeground("افتح Supernova لإدخال رمز ولي الأمر", alwaysConfirm: false)
                    } catch {
                        print("[SIRI] foreground error:", error)
                    }
                }

                print("[SIRI] add handoff complete")
                return .result(dialog: "افتح التطبيق وأدخل رمز ولي الأمر لإضافة الواجب.")

            } else if selectedChoice == changeOption {
                let changeReq: String
                do {
                    changeReq = try await $requestedChange.requestValue(IntentDialog("ماذا تريد أن تغيّر؟"))
                } catch {
                    print("[SIRI] change request prompt cancelled:", error)
                    return .result(dialog: "تم الإلغاء ولم تتم إضافة المهمة.")
                }

                do {
                    currentHomework = try await service.reviseHomework(
                        description: homeworkDescription,
                        currentHomework: currentHomework,
                        change: changeReq
                    )
                } catch {
                    print("[SIRI] revision network error:", error)
                    return .result(dialog: "تعذر الاتصال بخدمة Supernova. تأكد من تشغيل الخادم وحاول مجدداً.")
                }

            } else {
                return .result(dialog: "تم الإلغاء ولم تتم إضافة المهمة.")
            }
        }

        return .result(dialog: "تم الإلغاء ولم تتم إضافة المهمة.")
    }

    private func choiceDialog(for homework: GeneratedHomework) -> IntentDialog {
        let pinText = homework.requiresCode ? "مطلوب 🔐" : "غير مطلوب 🔓"

        let steps = homework.subtasks.enumerated()
            .map { index, subtask in
                "\(index + 1). \(subtask.title)"
            }
            .joined(separator: " | ")

        return IntentDialog(
            """
            تم إعداد \(homework.title).

            التركيز: \(homework.focusDuration) دقيقة ⏱
            الاستراحة: \(homework.breakDuration) دقيقة ☕️
            رمز ولي الأمر: \(pinText)

            الخطوات:
            \(steps)

             | هل تريد إضافته، تغييره، أم إلغاءه؟
            """
        )
    }
}
