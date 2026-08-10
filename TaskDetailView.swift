//
//  TaskDetailView.swift
//  app1
//
//  Created by alanoud on 21/02/1448 AH.
//

//
//  TaskDetailView.swift
//  app1
//
//  صفحة عرض تفاصيل مهمة محدّدة (العنوان، المدد، الخطوات...)
//

import SwiftUI

struct TaskDetailView: View {
    let task: TaskItem
    
    // دالة تُستدعى بعد تأكيد الحذف عشان تشيل المهمة من قائمة TasksListView
    var onDelete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    
    // للتحكم بظهور بوب أب تأكيد الحذف
    @State private var showDeleteConfirmation = false

    // نفس الألوان المستخدمة في باقي الصفحات
    private let backgroundTop = Color(hex: "1E264F")
    private let backgroundBottom = Color(hex: "1E2651")
    private let accentButton = Color(red: 0.20, green: 0.68, blue: 0.58)
    private let cardBackground = Color(hex: "4454A9").opacity(0.35)
    private let deleteColor = Color(red: 0.85, green: 0.30, blue: 0.30)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [backgroundTop, backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .trailing, spacing: 24) {

                        // عنوان المهمة
                        Text(task.title)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(accentButton)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 10)

                        // بطاقة المدد والصلاحية
                        HStack(spacing: 16) {
                            infoChip(title: "صلاحية المهمة", value: task.validity)
                            infoChip(title: "مدة الإستراحة", value: "\(task.breakMinutes) د")
                            infoChip(title: "مدة التركيز", value: "\(task.focusMinutes) د")
                        }

                        // الخطوات
                        VStack(alignment: .leading, spacing: 12) {
                            Text("الخطوات")
                                .font(.headline)
                                .foregroundColor(.white)

                            if task.steps.isEmpty {
                                Text("لا توجد خطوات مضافة لهذه المهمة")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            } else {
                                ForEach(Array(task.steps.enumerated()), id: \.offset) { index, step in
                                    HStack {
                                        Text("\(index + 1)")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                            .frame(width: 28, height: 28)
                                            .background(accentButton)
                                            .clipShape(Circle())

                                        Spacer()

                                        Text(step)
                                            .foregroundColor(.white)
                                            .font(.body)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .padding()
                                    .background(cardBackground)
                                    .cornerRadius(15)
                                }
                            }
                        }

                        // خيار رمز الأب
                        HStack {
                            Image(systemName: task.requirePin ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.requirePin ? accentButton : .gray)
                            Spacer()
                            Text("يتطلب إدخال الرمز قبل إنهاء المهمة")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(cardBackground)
                        .cornerRadius(15)

                        // زر حذف المهمة
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("حذف المهمة")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(deleteColor)
                            .cornerRadius(20)
                        }
                        .padding(.top, 10)

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 50)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        // بوب أب تأكيد الحذف
        .alert("هل أنت متأكد من حذف هذه المهمة؟", isPresented: $showDeleteConfirmation) {
            Button("إلغاء", role: .cancel) {}
            Button("حذف", role: .destructive) {
                onDelete()   // يشيل المهمة من قائمة TasksListView
                dismiss()    // يقفل صفحة التفاصيل ويرجع للقائمة
            }
        } message: {
            Text("لن تتمكن من التراجع عن هذا الإجراء بعد الحذف.")
        }
    }

    // MARK: - الشريط العلوي
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 40)
                    .background(accentButton)
                    .clipShape(Capsule())
            }
            Spacer()
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
    }

    // MARK: - بطاقة معلومة صغيرة (صلاحية/استراحة/تركيز)
    private func infoChip(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.75))
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview(traits: .landscapeLeft) {
    TaskDetailView(
        task: TaskItem(
            title: "حل واجب الرياضيات",
            focusMinutes: 20,
            breakMinutes: 2,
            validity: "يوم",
            steps: ["حل سؤال 1 فقط", "حل سؤال 2 فقط"],
            requirePin: true
        ),
        onDelete: {}
    )
}
