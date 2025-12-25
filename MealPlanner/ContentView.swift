//
//  ContentView.swift
//  MealPlanner
//

import SwiftUI
import AppTrackingTransparency
import AdSupport

struct ContentView: View {
    @State private var vm = PlannerViewModel()

    // чтобы ATT и первичная загрузка рекламы делались один раз
    @AppStorage("didRequestATT") private var didRequestATT = false
    @AppStorage("didPreloadAds") private var didPreloadAds = false

    var body: some View {
        TabView {
            SetupView(vm: vm)
                .tabItem { Label("Setup", systemImage: "slider.horizontal.3") }

            NavigationStack { PlanView(vm: vm) }
                .tabItem { Label("Plan", systemImage: "fork.knife") }

            NavigationStack { HistoryView(vm: vm) }
                .tabItem { Label("History", systemImage: "clock") }
        }
        .onAppear {
            // ATT лучше дергать после появления UI + с задержкой
            requestATTIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .levelPlayInitSuccess)) { _ in
            // грузим рекламу только после успешного init
            preloadAdsIfNeeded()
        }
        .overlay {
            if vm.isGenerating {
                GenerationOverlay(progress: vm.progressValue, text: vm.progressText)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: vm.isGenerating)
    }

    private func requestATTIfNeeded() {
        guard !didRequestATT else { return }
        didRequestATT = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                print("ATT status:", status.rawValue)

                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                print("IDFA:", idfa)
            }
        }
    }

    private func preloadAdsIfNeeded() {
        guard !didPreloadAds else { return }
        didPreloadAds = true

        AdsManager.shared.loadInterstitial()
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let levelPlayInitSuccess = Notification.Name("levelPlayInitSuccess")
}
