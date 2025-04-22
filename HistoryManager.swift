import Foundation

class HistoryManager: ObservableObject {
    @Published var sessions: [ChatSession] = []
    private let fileURL: URL

    init() {
        // Get URL for documents directory
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        fileURL = urls[0].appendingPathComponent("chatHistory.json")
        loadSessions()
        print("History file URL: \(fileURL.path)") // For debugging
    }

    // Load sessions from the JSON file
    func loadSessions() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601 // Ensure dates are decoded correctly
                sessions = try decoder.decode([ChatSession].self, from: data)
                // Sort sessions by creation date, newest first
                sessions.sort { $0.createdAt > $1.createdAt }
            } else {
                sessions = [] // No history file yet
            }
        } catch {
            print("Error loading chat history: \(error)")
            sessions = [] // Reset on error
        }
    }

    // Save sessions to the JSON file
    func saveSessions() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601 // Ensure dates are encoded correctly
            encoder.outputFormatting = .prettyPrinted // Make JSON readable
            let data = try encoder.encode(sessions)
            try data.write(to: fileURL, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Error saving chat history: \(error)")
        }
    }

    // Add or update a session
    func saveSession(_ session: ChatSession) {
        var sessionToSave = session
        sessionToSave.lastModified = Date()
        if let index = sessions.firstIndex(where: { $0.id == sessionToSave.id }) {
            // Update existing session
            sessions[index] = sessionToSave
        } else {
            // Add new session
            sessions.insert(sessionToSave, at: 0) // Add to the beginning (newest first)
        }
        saveSessions() // Persist changes
    }

    // Delete a session (might need later)
    func deleteSession(withId id: UUID) {
        sessions.removeAll { $0.id == id }
        saveSessions()
    }
    
    // Create a new empty session
    func createNewSession(provider: String) -> ChatSession {
        let newSession = ChatSession(provider: provider)
        // Don't save it immediately, only save when a message is added or user explicitly saves/navigates away
        return newSession
    }
} 