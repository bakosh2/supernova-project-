import SwiftUI

// MARK: - هيكل بيانات الخطوة (Step Model)
struct TaskStep: Identifiable {
    let id = UUID()
    var text: String
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
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 40)
                            .background(buttonTeal)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Button(action: {}) {
                        Text("؟")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 45, height: 45)
                            .background(buttonTeal)
                            .clipShape(Circle())
                    }
                    
                    
                }
                .padding(.horizontal, 35)
                .padding(.top, 25)
                
                Spacer()
            }
            
            // المحتوى الرئيسي (الكارت الداخلي لحفظ المهمة)
            VStack(spacing: 24) {
                    
                    // 1. عنوان المهمة
                    VStack(alignment: .leading, spacing: 10) {
                        Text("عنوان المهمة")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("", text: $taskTitle, prompt: Text("مثال : واجب الرياضيات").foregroundColor(.gray))
                            .multilineTextAlignment(.leading)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(neonBlue, lineWidth: 2)
                            )
                            .foregroundColor(.white)
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
                                                .stroke(neonBlue.opacity(0.4), lineWidth: 1)
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
                            
                            TextField("", text: $newStepText, prompt: Text("اكتب الخطوة هنا ثم اضغط إضافه...").foregroundColor(.gray))
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.white)
                                .font(.body)
                                .onSubmit {
                                    addNewStep()
                                }
                        }
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(neonBlue, lineWidth: 2)
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
                            .background(buttonTeal)
                            .cornerRadius(25)
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
            
            Spacer()
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
}

// المعاينة الخاصة بـ iPad
#Preview(traits: .landscapeLeft) {
    TaskCreationView()
}
