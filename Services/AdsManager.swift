//
//  AdsManager.swift
//  MealPlanner
//
//  Created by  Vladislav on 25.12.2025.
//

import Foundation
import UIKit
import IronSource

@MainActor
final class AdsManager: NSObject {

    static let shared = AdsManager()

    private let interstitial: LPMInterstitialAd

    private override init() {
        guard let adUnitId = Bundle.main.object(
            forInfoDictionaryKey: "IRON_SOURCE_INTERSTITIAL_AD_UNIT_ID"
        ) as? String else {
            fatalError("❌ IRON_SOURCE_INTERSTITIAL_AD_UNIT_ID not found in Info.plist")
        }

        self.interstitial = LPMInterstitialAd(adUnitId: adUnitId)
        super.init()

        interstitial.setDelegate(self)

        print("🟦 Interstitial AdUnitID:", adUnitId)
    }

    // MARK: - Public API

    func loadInterstitial() {
        print("🟦 Interstitial loadAd()")
        interstitial.loadAd()
    }

    func showInterstitial() {
        guard interstitial.isAdReady() else {
            print("⚠️ Interstitial not ready")
            return
        }

        guard let vc = Self.topViewController() else {
            print("❌ No topViewController")
            return
        }

        print("🟦 Interstitial showAd()")
        interstitial.showAd(viewController: vc, placementName: "Placement name")
    }

    // MARK: - Helpers

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow }

        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

// MARK: - LPMInterstitialAdDelegate
extension AdsManager: LPMInterstitialAdDelegate {

    func didLoadAd(with adInfo: LPMAdInfo) {
        print("✅ Interstitial loaded")
    }

    func didFailToLoadAd(withAdUnitId adUnitId: String, error: Error) {
        print("❌ Interstitial load failed:", error.localizedDescription)
    }

    func didDisplayAd(with adInfo: LPMAdInfo) {
        print("👀 Interstitial displayed")
    }

    func didFailToDisplayAd(with adInfo: LPMAdInfo, error: Error) {
        print("❌ Interstitial display failed:", error.localizedDescription)
    }

    func didClickAd(with adInfo: LPMAdInfo) {
        print("🖱️ Interstitial clicked")
    }

    func didCloseAd(with adInfo: LPMAdInfo) {
        print("✖️ Interstitial closed")
    }
}
