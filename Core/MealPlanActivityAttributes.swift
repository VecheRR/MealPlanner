//
//  MealPlanActivityAttributes.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import ActivityKit
import Foundation

struct MealPlanActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var step: String          // что делаем сейчас
        var progress: Double      // 0...1
    }

    var title: String            // заголовок активности
}
