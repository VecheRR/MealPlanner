//
//  MealPlannerLiveActivity.swift
//  MealPlannerLiveActivity
//
//  Created by  Vladislav on 20.12.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MealPlannerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MealPlanActivityAttributes.self) { context in
            // Lock Screen / banner
            VStack(alignment: .leading, spacing: 8) {
                Text(context.attributes.title).font(.headline)
                Text(context.state.step).font(.subheadline)
                ProgressView(value: context.state.progress)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("🍽️")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.progress * 100))%")
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.step)
                        .lineLimit(1)
                    ProgressView(value: context.state.progress)
                }
            } compactLeading: {
                Text("🍽️")
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))%").monospacedDigit()
            } minimal: {
                Text("🍽️")
            }
        }
    }
}
