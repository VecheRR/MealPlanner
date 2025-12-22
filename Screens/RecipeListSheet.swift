//
//  RecipeListSheet.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import SwiftUI

struct RecipeListSheet: View {
    @Bindable var vm: PlannerViewModel
    let terms: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var results: [MealDBService.MealDBMeal] = []
    @State private var err: AppError?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Ищу рецепты…")
                            .foregroundStyle(.secondary)
                    }
                } else if let err {
                    ContentUnavailableView("Ошибка", systemImage: "exclamationmark.triangle", description: Text(err.localizedDescription))
                } else if results.isEmpty {
                    ContentUnavailableView("Ничего не найдено", systemImage: "magnifyingglass", description: Text("Попробуй другие search_terms"))
                } else {
                    List(results) { m in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(m.strMeal).font(.headline)
                            if let cat = m.strCategory {
                                Text(cat).foregroundStyle(.secondary)
                            }
                            if let area = m.strArea {
                                Text(area).foregroundStyle(.secondary)
                            }
                            if let src = m.strSource, let url = URL(string: src) {
                                Link("Source", destination: url)
                            }
                            if let yt = m.strYoutube, let url = URL(string: yt) {
                                Link("YouTube", destination: url)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await load()
            }
        }
    }

    private func load() async {
        err = nil
        isLoading = true
        defer { isLoading = false }

        do {
            results = try await vm.searchRecipes(for: terms)
        } catch let e as AppError {
            err = e
        } catch {
            err = .network(error.localizedDescription)
        }
    }
}
