//
//  LiveActivityManager.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    private var activity: Activity<MealPlanActivityAttributes>?

    func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attrs = MealPlanActivityAttributes(title: "MealPlanner")
        let state = MealPlanActivityAttributes.ContentState(step: "Starting…", progress: 0.05)

        do {
            activity = try Activity.request(
                attributes: attrs,
                content: .init(state: state, staleDate: nil)
            )
        } catch {
            // можно логировать, но не падаем
        }
    }

    func update(step: String, progress: Double) async {
        guard let activity else { return }
        let clamped = min(1, max(0, progress))
        let state = MealPlanActivityAttributes.ContentState(step: step, progress: clamped)
        await activity.update(.init(state: state, staleDate: nil))
    }

    func end(success: Bool) async {
        guard let activity else { return }
        let state = MealPlanActivityAttributes.ContentState(
            step: success ? "Done ✅" : "Failed ❌",
            progress: success ? 1 : 0
        )
        await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
        self.activity = nil
    }
}
