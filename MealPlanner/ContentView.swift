//
//  ContentView.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var vm = PlannerViewModel()

    var body: some View {
        TabView {
            SetupView(vm: vm)
                .tabItem { Label("Setup", systemImage: "slider.horizontal.3") }

            NavigationStack {
                PlanView(vm: vm)
            }
            .tabItem { Label("Plan", systemImage: "fork.knife") }

            NavigationStack {
                HistoryView(vm: vm)
            }
            .tabItem { Label("History", systemImage: "clock") }
        }
        .overlay {
            if vm.isGenerating {
                GenerationOverlay(progress: vm.progressValue, text: vm.progressText)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: vm.isGenerating)
    }
}
