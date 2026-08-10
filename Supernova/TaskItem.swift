//
//  TaskItem.swift
//  app1
//
//  Created by alanoud on 23/02/1448 AH.
//

import SwiftUI

// MARK: - هيكل بيانات المهمة (Task Model)
struct TaskItem: Identifiable {
    let id = UUID()
    var title: String
    var focusMinutes: Int = 20          // مدة التركيز
    var breakMinutes: Int = 2           // مدة الاستراحة بين الخطوات
    var validity: String = "يوم"        // صلاحية المهمة
    var steps: [String] = []            // الخطوات
    var requirePin: Bool = false        // هل يتطلب رمز الأب قبل الإنهاء
}

#Preview {
}
