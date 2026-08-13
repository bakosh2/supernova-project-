import SwiftUI
import UIKit

// MARK: - هيكل بيانات الخطوة (Step Model)
struct TaskStep: Identifiable {
    let id = UUID()
    var text: String
}

/// حقل UIKit يفرض الاتجاه العربي من اليمين؛ TextField في SwiftUI قد يعكس
/// مكان النص الإرشادي عند استخدام اتجاه الواجهة العام.
struct ArabicRightTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    var onSubmit: (() -> Void)? = nil

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.textColor = .white
        field.font = UIFont.preferredFont(forTextStyle: .body)
        field.textAlignment = .right
        field.semanticContentAttribute = .forceRightToLeft
        field.returnKeyType = .done
        field.autocorrectionType = .no
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        paragraph.baseWritingDirection = .rightToLeft
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.systemGray,
                .paragraphStyle: paragraph
            ]
        )
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        if field.text != text { field.text = text }
        field.textAlignment = .right
        field.semanticContentAttribute = .forceRightToLeft
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        let parent: ArabicRightTextField

        init(parent: ArabicRightTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ field: UITextField) {
            parent.text = field.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit?()
            textField.resignFirstResponder()
            return true
        }
    }
}

// MARK: - Enums للخيارات المنسدلة

enum BreakDuration: Int, CaseIterable, Identifiable {
    case one = 1
    case two = 2
    case five = 5
    case ten = 10
    
    var id: Int { rawValue }
    
    var label: String {
        switch self {
        case .one: return "دقيقة واحدة"
        case .two: return "دقيقتين"
        default: return "\(rawValue) دقائق"
        }
    }
}

enum FocusDuration: Int, CaseIterable, Identifiable {
    case ten = 10
    case fifteen = 15
    case twenty = 20
    case twentyFive = 25
    case thirty = 30
    case fortyFive = 45
    case sixty = 60
    
    var id: Int { rawValue }
    
    var label: String { "\(rawValue) د" }
}

// MARK: - View الرئيسي

struct TaskCreationView: View {
    // MARK: - ربط البيانات مع TasksListView
    // دالة تُستدعى عند الضغط على "حفظ المهمة" وتُرجع المهمة الجديدة للشاشة السابقة
    var onSave: (TaskItem) -> Void = { _ in }
    
    // للتحكم بإغلاق الشاشة تلقائيًا بعد الحفظ (يدعم الرجوع سواء كانت الشاشة sheet أو navigation push)
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Variables
    @State private var taskTitle: String = ""
    
    @State private var focusDuration: FocusDuration = .twenty
    @State private var breakDuration: BreakDuration = .two
    
    // متغير لنص الخطوة الجديدة التي يكتبها المستخدم
    @State private var newStepText: String = ""
    
    // قائمة الخطوات المضافة
    @State private var steps: [TaskStep] = []
    
    @State private var requirePin: Bool = false
    
    // الألوان
    let backgroundColor = Color(red: 0.08, green: 0.10, blue: 0.22)
    let cardBackgroundColor = Color(red: 0.25, green: 0.24, blue: 0.45)
    let buttonTeal = Color(red: 0.20, green: 0.68, blue: 0.58)
    let neonBlue = Color(red: 0.20, green: 0.60, blue: 0.90)
    
    // MARK: - الحسابات التلقائية للملخص الجانبي
    private var totalFocusTime: Int {
        focusDuration.rawValue
    }
    
    private var totalBreaksTime: Int {
        let breaksCount = max(steps.count - 1, 0)
        return breaksCount * breakDuration.rawValue
    }
    
    private var totalSessionTime: Int {
        totalFocusTime + totalBreaksTime
    }
    
    // وظيفة إضافة الخطوة الجديدة
    private func addNewStep() {
        let trimmedText = newStepText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            steps.append(TaskStep(text: trimmedText))
            newStepText = "" // تفريغ حقل النص بعد الإضافة
        }
    }
    
    // MARK: - وظيفة حفظ المهمة وإرسالها لشاشة القائمة
    private func saveTask() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let newTask = TaskItem(
            title: trimmedTitle,
            focusMinutes: focusDuration.rawValue,
            breakMinutes: breakDuration.rawValue,
            steps: steps.map { $0.text },
            requirePin: requirePin
        )
        onSave(newTask)   // إرسال المهمة الجديدة بكل تفاصيلها لـ TasksListView
        dismiss()          // إغلاق الشاشة والرجوع للقائمة
    }
    
    var body: some View {
        ZStack {
            // خلفية الشاشة الأساسية - نفس خلفية قائمة جميع المهام (parent-dashboard)
            Image("parent-dashboard")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            // زر المساعدة والرجوع في الأعلى
            VStack {
                HStack {
                    
                    BackCapsuleButton { dismiss() }
                    Spacer()
                }
                .padding(.horizontal, AppHeaderLayout.horizontal)
                .padding(.top, AppHeaderLayout.top)
                .environment(\.layoutDirection, .leftToRight)
                
                Spacer()
            }
            
            // المحتوى الرئيسي (الكارت الداخلي لحفظ المهمة)
            VStack(spacing: 24) {
                    
                    // 1. عنوان المهمة
                    VStack(alignment: .trailing, spacing: 10) {
                        Text("عنوان المهمة")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .environment(\.layoutDirection, .leftToRight)
                        
                        ArabicRightTextField(
                            text: $taskTitle,
                            placeholder: "مثال: واجب الرياضيات"
                        )
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .padding(.horizontal, 18)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.tealPrimary, lineWidth: 2)
                            )
                    }
                    
                    // 2. مدة التركيز والراحة
                    HStack(alignment: .top, spacing: 30) {
                        
                        // مدة الإستراحة
                        VStack(spacing: 8) {
                            Text("مدة الإستراحة بين الخطوات")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Menu {
                                ForEach(BreakDuration.allCases) { option in
                                    Button(option.label) {
                                        breakDuration = option
                                    }
                                }
                            } label: {
                                dropDownButtonLabel(text: breakDuration.label)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // مدة التركيز
                        VStack(spacing: 8) {
                            Text("مدة التركيز")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Menu {
                                ForEach(FocusDuration.allCases) { option in
                                    Button(option.label) {
                                        focusDuration = option
                                    }
                                }
                            } label: {
                                dropDownButtonLabel(text: focusDuration.label)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // 3. قسم إضافة وعرض الخطوات
                    VStack(alignment: .leading, spacing: 12) {
                        Text("الخطوات")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        // أولاً: عرض قائمة الخطوات المضافة (قابلة للتمرير بدل ما تكبّر الكارد)
                        if !steps.isEmpty {
                            ScrollView(showsIndicators: true) {
                                VStack(spacing: 10) {
                                    ForEach(steps) { step in
                                        HStack {
                                            Button(action: {
                                                if let index = steps.firstIndex(where: { $0.id == step.id }) {
                                                    steps.remove(at: index)
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle")
                                                    .foregroundColor(neonBlue)
                                                    .font(.title3)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(step.text)
                                                .foregroundColor(.white)
                                                .font(.body)
                                                .multilineTextAlignment(.trailing)
                                        }
                                        .padding()
                                        .background(Color.black.opacity(0.2))
                                        .cornerRadius(15)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(Color.tealPrimary.opacity(0.65), lineWidth: 1.5)
                                        )
                                    }
                                }
                            }
                            .frame(maxHeight: 240) // ارتفاع أكبر - يوري حوالي 3 خطوات واضحة قبل ما يبدأ التمرير
                        }
                        
                        // ثانياً: حقل إدخال الخطوة الجديدة (سيكون دائماً في الأسفل، وثابت المكان)
                        HStack {
                            Button(action: addNewStep) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(buttonTeal)
                                    .font(.title2)
                            }
                            
                            ArabicRightTextField(
                                text: $newStepText,
                                placeholder: "اكتب الخطوة هنا ثم اضغط إضافة...",
                                onSubmit: addNewStep
                            )
                                .frame(maxWidth: .infinity)
                                .frame(height: 28)
                        }
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.tealPrimary, lineWidth: 2)
                        )
                    }
                    
                    // 4. خيار الرمز للطفل
                    HStack {
                        Button(action: {
                            requirePin.toggle()
                        }) {
                            Image(systemName: requirePin ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(requirePin ? buttonTeal : .gray)
                                .font(.title3)
                        }

                        Text("هل ترغب بإدخال الرمز قبل أن ينهي طفلك مهمته؟")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)

                        Spacer()
                    }
                    .padding(.top, 5)
                    
                    // 5. زر حفظ المهمة
                    Button(action: saveTask) {
                        Text("حفظ المهمـة")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .supernovaGlassCapsule(tint: buttonTeal)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 5)
                }
                .padding(35)
                .frame(width: 650, height: 600)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "4454A9").opacity(0.8),
                            Color(hex: "1E2651").opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(35)
                .overlay(
                    RoundedRectangle(cornerRadius: 35)
                        .stroke(Color.tealPrimary.opacity(0.65), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    // MARK: - تصميم زر القائمة المنسدلة الأنيق
    private func dropDownButtonLabel(text: String) -> some View {
        HStack {
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundColor(.gray)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.tealPrimary.opacity(0.78), lineWidth: 1.5)
        )
        // Physical right alignment for Arabic text inside the field.
        .environment(\.layoutDirection, .leftToRight)
    }
}

// المعاينة الخاصة بـ iPad
#Preview(traits: .landscapeLeft) {
    TaskCreationView()
}
