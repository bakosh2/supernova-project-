//
//  HelpMeStartView.swift
//  Supernova
//

import SwiftUI

/// Main native SwiftUI screen for "ساعدني أبدأ" (Help Me Start) on iPadOS landscape.
struct HelpMeStartView: View {
    @StateObject private var viewModel = HelpMeStartViewModel()
    @Environment(\.dismiss) private var dismiss
    
    /// Optional closure executed when the back button is pressed.
    var onBack: (() -> Void)?
    
    /// Closure executed when "يلا نبدأ!" is pressed.
    var onStart: (() -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            // Dynamic proportional sizing for responsive landscape iPad layout
            let contentWidth = min(screenWidth * 0.48, 540)
            let astronautWidth = min(screenWidth * 0.24, 280)
            
            ZStack(alignment: .topTrailing) {
                // Background space gradient with decorative stars
                SpaceBackgroundView()
                
                // Centered vertical content column (Title, 3 Checklist Rows, Start Button)
                VStack(spacing: 30) {
                    // Top area spacing below top bar
                    Spacer()
                        .frame(height: max(screenHeight * 0.08, 40))
                    
                    // Arabic header title "ساعدني أبدأ"
                    Text("ساعدني أبدأ")
                        .font(.system(size: min(screenWidth * 0.042, 52), weight: .bold))
                        .foregroundColor(.white)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.bottom, max(screenHeight * 0.04, 28))
                    
                    // Vertically stacked checklist rows
                    VStack(spacing: max(screenHeight * 0.02, 16)) {
                        HelpChecklistRow(
                            title: "هل مكانك هادئ؟",
                            isSelected: viewModel.isQuietPlaceChecked,
                            onTap: { viewModel.toggleQuietPlace() }
                        )
                        
                        HelpChecklistRow(
                            title: "هل معك أدواتك؟",
                            isSelected: viewModel.hasMaterialsChecked,
                            onTap: { viewModel.toggleMaterials() }
                        )
                        
                        HelpChecklistRow(
                            title: "هل معك ماء؟",
                            isSelected: viewModel.hasWaterChecked,
                            onTap: { viewModel.toggleWater() }
                        )
                    }
                    .frame(width: contentWidth)
                    .padding(.bottom, max(screenHeight * 0.04, 32))
                    
                    // Main action button ("يلا نبدأ!")
                    HelpMeStartButton(
                        isEnabled: viewModel.allItemsChecked,
                        action: {
                            onStart?()
                        }
                    )
                    .frame(width: min(contentWidth * 0.88, 440))
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
                // Upper-Right Back Button (Teal Capsule)
                BackCapsuleButton(action: {
                    if let onBack = onBack {
                        onBack()
                    } else {
                        dismiss()
                    }
                })
                .padding(.top, max(screenHeight * 0.04, 28))
                .padding(.trailing, max(screenWidth * 0.04, 36))
                
                // Lower-Left Astronaut Illustration with Star
                VStack {
                    Spacer()
                    HStack {
                        ZStack(alignment: .topTrailing) {
                            Image("astronaut 2")
                                .frame(width: 350)
                                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                            
                            // Yellow star asset
                            Image("Star")
                                .frame(width: astronautWidth * 0.4)
                                .offset(x: -35, y: 60)
                        }
                        .padding(.leading, max(screenWidth * 0.03, 18))
                        .padding(.bottom, max(screenHeight * 0.04, 18))
                        
                        Spacer()
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

// MARK: - Previews

#Preview("Help Me Start View") {
    HelpMeStartView()
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDevice(PreviewDevice(rawValue: "iPad Air 11-inch (M4)"))
}
