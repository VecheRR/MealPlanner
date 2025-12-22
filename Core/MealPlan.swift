//
//  MealPlan.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import Foundation

struct MealPlan: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let settings: PlannerSettings
    var days: [PlanDay]

    init(id: UUID = UUID(), createdAt: Date = Date(), settings: PlannerSettings, days: [PlanDay]) {
        self.id = id
        self.createdAt = createdAt
        self.settings = settings
        self.days = days
    }
}
