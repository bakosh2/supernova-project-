//
//  HelpMeStartViewModel.swift
//  Supernova
//

import SwiftUI
import Combine

/// ViewModel managing the state for the "ساعدني أبدأ" (Help Me Start) checklist.
@MainActor
final class HelpMeStartViewModel: ObservableObject {
    @Published var isQuietPlaceChecked: Bool = false
    @Published var hasMaterialsChecked: Bool = false
    @Published var hasWaterChecked: Bool = false
    
    /// Returns true only when all three checklist items are checked.
    var allItemsChecked: Bool {
        isQuietPlaceChecked && hasMaterialsChecked && hasWaterChecked
    }
    
    /// Toggles the quiet place state.
    func toggleQuietPlace() {
        isQuietPlaceChecked.toggle()
    }
    
    /// Toggles the materials state.
    func toggleMaterials() {
        hasMaterialsChecked.toggle()
    }
    
    /// Toggles the water state.
    func toggleWater() {
        hasWaterChecked.toggle()
    }
    
    /// Resets all checklist items to false.
    func resetChecklist() {
        isQuietPlaceChecked = false
        hasMaterialsChecked = false
        hasWaterChecked = false
    }
}
