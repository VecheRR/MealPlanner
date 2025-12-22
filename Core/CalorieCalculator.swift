//
//  CalorieCalculator.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import Foundation

enum Sex: String, CaseIterable, Codable, Equatable {
    case male, female

    var title: String {
        switch self {
        case .male: return "Мужчина"
        case .female: return "Женщина"
        }
    }
}

enum ActivityLevel: String, CaseIterable, Codable, Equatable {
    case sedentary, light, moderate, high

    var title: String {
        switch self {
        case .sedentary: return "Минимальная"
        case .light: return "Лёгкая (1–3 трен.)"
        case .moderate: return "Средняя (3–5 трен.)"
        case .high: return "Высокая (6–7 трен.)"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .high: return 1.725
        }
    }
}

struct BodyProfile: Equatable, Codable {
    var sex: Sex = .male
    var age: Int = 25          // лет
    var heightCm: Int = 180    // см
    var weightKg: Int = 80     // кг
    var activity: ActivityLevel = .moderate
}

struct CalorieTargets: Equatable {
    let cut: Int        // похудение
    let maintain: Int   // поддержание
    let bulk: Int       // набор
    let tdee: Int       // поддержание (то же, но явно)
}

enum CalorieCalculator {
    // Mifflin–St Jeor
    static func bmr(profile: BodyProfile) -> Double {
        let w = Double(profile.weightKg)
        let h = Double(profile.heightCm)
        let a = Double(profile.age)

        switch profile.sex {
        case .male:
            return 10*w + 6.25*h - 5*a + 5
        case .female:
            return 10*w + 6.25*h - 5*a - 161
        }
    }

    static func tdee(profile: BodyProfile) -> Double {
        bmr(profile: profile) * profile.activity.multiplier
    }

    static func targets(profile: BodyProfile) -> CalorieTargets {
        let t = tdee(profile: profile)

        // Простые, понятные проценты:
        let cut = Int((t * 0.80).rounded())       // -20%
        let maintain = Int(t.rounded())
        let bulk = Int((t * 1.12).rounded())      // +12% (умеренный набор)

        return CalorieTargets(cut: cut, maintain: maintain, bulk: bulk, tdee: maintain)
    }
}
