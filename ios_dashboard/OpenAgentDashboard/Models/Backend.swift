//
//  Backend.swift
//  OpenAgentDashboard
//
//  Backend data models for OpenCode, Claude Code, and Amp
//

import Foundation

/// Represents an available backend (OpenCode, Claude Code, Amp)
struct Backend: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    
    static let opencode = Backend(id: "opencode", name: "OpenCode")
    static let claudecode = Backend(id: "claudecode", name: "Claude Code")
    static let amp = Backend(id: "amp", name: "Amp")
    
    /// Default backends when API is unavailable
    static let defaults: [Backend] = [.opencode, .claudecode, .amp]
}

/// Represents an agent within a backend
struct BackendAgent: Codable, Identifiable, Hashable {
    let id: String
    let name: String
}

/// Backend configuration including enabled state
struct BackendConfig: Codable {
    let id: String
    let name: String
    let enabled: Bool
    let settings: [String: AnyCodable]?
    
    /// Helper to check if backend is enabled (defaults to true if not specified)
    var isEnabled: Bool { enabled }
}

/// A provider of AI models (e.g., Anthropic, OpenAI)
struct Provider: Codable, Identifiable {
    let id: String
    let name: String
    let billing: BillingType
    let description: String
    let models: [ProviderModel]
    
    enum BillingType: String, Codable {
        case subscription
        case payPerToken = "pay-per-token"
    }
}

/// A model available from a provider
struct ProviderModel: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
}

/// Response wrapper for providers API
struct ProvidersResponse: Codable {
    let providers: [Provider]
}

/// Combined agent with backend info for display
struct CombinedAgent: Identifiable, Hashable {
    let backend: String
    let backendName: String
    let agent: String
    
    var id: String { "\(backend):\(agent)" }
    var value: String { "\(backend):\(agent)" }
    
    /// Parse a combined value back to backend and agent
    static func parse(_ value: String) -> (backend: String, agent: String)? {
        let parts = value.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        return (String(parts[0]), String(parts[1]))
    }
}

/// Wrapper for encoding arbitrary JSON values
struct AnyCodable: Codable, Hashable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
    
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simple equality for common types
        switch (lhs.value, rhs.value) {
        case let (l as Bool, r as Bool): return l == r
        case let (l as Int, r as Int): return l == r
        case let (l as Double, r as Double): return l == r
        case let (l as String, r as String): return l == r
        default: return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        if let bool = value as? Bool { hasher.combine(bool) }
        else if let int = value as? Int { hasher.combine(int) }
        else if let double = value as? Double { hasher.combine(double) }
        else if let string = value as? String { hasher.combine(string) }
    }
}
