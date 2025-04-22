import Foundation

// Represents a single message in a chat
struct ChatMessage: Identifiable, Codable, Hashable {
    var id = UUID()
    let role: Role // user or assistant
    let content: String
    var timestamp: Date = Date()

    enum Role: String, Codable {
        case user
        case assistant
    }
    
    // Explicitly conform to Hashable based on id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Explicit Equatable conformance if needed (often implied by Hashable)
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// Represents a single chat session/conversation
struct ChatSession: Identifiable, Codable, Hashable {
    var id = UUID()
    var messages: [ChatMessage] = []
    var provider: String // e.g., "OpenAI"
    var createdAt: Date = Date()
    var lastModified: Date = Date()

    // Optional: Add a title or summary for the session later
    // var title: String?
    
    // Explicitly conform to Hashable based on id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Explicit Equatable conformance if needed
    static func == (lhs: ChatSession, rhs: ChatSession) -> Bool {
        lhs.id == rhs.id
    }
} 