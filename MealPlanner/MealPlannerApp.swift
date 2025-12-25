//
//  MealPlannerApp.swift
//  MealPlanner
//
//  Created by Vladislav on 20.12.2025.
//

import SwiftUI

import FirebaseCore
import FirebaseAnalytics

import AppMetricaCore
import AppsFlyerLib

import IronSource

final class AppDelegate: NSObject, UIApplicationDelegate, AppsFlyerLibDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 🔵 IronSource LevelPlay
        if let appKey = Bundle.main.object(forInfoDictionaryKey: "IRONSOURCE_APP_KEY") as? String {
            // Enable adapters debug logs during development
            LevelPlay.setAdaptersDebug(true)

            // Build LevelPlay init request with your app key
            let request = LPMInitRequest(appKey: appKey, userId: nil)

            // Initialize LevelPlay SDK
            LevelPlay.initWith(request) { config, error in
                if let error = error {
                    print("❌ LevelPlay init failed:", error.localizedDescription)
                } else {
                    print("✅ LevelPlay initialized. SDK version:", LevelPlay.sdkVersion())
                }
            }
        }

        // 🔥 Firebase
        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(true)

        // 🟡 AppMetrica
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "APPMETRICA_API_KEY") as? String,
           let config = AppMetricaConfiguration(apiKey: apiKey) {
            AppMetrica.activate(with: config)
        }

        // 🔵 AppsFlyer (только настройка)
        let af = AppsFlyerLib.shared()

        if let devKey = Bundle.main.object(forInfoDictionaryKey: "APPSFLYER_DEV_KEY") as? String {
            af.appsFlyerDevKey = devKey
        }

        if let appleAppId = Bundle.main.object(forInfoDictionaryKey: "APPLE_APP_ID") as? String {
            af.appleAppID = appleAppId
        }

        af.delegate = self
        af.isDebug = true // на время отладки

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // ✅ AppsFlyer стартуем тут
        AppsFlyerLib.shared().start()
    }

    // MARK: - AppsFlyer callbacks (для проверки)
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        print("✅ AppsFlyer conversion:", conversionInfo)
    }

    func onConversionDataFail(_ error: Error) {
        print("❌ AppsFlyer conversion error:", error)
    }
}

@main
struct MealPlannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
