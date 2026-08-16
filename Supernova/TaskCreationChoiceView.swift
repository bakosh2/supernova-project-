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
    @State private var goToSupernova = false

    // MARK: - الألوان

    // One primary button colour used by the parent dashboard and task flow.
    private let teal = Color(red: 0.20, green: 0.68, blue: 0.58)
    private let titleColor = Color(hex: "EDE7F6")

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            ZStack {
                Image("Choice")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                    Spacer(minLength: isLandscape ? 46 : 70)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("اكتب مهمتك لطفلك")
                    .font(.system(size: isLandscape ? 42 : 32, weight: .bold, design: .rounded))
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.32), radius: 8, y: 4)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * (isLandscape ? 0.43 : 0.41)
                    )

                optionsRow(isLandscape: isLandscape)
                    .padding(.horizontal, 28)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * (isLandscape ? 0.58 : 0.56)
                    )
            }
        }
        .fullScreenCover(isPresented: $goToManual) {
            TaskCreationView { newTask in
                onSave(newTask)
                isPresented = false
            }
        }
        .fullScreenCover(isPresented: $goToSupernova) {
            SupernovaAgentChatView(
                onTaskAdded: { task in
                    onSave(task)
                },
                onClose: {
                    goToSupernova = false
                }
            )
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - الشريط العلوي

    private var topBar: some View {
        HStack {

            BackCapsuleButton {
                isPresented = false
            }

            Spacer()
        }
        .padding(.horizontal, AppHeaderLayout.horizontal)
        .padding(.top, AppHeaderLayout.top)
        // Keep the shared back control physically on the left, even in Arabic.
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: - خيارات الإنشاء

    @ViewBuilder
    private func optionsRow(isLandscape: Bool) -> some View {
        if isLandscape {
            HStack(spacing: 24) {
                aiOption
                manualOption
            }
            .environment(\.layoutDirection, .leftToRight)
        } else {
            VStack(spacing: 18) {
                aiOption
                manualOption
            }
            .frame(maxWidth: 380)
        }
    }

    private var aiOption: some View {
        optionButton(icon: "cpu", title: "بمساعدة الذكاء\nالاصطناعي") {
            goToSupernova = true
        }
    }

    private var manualOption: some View {
        optionButton(icon: "square.and.pencil", title: "يدوياً") {
            goToManual = true
        }
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
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 46, height: 46)

                    Image(systemName: icon)
                        .foregroundColor(.white)
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
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 18)
            .frame(maxWidth: 320)
            .supernovaGlassCapsule()
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
