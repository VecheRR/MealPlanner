////
////  OpenAIService.swift
////  MealPlanner
////
////  Created by  Vladislav on 20.12.2025.
////
//
//import Foundation
//
//struct OpenAIService {
//    private let apiKey = AppConfig.openAIKey
//
//    private struct ChatRequest: Codable {
//        struct Message: Codable {
//            let role: String
//            let content: String
//        }
//        let model: String
//        let temperature: Double
//        let messages: [Message]
//        let response_format: ResponseFormat?
//
//        struct ResponseFormat: Codable {
//            let type: String // "json_object"
//        }
//    }
//
//    private struct ChatResponse: Codable {
//        struct Choice: Codable {
//            struct Msg: Codable { let role: String; let content: String }
//            let message: Msg
//        }
//        let choices: [Choice]
//    }
//    
//    private struct OpenAIErrorEnvelope: Codable {
//        struct OpenAIError: Codable {
//            let message: String
//            let type: String?
//            let code: String?
//        }
//        let error: OpenAIError
//    }
//
//    // Генерим дни плана, которые потом кладём в MealPlan
//    func generatePlan(settings: PlannerSettings) async throws -> [PlanDay] {
//        let prompt = buildPrompt(settings: settings)
//
//        let reqBody = ChatRequest(
//            model: "gpt-4o-mini",
//            temperature: 0,
//            messages: [
//                .init(role: "system", content: "You output ONLY valid JSON. No markdown. No comments."),
//                .init(role: "user", content: prompt)
//            ],
//            response_format: .init(type: "json_object")
//        )
//
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
//            throw AppError.network("Bad URL")
//        }
//
//        var req = URLRequest(url: url)
//        req.httpMethod = "POST"
//        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        req.httpBody = try JSONEncoder().encode(reqBody)
//
//        let (data, resp) = try await URLSession.shared.data(for: req)
//        guard let http = resp as? HTTPURLResponse else { throw AppError.badResponse }
//
//        guard http.statusCode == 200 else {
//            if let env = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data) {
//                // Приведём к нормальной форме
//                if env.error.code == "insufficient_quota" {
//                    throw AppError.network("OpenAI: нет квоты. Подключи биллинг/пополни баланс в OpenAI Platform.")
//                } else {
//                    throw AppError.network("OpenAI: \(env.error.message)")
//                }
//            } else {
//                throw AppError.network("OpenAI HTTP \(http.statusCode)")
//            }
//        }
//
//        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
//        guard let content = decoded.choices.first?.message.content else {
//            throw AppError.aiInvalid("Empty response")
//        }
//
//        // Content должен быть JSON-объектом { "days": [...] }
//        struct Payload: Codable { let days: [PlanDay] }
//        do {
//            let payload = try JSONDecoder().decode(Payload.self, from: Data(content.utf8))
//            validate(payload.days, settings: settings)
//            return payload.days
//        } catch {
//            throw AppError.aiInvalid("Bad JSON: \(error.localizedDescription)\n\(content)")
//        }
//    }
//
//    private func buildPrompt(settings: PlannerSettings) -> String {
//        let goal = settings.goal.title
//        let cal = settings.calories.map(String.init) ?? "auto"
//        let mpd = settings.mealsPerDay
//        let days = settings.days
//        let restrictions = settings.restrictions.isEmpty ? "none" : settings.restrictions
//
//        return """
//        Create a meal plan for \(days) days.
//        Goal: \(goal)
//        Target calories per day: \(cal)
//        Meals per day: \(mpd)
//        Restrictions: \(restrictions)
//
//        Output JSON object with this exact schema:
//        {
//          "days": [
//            {
//              "dateISO": "YYYY-MM-DD",
//              "meals": [
//                {
//                  "type": "breakfast|lunch|dinner|snack",
//                  "title": "string",
//                  "kcal": 123,
//                  "protein_g": 10,
//                  "fat_g": 10,
//                  "carbs_g": 10,
//                  "search_terms": ["string", "string"]
//                }
//              ]
//            }
//          ]
//        }
//
//        Rules:
//        - dateISO must be consecutive starting from today.
//        - meals count per day must equal Meals per day.
//        - kcal/macros are integers.
//        - search_terms: 2-4 short queries for recipe API lookup.
//        - Keep it realistic and consistent with calories goal.
//        """
//    }
//
//    private func validate(_ days: [PlanDay], settings: PlannerSettings) {
//        guard days.count == settings.days else {
//            // не кидаем фатально, но лучше сразу ошибкой
//            // чтобы UI не падал дальше
//            return
//        }
//        for d in days {
//            if d.meals.count != settings.mealsPerDay {
//                // тоже можно throw, но проще поймать выше через aiInvalid:
//                // валидировать строго будем в декоде/проверке по месту
//            }
//        }
//    }
//}
