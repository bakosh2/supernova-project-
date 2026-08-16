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
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HomeworkTask.createdAt, order: .forward) private var homeworkTasks: [HomeworkTask]
    
    // متغيرات التحكم بفتح المودالات والتحقق من الحد الأقصى للمهام
    @State private var showTaskCreationView = false
    @State private var showChildDashboard = false
    @State private var showLimitAlert = false
    
    // المهمة المختارة لعرض تفاصيلها
    @State private var selectedTask: TaskItem?
    
    // MARK: - Active Tasks & 10-Task Limit Check
    private var tasks: [TaskItem] {
        homeworkTasks.map {
            TaskItem(
                title: $0.title,
                focusMinutes: max(1, $0.focusDurationSeconds / 60),
                breakMinutes: max(1, $0.breakDurationSeconds / 60),
                steps: $0.sortedSubtasks.map(\.title),
                requirePin: $0.requiresCompletionPIN
            )
        }
    }
    
    var canAddAnotherTask: Bool {
        homeworkTasks.count < 10
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
                
                // أزرار التنقل العلوية
                HStack {
                    BackCapsuleButton { dismiss() }

                    Spacer()

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
                        .frame(height: 48)
                        .supernovaGlassCapsule()
                    }

                }
                .environment(\.layoutDirection, .leftToRight)
                .padding(.horizontal, AppHeaderLayout.horizontal)
                .padding(.top, AppHeaderLayout.top)
                
                VStack(alignment: .trailing, spacing: 20) {
                    
                    // النصوص والعناوين
                    VStack(alignment: .trailing, spacing: 10) {
                        Text("جميـع المهــام")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        Text("أضف مهام جديدة، وقسم المهام الكبيرة الى خطوات بسيطة تساعد طفلك على التركيز والإنجاز بثقة واستقلالية.")
                            .font(.system(size: 16))
                            .foregroundColor(accentButton)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .lineSpacing(4)
                    }
                    // Keep the heading visually beneath the child dashboard button.
                    .padding(.top, 28)
                    .padding(.bottom, 15)
                    .padding(.horizontal, 50)
                    // Keep the parent dashboard heading physically on the right.
                    // The screen uses RTL overall, which otherwise mirrors `.trailing`
                    // to the left side of the iPad.
                    .environment(\.layoutDirection, .leftToRight)
                    
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
                        .supernovaGlassCircle(
                            tint: canAddAnotherTask ? .tealPrimary : Color(hex: "#5A648D"),
                            opacity: canAddAnotherTask ? 0.68 : 0.72
                        )
                }
                .padding(.bottom, 130)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .alert("الحد الأقصى للمهام النشطة", isPresented: $showLimitAlert) {
            Button("حسناً", role: .cancel) {}
        } message: {
            Text("لا يمكنك إضافة أكثر من ١٠ مهام نشطة في وقت واحد. يرجى إكمال المهام الحالية وتجميع نجومها أولاً.")
        }
        // الانتقال إلى صفحة اختيار طريقة كتابة المهمة عند الضغط على زر (+)
        .fullScreenCover(isPresented: $showTaskCreationView) {
            TaskCreationChoiceView(isPresented: $showTaskCreationView) { newTask in
                guard canAddAnotherTask else { return }
                
                let steps = newTask.steps.isEmpty ? ["أكمل المهمة"] : newTask.steps
                if let createdTask = HomeworkTask.createFromTaskCreation(
                    title: newTask.title,
                    focusDurationMinutes: newTask.focusMinutes > 0 ? newTask.focusMinutes : 10,
                    breakDurationMinutes: newTask.breakMinutes > 0 ? newTask.breakMinutes : 5,
                    stepTitles: steps,
                    requiresCompletionPIN: newTask.requirePin
                ) {
                    modelContext.insert(createdTask)
                    try? modelContext.save()
                }
            }
        }
        // فتح صفحة تفاصيل المهمة عند اختيار مهمة من القائمة
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task) {
                deleteStoredTask(named: task.title)
            }
        }
        // الانتقال إلى لوحة الطفل (Child Dashboard)
        .fullScreenCover(isPresented: $showChildDashboard) {
            TodaysMissionsView(
                onBackToParent: {
                    showChildDashboard = false
                },
                onTaskDeleted: { deletedTask in
                    modelContext.delete(deletedTask)
                    try? modelContext.save()
                }
            )
        }
        .navigationBarBackButtonHidden(true)
    }

    private func deleteStoredTask(named title: String) {
        for task in homeworkTasks where task.title == title {
            modelContext.delete(task)
        }
        try? modelContext.save()
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
