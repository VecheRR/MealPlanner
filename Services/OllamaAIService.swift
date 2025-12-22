//
//  OllamaAIService.swift
//  MealPlanner
//
//  Created by  Vladislav on 20.12.2025.
//

import Foundation

struct OllamaAIService {
    private let baseURL = URL(string: "http://192.168.1.107:11434")!

    private struct GenerateRequest: Codable {
        let model: String
        let prompt: String
        let stream: Bool
        let options: Options

        struct Options: Codable {
            let temperature: Double
            let num_predict: Int
            let stop: [String]?
        }
    }

    private struct GenerateResponse: Codable {
        let response: String
    }
    
    private func normalizeDates(_ days: [PlanDay], settings: PlannerSettings) -> [PlanDay] {
        let count = max(1, min(settings.days, days.count))
        let today = Date()
        let cal = Calendar.current

        return (0..<count).map { i in
            let date = cal.date(byAdding: .day, value: i, to: today) ?? today
            let iso = isoDate(date)

            // берём существующий день, но переписываем dateISO
            let original = days[i]
            return PlanDay(id: original.id, dateISO: iso, meals: original.meals)
        }
    }

    func generatePlan(settings: PlannerSettings) async throws -> [PlanDay] {
        let prompt = buildPrompt(settings: settings)

        let reqBody = GenerateRequest(
            model: "qwen2.5:7b",
            prompt: prompt,
            stream: false,
            options: .init(
                temperature: 0,
                num_predict: 1200,
                stop: ["```"]
            )
        )

        let url = baseURL.appendingPathComponent("/api/generate")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(reqBody)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppError.network("Ollama HTTP error")
        }

        let decoded = try JSONDecoder().decode(GenerateResponse.self, from: data)
        let raw = decoded.response.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonText = extractJSONObject(raw) ?? raw

        struct Payload: Codable { let days: [PlanDay] }

        do {
            let payload = try JSONDecoder().decode(Payload.self, from: Data(jsonText.utf8))
            return normalizeDates(payload.days, settings: settings)
        } catch {
            throw AppError.aiInvalid("Ollama вернул невалидный JSON: \(error.localizedDescription)\n\(raw)")
        }
    }

    private func buildPrompt(settings: PlannerSettings) -> String {
        let goal = settings.goal.title
        let cal = settings.calories.map(String.init) ?? "auto"
        let mpd = settings.mealsPerDay
        let days = settings.days
        let restrictions = settings.restrictions.isEmpty ? "none" : settings.restrictions

        return """
        You are a strict JSON generator. Output ONLY valid JSON. No markdown, no comments.

        Create a meal plan for \(days) days.
        Goal: \(goal)
        Target calories per day: \(cal)
        Meals per day: \(mpd)
        Restrictions: \(restrictions)

        Output JSON object with this exact schema:
        {
          "days": [
            {
              "dateISO": "YYYY-MM-DD",
              "meals": [
                {
                  "type": "breakfast|lunch|dinner|snack",
                  "title": "string",
                  "kcal": 123,
                  "protein_g": 10,
                  "fat_g": 10,
                  "carbs_g": 10,
                  "search_terms": ["string", "string"]
                }
              ]
            }
          ]
        }

        Rules:
        - dateISO must be consecutive starting from today.
        - meals count per day must equal Meals per day.
        - kcal/macros are integers.
        - search_terms: 2-4 short terms for TheMealDB search.
        - Return only JSON.
        """
    }
    
    private func extractJSONObject(_ text: String) -> String? {
        guard let start = text.firstIndex(of: "{") else { return nil }

        var depth = 0
        var inString = false
        var escape = false

        var i = start
        while i < text.endIndex {
            let ch = text[i]

            if inString {
                if escape {
                    escape = false
                } else if ch == "\\" {
                    escape = true
                } else if ch == "\"" {
                    inString = false
                }
            } else {
                if ch == "\"" { inString = true }
                else if ch == "{" { depth += 1 }
                else if ch == "}" {
                    depth -= 1
                    if depth == 0 {
                        return String(text[start...i])
                    }
                }
            }

            i = text.index(after: i)
        }

        return nil // не нашли закрывающую }
    }
    
    private func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
