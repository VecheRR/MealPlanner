//
//  Models.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import Foundation

enum Goal: String, CaseIterable, Codable, Identifiable {
    case cut, maintain, bulk
    var id: String { rawValue }

    var title: String {
        switch self {
        case .cut: return "Похудение"
        case .maintain: return "Поддержание"
        case .bulk: return "Масса"
        }
    }
}

struct PlannerSettings: Codable, Equatable {
    var goal: Goal = .cut
    var calories: Int? = 2000
    var mealsPerDay: Int = 3
    var restrictions: String = ""
    var days: Int = 3

    var profile: BodyProfile = BodyProfile()
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }
}

struct PlannedMeal: Codable, Identifiable, Equatable {
    let id: UUID
    let type: MealType
    let title: String
    let kcal: Int
    let protein_g: Int
    let fat_g: Int
    let carbs_g: Int
    let search_terms: [String]

    enum CodingKeys: String, CodingKey {
        case type, title, kcal, protein_g, fat_g, carbs_g, search_terms
    }

    init(
        id: UUID = UUID(),
        type: MealType,
        title: String,
        kcal: Int,
        protein_g: Int,
        fat_g: Int,
        carbs_g: Int,
        search_terms: [String]
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.kcal = kcal
        self.protein_g = protein_g
        self.fat_g = fat_g
        self.carbs_g = carbs_g
        self.search_terms = search_terms
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.type = try c.decode(MealType.self, forKey: .type)
        self.title = try c.decode(String.self, forKey: .title)
        self.kcal = try c.decode(Int.self, forKey: .kcal)
        self.protein_g = try c.decode(Int.self, forKey: .protein_g)
        self.fat_g = try c.decode(Int.self, forKey: .fat_g)
        self.carbs_g = try c.decode(Int.self, forKey: .carbs_g)
        self.search_terms = try c.decode([String].self, forKey: .search_terms)
    }
}
