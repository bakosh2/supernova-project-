//
//  TaskCompletionView.swift
//  Supernova
//

import SwiftUI

/// Task completion celebration view displaying happy star and congratulation message.
struct TaskCompletionView: View {
    let task: HomeworkTask?
    let onClose: () -> Void
    
    init(task: HomeworkTask? = nil, onClose: @escaping () -> Void) {
        self.task = task
        self.onClose = onClose
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            ZStack(alignment: .topTrailing) {
                // Background star illustration with radiant light burst
                Image("happy star image")
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth, height: screenHeight)
                    .clipped()
                    .ignoresSafeArea()
                
                // Centered Congratulation Text
                VStack {
                    Spacer()
                    
                    Text("تهانينا لقد فزت بنجمة !")
                        .font(.system(size: min(screenWidth * 0.04, 44), weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#F9D043"))
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .multilineTextAlignment(.center)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.bottom, max(screenHeight * 0.12, 60))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Upper-Right Teal Close Button with xmark
                Button(action: onClose) {
                    ZStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.tealPrimary, Color(hex: "#43A8A0")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Capsule()
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "#1E264F"))
                    }
                    .frame(width: 90, height: 42)
                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                }
                .padding(.top, max(screenHeight * 0.04, 28))
                .padding(.trailing, max(screenWidth * 0.04, 36))
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Task Completion Screen") {
    TaskCompletionView(onClose: {})
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDevice(PreviewDevice(rawValue: "iPad Air 11-inch (M4)"))
}
