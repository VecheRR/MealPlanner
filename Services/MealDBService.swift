//
//  MealDBService.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import Foundation

struct MealDBService {
    struct MealDBMeal: Codable, Identifiable, Equatable {
        let idMeal: String
        let strMeal: String
        let strCategory: String?
        let strArea: String?
        let strMealThumb: String?
        let strInstructions: String?
        let strSource: String?
        let strYoutube: String?

        var id: String { idMeal }
    }

    private struct SearchResponse: Codable {
        let meals: [MealDBMeal]?
    }

    private let http = HTTPClient(policy: .init(maxAttempts: 4, baseDelay: 0.4, maxDelay: 6.0))

    func searchMeals(query: String) async throws -> [MealDBMeal] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return [] }

        var comps = URLComponents(string: "https://www.themealdb.com/api/json/v1/1/search.php")!
        comps.queryItems = [URLQueryItem(name: "s", value: q)]
        guard let url = comps.url else { throw AppError.network("Bad URL") }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 30

        let (data, resp) = try await http.request(req)

        guard resp.statusCode == 200 else {
            throw AppError.network("TheMealDB HTTP \(resp.statusCode)")
        }

        do {
            let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
            return decoded.meals ?? []
        } catch {
            throw AppError.decode(error.localizedDescription)
        }
    }
}
