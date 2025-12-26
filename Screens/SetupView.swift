//
//  SetupView.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import SwiftUI

struct SetupView: View {
    @Bindable var vm: PlannerViewModel

    @State private var didLogOpen = false
    @State private var propsDebounceTask: Task<Void, Never>?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                caloriesCalculatorSection
                goalSection
                caloriesSection
                planSection
                restrictionsSection
                actionsSection
                errorSection
                adsDebugSection
            }
            .navigationTitle("Setup")
            .toolbar { historyToolbar }
            .onAppear(perform: onAppearLogOnce)
            .onChange(of: vm.settings.goal) { _, _ in scheduleUserPropsLog() }
            .onChange(of: vm.settings.mealsPerDay) { _, _ in scheduleUserPropsLog() }
            .onChange(of: vm.settings.calories) { _, _ in scheduleUserPropsLog() }
        }
        .onAppear {
            AdMobAdsManager.shared.loadRewarded()
        }
    }

    // MARK: - Sections

    private var caloriesCalculatorSection: some View {
        Section("Калькулятор калорий") {
            sexPicker
            ageHeightWeightSteppers
            activityPicker

            recommendationsBlock

            goalCaloriesButtons
        }
    }

    private var goalSection: some View {
        Section("Goal") {
            Picker("Цель", selection: $vm.settings.goal) {
                ForEach(Goal.allCases) { g in
                    Text(g.title).tag(g)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var caloriesSection: some View {
        Section("Calories") {
            Stepper(value: caloriesBinding, in: 1200...4500, step: 50) {
                Text("Калории: \(vm.settings.calories ?? 2000)")
            }
        }
    }

    private var planSection: some View {
        Section("Plan") {
            Stepper("Дней: \(vm.settings.days)", value: $vm.settings.days, in: 1...7)
            Stepper("Приёмов: \(vm.settings.mealsPerDay)", value: $vm.settings.mealsPerDay, in: 2...4)
        }
    }

    private var restrictionsSection: some View {
        Section("Restrictions") {
            TextField("Аллергии / исключения", text: $vm.settings.restrictions, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .toolbar { keyboardToolbar }
        }
    }

    private var actionsSection: some View {
        Section {
            generateButton
            rewardedButton
        }
    }

    private var errorSection: some View {
        Group {
            if let err = vm.appError {
                Section("Ошибка") {
                    Text(err.localizedDescription)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var adsDebugSection: some View {
        Section("Ads (debug)") {
            Button("Load Interstitial") { AdsManager.shared.loadInterstitial() }
            Button("Show Interstitial") { AdsManager.shared.showInterstitial() }
        }
    }

    // MARK: - Small UI pieces

    private var sexPicker: some View {
        Picker("Пол", selection: $vm.settings.profile.sex) {
            ForEach(Sex.allCases, id: \.self) { s in
                Text(s.title).tag(s)
            }
        }
        .pickerStyle(.segmented)
    }

    private var ageHeightWeightSteppers: some View {
        Group {
            Stepper("Возраст: \(vm.settings.profile.age)", value: $vm.settings.profile.age, in: 10...80)
            Stepper("Рост: \(vm.settings.profile.heightCm) см", value: $vm.settings.profile.heightCm, in: 120...220)
            Stepper("Вес: \(vm.settings.profile.weightKg) кг", value: $vm.settings.profile.weightKg, in: 35...200)
        }
    }

    private var activityPicker: some View {
        Picker("Активность", selection: $vm.settings.profile.activity) {
            ForEach(ActivityLevel.allCases, id: \.self) { a in
                Text(a.title).tag(a)
            }
        }
        // У тебя тут было onChange(of: vm.settings.goal) — это странно.
        // Если реально нужно пересчитывать calories при смене ЦЕЛИ — лучше повесить onChange на goal ниже (и он у тебя уже есть).
    }

    private var recommendationsBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Рекомендации:")
                .font(.headline)

            Text("Похудение: ~\(targets.cut) ккал")
            Text("Поддержание: ~\(targets.maintain) ккал")
            Text("Набор: ~\(targets.bulk) ккал")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var goalCaloriesButtons: some View {
        HStack {
            Button("Поставить для цели") {
                applyCaloriesForGoal()
            }
            .buttonStyle(.borderedProminent)

            Button("Поддержание") {
                vm.settings.calories = targets.maintain
            }
            .buttonStyle(.bordered)
        }
    }

    private var generateButton: some View {
        Button {
            let caloriesMode = (vm.settings.calories == nil) ? "auto" : "manual"

            AnalyticsService.shared.settingsSaved(
                goal: vm.settings.goal.rawValue,
                days: vm.settings.days,
                mealsPerDay: vm.settings.mealsPerDay,
                caloriesMode: caloriesMode
            )

            AnalyticsService.shared.planGenerateTap(
                goal: vm.settings.goal.rawValue,
                days: vm.settings.days,
                mealsPerDay: vm.settings.mealsPerDay,
                caloriesMode: caloriesMode
            )

            Task { await vm.generatePlan() }
        } label: {
            HStack {
                if vm.isLoading { ProgressView().padding(.trailing, 6) }
                Text(vm.isLoading ? "Генерирую..." : "Сгенерировать план")
            }
        }
        .disabled(vm.isLoading)
        .buttonStyle(.borderedProminent)
    }

    private var rewardedButton: some View {
        Button("🎁 Получить доп. план за рекламу") {
            AdMobAdsManager.shared.showRewarded {_ in 
                Task { await vm.generatePlan() }
            }
        }
    }

    // MARK: - Toolbars

    private var historyToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink("History") {
                HistoryView(vm: vm)
            }
        }
    }

    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Готово") { hideKeyboard() }
        }
    }

    // MARK: - Derived values / helpers

    private var targets: CalorieTargets {
        CalorieCalculator.targets(profile: vm.settings.profile)
    }

    private var caloriesBinding: Binding<Int> {
        Binding(
            get: { vm.settings.calories ?? 2000 },
            set: { vm.settings.calories = $0 }
        )
    }

    private func applyCaloriesForGoal() {
        switch vm.settings.goal {
        case .cut: vm.settings.calories = targets.cut
        case .maintain: vm.settings.calories = targets.maintain
        case .bulk: vm.settings.calories = targets.bulk
        }
    }

    private func onAppearLogOnce() {
        guard !didLogOpen else { return }
        didLogOpen = true
        AnalyticsService.shared.settingsOpen()
    }

    private func scheduleUserPropsLog() {
        propsDebounceTask?.cancel()
        propsDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)

            let caloriesMode = (vm.settings.calories == nil) ? "auto" : "manual"
            AnalyticsService.shared.setUserProperties(
                goal: vm.settings.goal.rawValue,
                mealsPerDay: vm.settings.mealsPerDay,
                caloriesMode: caloriesMode
            )
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
