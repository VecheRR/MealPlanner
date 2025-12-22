//
//  SetupView.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import SwiftUI

struct SetupView: View {
    @Bindable var vm: PlannerViewModel

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Калькулятор калорий") {
                    Picker("Пол", selection: $vm.settings.profile.sex) {
                        ForEach(Sex.allCases, id: \.self) { s in
                            Text(s.title).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)

                    Stepper("Возраст: \(vm.settings.profile.age)", value: $vm.settings.profile.age, in: 10...80)
                    Stepper("Рост: \(vm.settings.profile.heightCm) см", value: $vm.settings.profile.heightCm, in: 120...220)
                    Stepper("Вес: \(vm.settings.profile.weightKg) кг", value: $vm.settings.profile.weightKg, in: 35...200)

                    Picker("Активность", selection: $vm.settings.profile.activity) {
                        ForEach(ActivityLevel.allCases, id: \.self) { a in
                            Text(a.title).tag(a)
                        }
                    }
                    .onChange(of: vm.settings.goal) { _, _ in
                        let t = CalorieCalculator.targets(profile: vm.settings.profile)
                        switch vm.settings.goal {
                        case .cut: vm.settings.calories = t.cut
                        case .maintain: vm.settings.calories = t.maintain
                        case .bulk: vm.settings.calories = t.bulk
                        }
                    }

                    let targets = CalorieCalculator.targets(profile: vm.settings.profile)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Рекомендации:")
                            .font(.headline)

                        Text("Похудение: ~\(targets.cut) ккал")
                        Text("Поддержание: ~\(targets.maintain) ккал")
                        Text("Набор: ~\(targets.bulk) ккал")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)

                    HStack {
                        Button("Поставить для цели") {
                            switch vm.settings.goal {
                            case .cut: vm.settings.calories = targets.cut
                            case .maintain: vm.settings.calories = targets.maintain
                            case .bulk: vm.settings.calories = targets.bulk
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Поддержание") {
                            vm.settings.calories = targets.maintain
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Section("Goal") {
                    Picker("Цель", selection: $vm.settings.goal) {
                        ForEach(Goal.allCases) { g in
                            Text(g.title).tag(g)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Calories") {
                    Stepper(value: Binding(
                        get: { vm.settings.calories ?? 2000 },
                        set: { vm.settings.calories = $0 }
                    ), in: 1200...4500, step: 50) {
                        Text("Калории: \(vm.settings.calories ?? 2000)")
                    }
                }

                Section("Plan") {
                    Stepper("Дней: \(vm.settings.days)", value: $vm.settings.days, in: 1...7)
                    Stepper("Приёмов: \(vm.settings.mealsPerDay)", value: $vm.settings.mealsPerDay, in: 2...4)
                }

                Section("Restrictions") {
                    TextField("Аллергии / исключения", text: $vm.settings.restrictions, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Готово") {
                                    hideKeyboard()
                                }
                            }
                        }
                }

                Section {
                    Button {
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

                if let err = vm.appError {
                    Section("Ошибка") {
                        Text(err.localizedDescription)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Setup")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("History") {
                        HistoryView(vm: vm)
                    }
                }
            }
        }
    }
}
