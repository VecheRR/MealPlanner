//
//  HTTPClient.swift
//  MealPlanner
//
//  Created by  Vladislav on 23.12.2025.
//

import Foundation

struct HTTPClient {

    struct RetryPolicy {
        let maxAttempts: Int              // общее число попыток (1 = без ретраев)
        let baseDelay: TimeInterval       // стартовая задержка, например 0.5
        let maxDelay: TimeInterval        // потолок задержки, например 8.0

        init(maxAttempts: Int = 5, baseDelay: TimeInterval = 0.5, maxDelay: TimeInterval = 8.0) {
            self.maxAttempts = max(1, maxAttempts)
            self.baseDelay = max(0, baseDelay)
            self.maxDelay = max(baseDelay, maxDelay)
        }
    }

    private let session: URLSession
    private let policy: RetryPolicy

    init(session: URLSession = .shared, policy: RetryPolicy = .init()) {
        self.session = session
        self.policy = policy
    }

    func request(_ req: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var lastError: Error?

        for attempt in 1...policy.maxAttempts {
            do {
                let (data, resp) = try await session.data(for: req)
                guard let http = resp as? HTTPURLResponse else { throw AppError.badResponse }

                if shouldRetry(status: http.statusCode) && attempt < policy.maxAttempts {
                    let delay = retryDelay(response: http, attempt: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }

                return (data, http)
            } catch {
                lastError = error

                // retry только для “временных” сетевых ошибок
                if shouldRetry(error: error) && attempt < policy.maxAttempts {
                    let delay = backoffDelay(attempt: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }

                throw mapToAppError(error)
            }
        }

        throw mapToAppError(lastError ?? AppError.network("Unknown error"))
    }

    // MARK: - Retry rules

    private func shouldRetry(status: Int) -> Bool {
        if status == 429 { return true }
        if (500...599).contains(status) { return true }
        return false
    }

    private func shouldRetry(error: Error) -> Bool {
        // URLSession/URLError: временные проблемы, которые обычно лечатся ретраем
        if let urlErr = error as? URLError {
            switch urlErr.code {
            case .timedOut,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .networkConnectionLost,
                 .dnsLookupFailed,
                 .notConnectedToInternet,
                 .internationalRoamingOff,
                 .callIsActive,
                 .dataNotAllowed:
                return true
            default:
                return false
            }
        }
        return false
    }

    // MARK: - Delays

    private func retryDelay(response: HTTPURLResponse, attempt: Int) -> TimeInterval {
        // Если сервер прислал Retry-After — уважаем его
        if let ra = parseRetryAfter(response: response) {
            return min(ra, policy.maxDelay)
        }
        return backoffDelay(attempt: attempt)
    }

    private func backoffDelay(attempt: Int) -> TimeInterval {
        // exponential: base * 2^(attempt-1) + jitter
        let exp = policy.baseDelay * pow(2.0, Double(attempt - 1))
        let capped = min(exp, policy.maxDelay)

        // jitter 0…0.25*delay (чтобы не долбиться синхронно)
        let jitter = Double.random(in: 0...(capped * 0.25))
        return capped + jitter
    }

    private func parseRetryAfter(response: HTTPURLResponse) -> TimeInterval? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After")?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }

        // 1) секунды
        if let seconds = TimeInterval(value) {
            return max(0, seconds)
        }

        // 2) дата HTTP (RFC1123) — грубо, но работает
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss zzz"

        if let date = df.date(from: value) {
            return max(0, date.timeIntervalSinceNow)
        }

        return nil
    }

    // MARK: - Error mapping

    private func mapToAppError(_ error: Error) -> AppError {
        if let e = error as? AppError { return e }
        return .network(error.localizedDescription)
    }
}
