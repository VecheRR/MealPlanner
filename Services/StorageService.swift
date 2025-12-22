//
//  StorageService.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import Foundation

struct StorageService {
    private let fileName = "mealplanner_plans_v1.json"

    private var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    func loadPlans() throws -> [MealPlan] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([MealPlan].self, from: data)
        } catch {
            throw AppError.storage(error.localizedDescription)
        }
    }

    func savePlans(_ plans: [MealPlan]) throws {
        do {
            let data = try JSONEncoder().encode(plans)
            try data.write(to: url, options: [.atomic])
        } catch {
            throw AppError.storage(error.localizedDescription)
        }
    }
}
