//
//  TasksListView.swift
//  app1
//
//  Created by alanoud on 21/02/1448 AH.
//

import SwiftUI

// MARK: - View قائمة المهام الرئيسي

struct TasksListView: View {
    // قائمة مهام تجريبية للظهور بالواجهة
    @State private var tasks: [TaskItem] = [
        TaskItem(title: "حل واجب الرياضيات"),
        TaskItem(title: "قراءة صفحتين من كتابي المفضّل"),
        TaskItem(title: "حل واجب العلوم")
    ]
    
    // متغير للتحكم بفتح صفحة إنشاء المهمة
    @State private var showTaskCreationView = false
    
    // المهمة المختارة لعرض تفاصيلها
    @State private var selectedTask: TaskItem?
    
    // المهمة الجاري تنفيذها لبدء الجلسة (Help Me Start ➔ Task Session ➔ Task Completion)
    @State private var activeExecutionTask: HomeworkTask?
    
    // MARK: - الألوان (الباليت: 1E264F - 1E2651 - 4454A9 - B39DDB)
    let backgroundTop = Color(hex: "1E264F")
    let backgroundBottom = Color(hex: "1E2651")
    let accentButton = Color(red: 0.20, green: 0.68, blue: 0.58)
    let cardGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "4454A9").opacity(0.8),
            Color(hex: "1E2651").opacity(0.9)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // 1. الخلفية الأساسية - صورة من Assets بدل التدرج اللوني
            Image("Image")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // 2. المحتوى الرئيسي
            VStack(spacing: 0) {
                
                // أزرا الإبهار العلوية (المساعدة والرجوع)
                HStack {
                    
                    // زر الرجوع
                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 40)
                            .background(accentButton)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // زر المساعدة
                    Button(action: {}) {
                        Text("؟")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 45, height: 45)
                            .background(accentButton)
                            .clipShape(Circle())
                    }
                    
                    
                }
                .padding(.horizontal, 40)
                .padding(.top, 30)
                
                VStack(alignment: .trailing, spacing: 20) {
                    
                    // النصوص والعناوين (ثابتة، ما تتحرك مع التمرير)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("جميـع المهــام")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(accentButton)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("أضف مهام جديدة، رتبها حسب الأولوية، وقسم المهام الكبيرة الى خطوات بسيطة تساعد طفلك على التركيز والإنجاز بثقة واستقلالية.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.trailing)
                            .lineSpacing(4)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 15)
                    .padding(.horizontal, 50)
                    
                    // قائمة بطاقات المهام - ارتفاع ثابت يعرض أول 3 مهام بوضوح، وبعدها يبدأ التمرير
                    ScrollView(showsIndicators: true) {
                        VStack(spacing: 16) {
                            ForEach(tasks) { task in
                                taskCardRow(task: task)
                            }
                        }
                        .padding(.horizontal, 50)
                    }
                    .frame(maxHeight: .infinity)
                    
                    Spacer(minLength: 30)
                }
                
                // 3. زر الإضافة الدائري (+) في الأسفل
                Button(action: {
                    showTaskCreationView = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 65, height: 65)
                        .background(accentButton)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: accentButton.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 25)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        // الانتقال إلى صفحة اختيار طريقة كتابة المهمة عند الضغط على زر (+) - كبوب أب
        .sheet(isPresented: $showTaskCreationView) {
            TaskCreationChoiceView(isPresented: $showTaskCreationView) { newTask in
                tasks.append(newTask)
            }
        }
        // فتح صفحة تفاصيل المهمة عند اختيار مهمة من القائمة
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task) {
                tasks.removeAll { $0.id == task.id }
            }
        }
        // بدء تنفيذ المهمة (Help Me Start ➔ Focus ➔ Completion) عند الضغط على بطاقة المهمة
        .fullScreenCover(item: $activeExecutionTask) { task in
            TaskFlowView(
                task: task,
                onExitToMain: {
                    activeExecutionTask = nil
                }
            )
        }
    }
    
    // MARK: - تصميم بطاقة المهمة الواحدة
    @ViewBuilder
    private func taskCardRow(task: TaskItem) -> some View {
        HStack {
            // عنوان المهمة
            Text(task.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // زر عرض التفاصيل
            Button(action: {
                selectedTask = task
            }) {
                Text("عرض التفاصيل")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(accentButton)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 18)
        .background(cardGradient)
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            startTaskExecution(taskItem: task)
        }
    }
    
    // تحويل TaskItem إلى HomeworkTask وبدء التنفيذ
    private func startTaskExecution(taskItem: TaskItem) {
        let steps = taskItem.steps.isEmpty ? ["أكمل المهمة"] : taskItem.steps
        if let createdTask = HomeworkTask.createFromTaskCreation(
            title: taskItem.title,
            focusDurationMinutes: taskItem.focusMinutes > 0 ? taskItem.focusMinutes : 10,
            breakDurationMinutes: taskItem.breakMinutes > 0 ? taskItem.breakMinutes : 5,
            validityDays: 1,
            stepTitles: steps,
            requiresCompletionPIN: taskItem.requirePin
        ) {
            activeExecutionTask = createdTask
        }
    }
}

// MARK: - المعاينة الخاصية بالأيباد (Landscape)
#Preview(traits: .landscapeLeft) {
    TasksListView()
}
