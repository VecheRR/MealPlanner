//
//  LocalPlanBuilder.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import Foundation

enum LocalPlanBuilder {
    static func build(settings: PlannerSettings) -> [PlanDay] {
        let daysCount = max(1, min(settings.days, 7))
        let mealsCount = max(2, min(settings.mealsPerDay, 4))
        let target = settings.calories ?? 2000

        let today = Date()
        let cal = Calendar.current

        // простая раскладка калорий по приёмам
        let shares: [Double]
        switch mealsCount {
        case 2: shares = [0.45, 0.55]
        case 3: shares = [0.30, 0.40, 0.30]
        default: shares = [0.25, 0.35, 0.25, 0.15]
        }

        let types: [MealType] = mealsCount == 4
            ? [.breakfast, .lunch, .dinner, .snack]
            : mealsCount == 3
                ? [.breakfast, .lunch, .dinner]
                : [.lunch, .dinner]

        return (0..<daysCount).map { offset in
            let date = cal.date(byAdding: .day, value: offset, to: today) ?? today
            let iso = isoDate(date)

            let meals: [PlannedMeal] = (0..<mealsCount).map { i in
                let kcal = Int(Double(target) * shares[i])

                // грубые макросы “по умолчанию”
                let protein = max(10, kcal / 20)
                let fat = max(8, kcal / 30)
                let carbs = max(10, (kcal - protein*4 - fat*9) / 4)

                let title = defaultTitle(for: types[i], goal: settings.goal)
                let terms = defaultTerms(for: types[i], goal: settings.goal, restrictions: settings.restrictions)

                return PlannedMeal(
                    type: types[i],
                    title: title,
                    kcal: kcal,
                    protein_g: protein,
                    fat_g: fat,
                    carbs_g: carbs,
                    search_terms: terms
                )
            }

            return PlanDay(dateISO: iso, meals: meals)
        }
    }

    private static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private static func defaultTitle(for type: MealType, goal: Goal) -> String {
        switch (goal, type) {
        case (.cut, .breakfast): return "High-protein breakfast"
        case (.cut, .lunch): return "Lean lunch bowl"
        case (.cut, .dinner): return "Light dinner plate"
        case (.cut, .snack): return "Protein snack"
        case (.bulk, .breakfast): return "Calorie-dense breakfast"
        case (.bulk, .lunch): return "Hearty lunch"
        case (.bulk, .dinner): return "Big dinner"
        case (.bulk, .snack): return "Energy snack"
        default:
            return "\(type.title)"
        }
    }

    private static func defaultTerms(for type: MealType, goal: Goal, restrictions: String) -> [String] {
        // terms под TheMealDB (поиск по названию)
        // restrictions просто добавим как “намёк” в термины (не идеально, но ок для прототипа)
        let r = restrictions.lowercased()
        let hint = r.isEmpty ? nil : r

        var base: [String]
        switch type {
        case .breakfast: base = ["omelette", "oat", "pancake"]
        case .lunch: base = ["chicken", "salad", "rice"]
        case .dinner: base = ["fish", "beef", "pasta"]
        case .snack: base = ["smoothie", "yogurt", "nuts"]
        }

        if goal == .cut { base.insert("salad", at: 0) }
        if goal == .bulk { base.insert("pasta", at: 0) }

        if let hint {
            base.insert(hint, at: 0)
        }

        return Array(base.prefix(4))
    }
}
