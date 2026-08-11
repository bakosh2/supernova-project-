//
//  TasksListView.swift
//  app1
//
//  Created by alanoud on 21/02/1448 AH.
//

import SwiftUI
import SwiftData

// MARK: - View قائمة المهام الرئيسي

struct TasksListView: View {
    @Environment(\.modelContext) private var modelContext
    
    // قائمة مهام تجريبية للظهور بالواجهة
    @State private var tasks: [TaskItem] = [
        TaskItem(
            title: "حل واجب الرياضيات",
            focusMinutes: 10,
            breakMinutes: 5,
            steps: ["أكمل المسائل الفردية فقط", "حل سؤال ٤", "تأكد من حلك"]
        ),
        TaskItem(
            title: "قراءة صفحتين من كتابي المفضّل",
            focusMinutes: 15,
            breakMinutes: 3,
            steps: ["قراءة الفصل الأول"]
        ),
        TaskItem(
            title: "حل واجب العلوم",
            focusMinutes: 20,
            breakMinutes: 5,
            steps: ["رسم الخلية النباتية", "الإجابة عن السؤال الأخير"]
        )
    ]
    
    // قائمة المهام المشتركة المعززة بنماذج HomeworkTask للطفل
    @State private var homeworkTasks: [HomeworkTask] = [
        HomeworkTask.createFromTaskCreation(
            title: "حل واجب الرياضيات",
            focusDurationMinutes: 10,
            breakDurationMinutes: 5,
            stepTitles: ["أكمل المسائل الفردية فقط", "حل سؤال ٤", "تأكد من حلك"],
            requiresCompletionPIN: false
        )!,
        HomeworkTask.createFromTaskCreation(
            title: "قراءة صفحتين من كتابي المفضّل",
            focusDurationMinutes: 15,
            breakDurationMinutes: 3,
            stepTitles: ["قراءة الفصل الأول"],
            requiresCompletionPIN: false
        )!,
        HomeworkTask.createFromTaskCreation(
            title: "حل واجب العلوم",
            focusDurationMinutes: 20,
            breakDurationMinutes: 5,
            stepTitles: ["رسم الخلية النباتية", "الإجابة عن السؤال الأخير"],
            requiresCompletionPIN: false
        )!
    ]
    
    // متغيرات التحكم بفتح المودالات والتحقق من الحد الأقصى للمهام
    @State private var showTaskCreationView = false
    @State private var showChildDashboard = false
    @State private var showLimitAlert = false
    
    // المهمة المختارة لعرض تفاصيلها
    @State private var selectedTask: TaskItem?
    
    // MARK: - Active Tasks & 10-Task Limit Check
    var activeTasks: [HomeworkTask] {
        homeworkTasks
    }
    
    var canAddAnotherTask: Bool {
        activeTasks.count < 10
    }
    
    // MARK: - الألوان
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
            // 1. الخلفية الأساسية - صورة parent-dashboard
            Image("parent-dashboard")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // 2. المحتوى الرئيسي
            VStack(spacing: 0) {
                
                // أزرا الإبهار العلوية (المساعدة والرجوع إلى واجهة الطفل)
                HStack {
                    // زر التبديل إلى واجهة الطفل (Child Dashboard)
                    Button(action: { showChildDashboard = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .bold))
                            Text("لوحة الطفل")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 40)
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
                    
                    // النصوص والعناوين
                    VStack(alignment: .leading, spacing: 10) {
                        Text("جميـع المهــام")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(accentButton)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("أضف مهام جديدة، وقسم المهام الكبيرة الى خطوات بسيطة تساعد طفلك على التركيز والإنجاز بثقة واستقلالية.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.trailing)
                            .lineSpacing(4)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 15)
                    .padding(.horizontal, 50)
                    
                    // قائمة بطاقات المهام
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
                
                // 3. زر الإضافة الدائري (+) في الأسفل (محدود بـ 10 مهام نشطة)
                Button(action: {
                    if canAddAnotherTask {
                        showTaskCreationView = true
                    } else {
                        showLimitAlert = true
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 65, height: 65)
                        .background(canAddAnotherTask ? accentButton : Color.gray)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: canAddAnotherTask ? accentButton.opacity(0.4) : Color.clear, radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 25)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .alert("الحد الأقصى للمهام النشطة", isPresented: $showLimitAlert) {
            Button("حسناً", role: .cancel) {}
        } message: {
            Text("لا يمكنك إضافة أكثر من ١٠ مهام نشطة في وقت واحد. يرجى إكمال المهام الحالية وتجميع نجومها أولاً.")
        }
        // الانتقال إلى صفحة اختيار طريقة كتابة المهمة عند الضغط على زر (+)
        .sheet(isPresented: $showTaskCreationView) {
            TaskCreationChoiceView(isPresented: $showTaskCreationView) { newTask in
                guard canAddAnotherTask else { return }
                
                tasks.append(newTask)
                
                let steps = newTask.steps.isEmpty ? ["أكمل المهمة"] : newTask.steps
                if let createdTask = HomeworkTask.createFromTaskCreation(
                    title: newTask.title,
                    focusDurationMinutes: newTask.focusMinutes > 0 ? newTask.focusMinutes : 10,
                    breakDurationMinutes: newTask.breakMinutes > 0 ? newTask.breakMinutes : 5,
                    stepTitles: steps,
                    requiresCompletionPIN: newTask.requirePin
                ) {
                    homeworkTasks.append(createdTask)
                }
            }
        }
        // فتح صفحة تفاصيل المهمة عند اختيار مهمة من القائمة
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task) {
                tasks.removeAll { $0.id == task.id }
                homeworkTasks.removeAll { $0.title == task.title }
            }
        }
        // الانتقال إلى لوحة الطفل (Child Dashboard)
        .fullScreenCover(isPresented: $showChildDashboard) {
            TodaysMissionsView(
                passedTasks: homeworkTasks,
                onBackToParent: {
                    showChildDashboard = false
                },
                onTaskDeleted: { deletedTask in
                    tasks.removeAll { $0.title == deletedTask.title }
                    homeworkTasks.removeAll { $0.id == deletedTask.id || $0.title == deletedTask.title }
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
    }
}

// MARK: - المعاينة
#Preview(traits: .landscapeLeft) {
    TasksListView()
}
