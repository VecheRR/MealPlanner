//
//  AppConfig.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import Foundation

enum AppConfig {
    static let openAIKey: String = {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
            !key.isEmpty
        else {
            fatalError("OPENAI_API_KEY not found in Info.plist")
        }
        return key
    }()
}
