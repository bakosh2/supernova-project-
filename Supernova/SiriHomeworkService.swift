import Foundation

// MARK: - Generated Homework Models

struct GeneratedHomework: Codable, Equatable {
    let title: String
    let focusDuration: Int
    let breakDuration: Int
    let validityDays: Int
    let requiresCode: Bool
    let subtasks: [GeneratedSubtask]

    enum CodingKeys: String, CodingKey {
        case title
        case focusDuration = "focus_duration"
        case breakDuration = "break_duration"
        case validityDays = "validity_days"
        case requiresCode = "requires_code"
        case subtasks
    }
}

struct GeneratedSubtask: Codable, Equatable {
    let title: String
    let duration: Int
}

// MARK: - Local Pending Homework Storage Helper

enum PendingSiriHomework {
    static let key = "pendingSiriHomework"
    static let notificationName = Notification.Name("PendingSiriHomeworkDidSave")

    static func save(_ homework: GeneratedHomework) throws {
        let data = try JSONEncoder().encode(homework)
        UserDefaults.standard.set(data, forKey: key)
        NotificationCenter.default.post(name: notificationName, object: nil)
    }

    static func load() -> GeneratedHomework? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(GeneratedHomework.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - Stateless Siri Homework Network Service

struct SiriHomeworkService {
    private let baseURL = URL(string: "http://172.20.10.3:8000/siri-homework")!

    func generateHomework(description: String) async throws -> GeneratedHomework {
        let payload: [String: Any] = [
            "description": description,
            "current_task": NSNull(),
            "change": NSNull()
        ]
        return try await performRequest(payload: payload)
    }

    func reviseHomework(
        description: String,
        currentHomework: GeneratedHomework,
        change: String
    ) async throws -> GeneratedHomework {
        let encoder = JSONEncoder()
        guard let currentTaskData = try? encoder.encode(currentHomework),
              let currentTaskDict = try? JSONSerialization.jsonObject(with: currentTaskData) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        let payload: [String: Any] = [
            "description": description,
            "current_task": currentTaskDict,
            "change": change
        ]
        return try await performRequest(payload: payload)
    }

    private func performRequest(payload: [String: Any]) async throws -> GeneratedHomework {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(GeneratedHomework.self, from: data)
    }
}
