//
//  HistoryView.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import SwiftUI

struct HistoryView: View {
    @Bindable var vm: PlannerViewModel

    var body: some View {
        List {
            if vm.history.isEmpty {
                ContentUnavailableView("История пустая", systemImage: "clock")
            } else {
                ForEach(vm.history) { plan in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(plan.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                        Text("\(plan.settings.goal.title) • \(plan.settings.days) days • \(plan.settings.mealsPerDay) meals/day")
                            .foregroundStyle(.secondary)
                    }
                    .onTapGesture {
                        vm.currentPlan = plan
                    }
                }
                .onDelete(perform: vm.deleteHistory)
            }
        }
        .navigationTitle("History")
        .toolbar {
            EditButton()
        }
    }
}
