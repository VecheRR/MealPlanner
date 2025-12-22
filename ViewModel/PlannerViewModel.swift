//
//  PlannerViewModel.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import SwiftUI
import Foundation
import Observation

@MainActor
@Observable
final class PlannerViewModel {
    var settings = PlannerSettings()
    var currentPlan: MealPlan?
    var history: [MealPlan] = []

    var isLoading = false
    var appError: AppError?

    let ai = OllamaAIService()
    let mealDB = MealDBService()
    let storage = StorageService()
    
    let liveActivity = LiveActivityManager()
    
    var progressText: String = ""
    var progressValue: Double = 0
    var isGenerating = false

    init() {
        do {
            history = try storage.loadPlans()
        } catch {
            self.appError = (error as? AppError) ?? .storage(error.localizedDescription)
        }
    }

    func generatePlan() async {
        appError = nil

        isGenerating = true
        isLoading = true
        progressValue = 0.05
        progressText = "Подготавливаем запрос…"
        defer {
            isLoading = false
            isGenerating = false
        }

        do {
            progressValue = 0.15
            progressText = "Готовим параметры плана…"
            try? await Task.sleep(nanoseconds: 200_000_000)

            progressValue = 0.35
            progressText = "Генерируем план с Ollama…"
            let days = try await ai.generatePlan(settings: settings)

            progressValue = 0.70
            progressText = "Проверяем и приводим данные…"
            // Если у тебя нормализация дат:
            // let normalized = normalizeDates(days, settings: settings)

            progressValue = 0.85
            progressText = "Сохраняем результат…"
            currentPlan = MealPlan(settings: settings, days: days)

            progressValue = 1.0
            progressText = "Готово ✅"
            try? await Task.sleep(nanoseconds: 350_000_000)
        } catch let e as AppError {
            currentPlan = MealPlan(settings: settings, days: LocalPlanBuilder.build(settings: settings))
            appError = e
            progressText = "Ошибка, сделал базовый план"
            progressValue = 1.0
            try? await Task.sleep(nanoseconds: 500_000_000)
        } catch {
            currentPlan = MealPlan(settings: settings, days: LocalPlanBuilder.build(settings: settings))
            appError = .network(error.localizedDescription)
            progressText = "Ошибка сети, сделал базовый план"
            progressValue = 1.0
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }

    func saveCurrentToHistory() {
        guard let plan = currentPlan else { return }
        // чтобы не плодить одинаковые — можно чекать id, но для прототипа норм
        history.insert(plan, at: 0)
        do {
            try storage.savePlans(history)
        } catch let e as AppError {
            appError = e
        } catch {
            appError = .storage(error.localizedDescription)
        }
    }

    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        do {
            try storage.savePlans(history)
        } catch {
            appError = .storage(error.localizedDescription)
        }
    }

    func searchRecipes(for terms: [String]) async throws -> [MealDBService.MealDBMeal] {
        // соберём топ выдачу: по всем терминам, но без дублей
        var all: [MealDBService.MealDBMeal] = []
        var seen = Set<String>()

        for t in terms {
            let found = try await mealDB.searchMeals(query: t)
            for m in found where !seen.contains(m.idMeal) {
                seen.insert(m.idMeal)
                all.append(m)
            }
            if all.count >= 20 { break }
        }
        return all
    }
}
