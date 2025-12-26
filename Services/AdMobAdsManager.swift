//
//  AdMobAdsManager.swift
//  MealPlanner
//
//  Created by  Vladislav on 26.12.2025.
//

import Foundation
import GoogleMobileAds
import UIKit

final class AdMobAdsManager: NSObject {
    static let shared = AdMobAdsManager()
    private override init() {}

    private let bannerId = "ca-app-pub-3940256099942544/2934735716"
    private let interstitialId = "ca-app-pub-3940256099942544/4411468910"
    private let rewardedId = "ca-app-pub-3940256099942544/1712485313"
    private let rewardedInterstitialId = "ca-app-pub-3940256099942544/6978759866"
    private let appOpenId = "ca-app-pub-3940256099942544/5662855259"

    private var interstitial: GADInterstitialAd?
    private var rewarded: GADRewardedAd?
    private var rewardedInterstitial: GADRewardedInterstitialAd?
    private var appOpen: GADAppOpenAd?
    private var isLoadingAppOpen = false

    // MARK: - Helpers

    private func topVC() -> UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first,
            var top = window.rootViewController
        else { return nil }

        while let presented = top.presentedViewController { top = presented }
        return top
    }

    // MARK: - Load

    func loadAll() {
        loadInterstitial()
        loadRewarded()
        loadRewardedInterstitial()
        loadAppOpen()
    }

    func loadInterstitial() {
        GADInterstitialAd.load(withAdUnitID: interstitialId, request: GADRequest()) { [weak self] ad, error in
            if let error { print("❌ interstitial load:", error); return }
            self?.interstitial = ad
            print("✅ interstitial loaded")
        }
    }

    func loadRewarded() {
        GADRewardedAd.load(withAdUnitID: rewardedId, request: GADRequest()) { [weak self] ad, error in
            if let error { print("❌ rewarded load:", error); return }
            self?.rewarded = ad
            print("✅ rewarded loaded")
        }
    }

    func loadRewardedInterstitial() {
        GADRewardedInterstitialAd.load(withAdUnitID: rewardedInterstitialId, request: GADRequest()) { [weak self] ad, error in
            if let error { print("❌ rewarded interstitial load:", error); return }
            self?.rewardedInterstitial = ad
            print("✅ rewarded interstitial loaded")
        }
    }

    func loadAppOpen() {
        let request = GADRequest()

        GADAppOpenAd.load(withAdUnitID: appOpenId, request: request) { [weak self] ad, error in
            if let error {
                print("❌ app open load:", error)
                return
            }
            self?.appOpen = ad
            print("✅ app open loaded")
        }
    }
    
    // MARK: - Show

    func showInterstitial() {
        guard let ad = interstitial else { print("⚠️ interstitial not ready"); return }
        guard let vc = topVC() else { return }
        ad.present(fromRootViewController: vc)
        interstitial = nil
        loadInterstitial()
    }

    func showRewarded(onReward: @escaping (Int) -> Void) {
        guard let ad = rewarded else { print("⚠️ rewarded not ready"); return }
        guard let vc = topVC() else { return }

        ad.present(fromRootViewController: vc) {
            let amount = ad.adReward.amount.intValue
            print("✅ reward:", amount)
            onReward(amount)
        }

        rewarded = nil
        loadRewarded()
    }

    func showRewardedInterstitial(onReward: @escaping (Int) -> Void) {
        guard let ad = rewardedInterstitial else { print("⚠️ rewarded interstitial not ready"); return }
        guard let vc = topVC() else { return }

        ad.present(fromRootViewController: vc) {
            let amount = ad.adReward.amount.intValue
            onReward(amount)
        }

        rewardedInterstitial = nil
        loadRewardedInterstitial()
    }
    
    func showAppOpenIfReady() {
        guard let ad = appOpen else { return }
        guard let vc = topVC() else { return }
        ad.present(fromRootViewController: vc)
        appOpen = nil
        loadAppOpen()
    }

    // MARK: - Banner ID accessor
    func bannerUnitId() -> String { bannerId }
}
