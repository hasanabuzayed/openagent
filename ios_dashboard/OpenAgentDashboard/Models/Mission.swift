//
//  Mission.swift
//  OpenAgentDashboard
//
//  Mission and task data models
//

import Foundation

enum MissionStatus: String, Codable, CaseIterable {
    case active
    case completed
    case failed
    
    var statusType: StatusType {
        switch self {
        case .active: return .active
        case .completed: return .completed
        case .failed: return .failed
        }
    }
}

struct MissionHistoryEntry: Codable, Identifiable {
    var id: String { "\(role)-\(content.prefix(20))" }
    let role: String
    let content: String
    
    var isUser: Bool {
        role == "user"
    }
}

struct Mission: Codable, Identifiable, Hashable {
    let id: String
    var status: MissionStatus
    let title: String?
    let history: [MissionHistoryEntry]
    let createdAt: String
    let updatedAt: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Mission, rhs: Mission) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, status, title, history
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title.count > 60 ? String(title.prefix(60)) + "..." : title
        }
        return "Untitled Mission"
    }
    
    var updatedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: updatedAt) ?? ISO8601DateFormatter().date(from: updatedAt)
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case pending
    case running
    case completed
    case failed
    case cancelled
    
    var statusType: StatusType {
        switch self {
        case .pending: return .pending
        case .running: return .running
        case .completed: return .completed
        case .failed: return .failed
        case .cancelled: return .cancelled
        }
    }
}

struct TaskState: Codable, Identifiable {
    let id: String
    let status: TaskStatus
    let task: String
    let model: String
    let iterations: Int
    let result: String?
    
    var displayModel: String {
        if let lastPart = model.split(separator: "/").last {
            return String(lastPart)
        }
        return model
    }
}

struct Run: Codable, Identifiable {
    let id: String
    let createdAt: String
    let status: String
    let inputText: String
    let finalOutput: String?
    let totalCostCents: Int
    let summaryText: String?
    
    enum CodingKeys: String, CodingKey {
        case id, status
        case createdAt = "created_at"
        case inputText = "input_text"
        case finalOutput = "final_output"
        case totalCostCents = "total_cost_cents"
        case summaryText = "summary_text"
    }
    
    var costDollars: Double {
        Double(totalCostCents) / 100.0
    }
    
    var createdDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt) ?? ISO8601DateFormatter().date(from: createdAt)
    }
}
