//
//  PlanDay.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import Foundation

struct PlanDay: Codable, Identifiable, Equatable {
    let id: UUID
    let dateISO: String
    let meals: [PlannedMeal]

    enum CodingKeys: String, CodingKey {
        case dateISO, meals
    }

    init(id: UUID = UUID(), dateISO: String, meals: [PlannedMeal]) {
        self.id = id
        self.dateISO = dateISO
        self.meals = meals
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.dateISO = try c.decode(String.self, forKey: .dateISO)
        self.meals = try c.decode([PlannedMeal].self, forKey: .meals)
    }
}
