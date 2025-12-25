import Foundation
import FirebaseAnalytics
import AppMetricaCore

final class AnalyticsService {

    static let shared = AnalyticsService()
    private init() {}

    // MARK: - Low level

    private func log(_ name: String, _ params: [String: Any] = [:]) {
        Analytics.logEvent(name, parameters: params)

        if params.isEmpty {
            AppMetrica.reportEvent(name: name)
        } else {
            AppMetrica.reportEvent(name: name, parameters: params)
        }
    }

    // MARK: - User props

    func setUserProperties(goal: String, mealsPerDay: Int, caloriesMode: String) {
        Analytics.setUserProperty(goal, forName: "goal")
        Analytics.setUserProperty(String(mealsPerDay), forName: "meals_per_day")
        Analytics.setUserProperty(caloriesMode, forName: "target_calories_mode")

        log("user_props_set", [
            "goal": goal,
            "meals_per_day": mealsPerDay,
            "calories_mode": caloriesMode
        ])
    }

    // MARK: - Core funnel (4)

    func planGenerateTap(goal: String, days: Int, mealsPerDay: Int, caloriesMode: String) {
        log("plan_generate_tap", [
            "goal": goal,
            "days": days,
            "meals_per_day": mealsPerDay,
            "calories_mode": caloriesMode
        ])
    }

    func planGenerateStart(provider: String, model: String, days: Int, mealsPerDay: Int, caloriesMode: String) {
        log("plan_generate_start", [
            "provider": provider,
            "model": model,
            "days": days,
            "meals_per_day": mealsPerDay,
            "calories_mode": caloriesMode
        ])
    }

    func planGenerateSuccess(days: Int, totalMeals: Int) {
        log("plan_generate_success", [
            "days": days,
            "total_meals": totalMeals
        ])
    }

    func planGenerateFail(stage: String, errorType: String, httpStatus: Int? = nil) {
        var params: [String: Any] = [
            "stage": stage,
            "error_type": errorType
        ]
        if let httpStatus { params["http_status"] = httpStatus }
        log("plan_generate_fail", params)
    }

    // MARK: - History (2)

    func planSavedToHistory(days: Int) {
        log("plan_saved_to_history", [
            "days": days
        ])
    }

    func historyOpen(itemsCount: Int? = nil) {
        var params: [String: Any] = [:]
        if let itemsCount { params["items_count"] = itemsCount }
        log("history_open", params)
    }

    // MARK: - Recipes (2)

    func recipesSearch(termsCount: Int) {
        log("recipes_search", [
            "terms_count": termsCount
        ])
    }

    func recipeOpen(recipeId: String, source: String) {
        log("recipe_open", [
            "recipe_id": recipeId,
            "source": source
        ])
    }

    // MARK: - Paywall / Purchases (5) — под этап с AppHud

    func paywallShow(placement: String) {
        log("paywall_show", [
            "placement": placement
        ])
    }

    func paywallClose(placement: String) {
        log("paywall_close", [
            "placement": placement
        ])
    }

    func purchaseStart(productId: String, source: String) {
        log("purchase_start", [
            "product_id": productId,
            "source": source
        ])
    }

    func purchaseSuccess(productId: String, price: Double? = nil, currency: String? = nil) {
        var params: [String: Any] = [
            "product_id": productId
        ]
        if let price { params["price"] = price }
        if let currency { params["currency"] = currency }
        log("purchase_success", params)
    }

    func purchaseFail(productId: String, reason: String) {
        log("purchase_fail", [
            "product_id": productId,
            "reason": reason
        ])
    }
}
