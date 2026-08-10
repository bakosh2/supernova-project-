//
//  TaskCreationChoiceView.swift
//  app1
//
//  Created by alanoud on 21/02/1448 AH.
//

import SwiftUI

// MARK: - صفحة اختيار طريقة إنشاء المهمة

struct TaskCreationChoiceView: View {

    @Binding var isPresented: Bool

    var onSave: (TaskItem) -> Void

    @State private var goToManual = false

    // MARK: - الألوان

    private let teal = Color(hex: "4DB6AC")
    private let titleColor = Color(hex: "EDE7F6")

    var body: some View {
        ZStack {

            // الخلفية الأساسية - صورة من Assets بدل الألوان
            Image("Choice")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: المنطقة العلوية

                ZStack {

                    VStack(spacing: 0) {

                        topBar

                        Spacer()

                        Text("اكتب مهمتك لطفلك")
                            .font(
                                .system(
                                    size: 34,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(titleColor)
                            .offset(y: -80)

                        Spacer()
                            .frame(height: 60)
                    }
                }
                .frame(height: 300)
                .clipped()

                Spacer()
            }

            // MARK: خيارات إنشاء المهمة

            VStack {

                Spacer()
                    .frame(height: 340)

                optionsRow

                Spacer()
            }
        }
        .fullScreenCover(isPresented: $goToManual) {
            TaskCreationView { newTask in
                onSave(newTask)
                isPresented = false
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - الشريط العلوي

    private var topBar: some View {
        HStack {

            Button {
                isPresented = false
            } label: {
                Image(systemName: "chevron.right")
                    .font(
                        .system(
                            size: 18,
                            weight: .bold
                        )
                    )
                    .foregroundColor(.white)
                    .frame(width: 60, height: 40)
                    .background(teal)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Button {

            } label: {
                Text("؟")
                    .font(
                        .system(
                            size: 18,
                            weight: .bold
                        )
                    )
                    .foregroundColor(.white)
                    .frame(width: 45, height: 45)
                    .background(teal)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 35)
        .padding(.top, 20)
    }

    // MARK: - خيارات الإنشاء

    private var optionsRow: some View {
        HStack(spacing: 24) {

            optionButton(
                icon: "cpu",
                title: "بمساعدة الذكاء\nالاصطناعي"
            ) {
                // اربطيه بواجهة الذكاء الاصطناعي
            }

            optionButton(
                icon: "square.and.pencil",
                title: "يدويًا"
            ) {
                goToManual = true
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: - زر الاختيار

    private func optionButton(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {

                ZStack {
                    Circle()
                        .stroke(teal, lineWidth: 1.5)
                        .frame(width: 46, height: 46)

                    Image(systemName: icon)
                        .foregroundColor(teal)
                        .font(
                            .system(
                                size: 18,
                                weight: .bold
                            )
                        )
                }

                Text(title)
                    .font(
                        .system(
                            size: 17,
                            weight: .bold
                        )
                    )
                    .foregroundColor(teal)
                    .multilineTextAlignment(.leading)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 18)
            .frame(minWidth: 280)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.15))
            )
            .overlay {
                Capsule()
                    .stroke(teal, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview(traits: .landscapeLeft) {
    TaskCreationChoiceView(
        isPresented: .constant(true),
        onSave: { _ in }
    )
}
