//
//  MealPlannerLiveActivityBundle.swift
//  MealPlannerLiveActivity
//
//  Created by  Vladislav on 20.12.2025.
//

import WidgetKit
import SwiftUI

@main
struct MealPlannerLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        MealPlannerLiveActivityWidget()
        // Оставь эти два только если они реально существуют в проекте
        MealPlannerLiveActivityControl()
        MealPlannerLiveActivityLiveActivity()
    }
}
