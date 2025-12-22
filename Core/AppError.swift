//
//  AppError.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import Foundation

enum AppError: LocalizedError, Equatable {
    case network(String)
    case badResponse
    case decode(String)
    case aiInvalid(String)
    case storage(String)

    var errorDescription: String? {
        switch self {
        case .network(let msg): return "Сеть: \(msg)"
        case .badResponse: return "Некорректный ответ сервера"
        case .decode(let msg): return "Ошибка разбора данных: \(msg)"
        case .aiInvalid(let msg): return "AI вернул неверные данные: \(msg)"
        case .storage(let msg): return "Хранилище: \(msg)"
        }
    }
}
