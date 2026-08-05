//
//  TaskSessionComponents.swift
//  Supernova
//

import SwiftUI

// MARK: - Navigation Capsule Button
struct SessionNavigationButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#1E264F"))
                .frame(width: 110, height: 42)
                .background(Color.tealPrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Subtask Completion Check Control
struct SubtaskCompletionControl: View {
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.purpleCheckbox)
                    .clipShape(Circle())
            } else {
                Circle()
                    .stroke(Color.purpleCheckbox, lineWidth: 2.5)
                    .frame(width: 36, height: 36)
            }
        }
    }
}

// MARK: - Disconnected Subtask Progress Segments (RTL Visual Progression)
struct SubtaskProgressSegments: View {
    let subtasks: [HomeworkSubtask]
    let currentIndex: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(subtasks.indices.reversed()), id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? Color.purpleCheckbox : (subtasks[index].isCompleted ? Color.purpleCheckbox.opacity(0.75) : Color.gray.opacity(0.22)))
                    .frame(height: 6)
            }
        }
    }
}

// MARK: - Previous Subtask Button
struct PreviousSubtaskButton: View {
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isDisabled ? Color.white.opacity(0.6) : .white)
                .frame(width: 36, height: 36)
                .background(isDisabled ? Color(hex: "#D1D1D4") : Color.purpleCheckbox)
                .clipShape(Circle())
        }
        .disabled(isDisabled)
    }
}

// MARK: - Focus Task Card (Left Side)
struct FocusTaskCard: View {
    let taskTitle: String
    let subtaskTitle: String
    let isSubtaskCompleted: Bool
    let subtasks: [HomeworkSubtask]
    let currentIndex: Int
    let isFirstSubtask: Bool
    let actionButtonTitle: String
    let canAdvance: Bool
    
    let onToggleCheck: () -> Void
    let onPreviousSubtask: () -> Void
    let onPrimaryAction: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 20) {
            // Task Title
            Text(taskTitle)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#1E264F"))
                .environment(\.layoutDirection, .rightToLeft)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            Spacer()
            
            // Current Subtask Row (Arabic text aligned right, check control on the right)
            HStack(spacing: 16) {
                Spacer()
                
                Text(subtaskTitle)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#1E264F"))
                    .multilineTextAlignment(.trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                
                SubtaskCompletionControl(
                    isCompleted: isSubtaskCompleted,
                    onTap: onToggleCheck
                )
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            // Progress Segments (Left) & Previous Button (Right) in explicit LTR container
            HStack(spacing: 12) {
                SubtaskProgressSegments(
                    subtasks: subtasks,
                    currentIndex: currentIndex
                )
                
                PreviousSubtaskButton(
                    isDisabled: isFirstSubtask,
                    action: onPreviousSubtask
                )
            }
            .environment(\.layoutDirection, .leftToRight)
            .padding(.bottom, 12)
            
            // Primary Action Button ("المهمة التالية" / "إنهاء المهمة")
            Button(action: onPrimaryAction) {
                Text(actionButtonTitle)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(canAdvance ? .white : Color.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(canAdvance ? Color.tealPrimary : Color.disabledButtonGray)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(
                        color: canAdvance ? Color.tealPrimary.opacity(0.4) : Color.clear,
                        radius: canAdvance ? 8 : 0,
                        x: 0,
                        y: canAdvance ? 3 : 0
                    )
            }
            .disabled(!canAdvance)
        }
        .padding(32)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Session Timer Ring Component
struct SessionTimerRing: View {
    let title: String
    let formattedTime: String
    let progress: Double
    let isBreak: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .environment(\.layoutDirection, .rightToLeft)
            
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.rowBackgroundDark.opacity(0.8), lineWidth: 12)
                
                // Progress Arc
                Circle()
                    .trim(from: 0, to: max(0, min(1, progress)))
                    .stroke(
                        isBreak ? Color.tealPrimary : Color.purpleCheckbox,
                        lineWidth: 12
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.8), value: progress)
                
                // MM:SS Time Text
                Text(formattedTime)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: 280, height: 280)
        }
    }
}

// MARK: - Focus Pause / Resume Button
struct FocusPauseButton: View {
    let isPaused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(isPaused ? "متابعة" : "إيقاف مؤقت", systemImage: isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.tealPrimary)
                .clipShape(Capsule())
                .shadow(color: Color.tealPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Break Encouragement Card (Left Side in Break Phase)
struct BreakEncouragementCard: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("أحسنت!")
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#1E264F"))
                .environment(\.layoutDirection, .rightToLeft)
            
            // Stretching star illustration asset
            Image("stretching_star")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 400)
            
            Text("حان الوقت ليرتاح عقلك قليلًا.")
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#1E264F"))
                .multilineTextAlignment(.center)
                .lineSpacing(12)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Skip Break Button
struct SkipBreakButton: View {
    let action: () -> Void
    
    var body: some View {
        Button("تخطي وقت الراحة", action: action)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(Color.tealPrimary)
            .clipShape(Capsule())
            .shadow(color: Color.tealPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}
