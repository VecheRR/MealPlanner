//
//  PlanView.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import SwiftUI
import FirebaseAnalytics

struct PlanView: View {
    @Bindable var vm: PlannerViewModel
    @State private var selectedTerms: [String] = []
    @State private var isShowingRecipes = false

    var body: some View {
        Group {
            if let plan = vm.currentPlan {
                planList(plan)
            } else {
                ContentUnavailableView(
                    "Плана нет",
                    systemImage: "fork.knife",
                    description: Text("Сгенерируй план на экране Setup")
                )
            }
        }
        .navigationTitle("Plan")
        .sheet(isPresented: $isShowingRecipes) {
            RecipeListSheet(vm: vm, terms: selectedTerms)
        }
    }

    @ViewBuilder
    private func planList(_ plan: MealPlan) -> some View {
        List {
            Section {
                Button("Save to history") { vm.saveCurrentToHistory() }
            }

            ForEach(plan.days) { day in
                Section(day.dateISO) {
                    ForEach(day.meals) { meal in
                        mealRow(meal)
                    }
                }
            }
        }
    }

    private func mealRow(_ meal: PlannedMeal) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(meal.type.rawValue.capitalized): \(meal.title)")
                .font(.headline)

            Text("\(meal.kcal) kcal • P\(meal.protein_g) F\(meal.fat_g) C\(meal.carbs_g)")
                .foregroundStyle(.secondary)

            Button("Find recipes") {
                AnalyticsService.shared.recipesSearch(termsCount: meal.search_terms.count)
                
                selectedTerms = meal.search_terms
                isShowingRecipes = true
            }
        }
        .padding(.vertical, 4)
    }
}
