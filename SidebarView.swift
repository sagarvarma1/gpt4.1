import SwiftUI

struct SidebarView: View {
    @ObservedObject var historyManager: HistoryManager
    @Binding var currentSession: ChatSession
    @Binding var showSidebar: Bool // To close the sidebar after selection

    var startNewChatAction: () -> Void // Closure to trigger new chat from ChatView

    // Date formatter for session creation date
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // e.g., "Jul 23, 2024"
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // Reduced spacing
            // Title remains - THIS SHOULD BE REMOVED
            /* Text("Chat History") 
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 10) // Add some bottom padding */

            // Removed the explicit "New Chat" Button row
            // Button { ... } label: { ... } // REMOVED

            // List of sessions
            List {
                ForEach(historyManager.sessions) { session in
                    Button {
                        if currentSession.id != session.id {
                            // Save current session only if it has messages and isn't already saved
                            if !currentSession.messages.isEmpty && !historyManager.sessions.contains(where: { $0.id == currentSession.id }) {
                                print("Saving session \(currentSession.id) before switching")
                                historyManager.saveSession(currentSession)
                            }
                             currentSession = session
                             print("Switched to session \(session.id)")
                        }
                        showSidebar = false
                    } label: {
                        VStack(alignment: .leading) {
                            Text(sessionTitle(for: session))
                                .lineLimit(1)
                                .font(.headline)
                                // Highlight the selected session
                                .foregroundColor(currentSession.id == session.id ? Color.accentColor : Color.primary)
                            // Display formatted creation date instead of relative lastModified
                            Text(session.createdAt, formatter: dateFormatter)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4) // Add some vertical padding to list items
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) { // Add swipe to delete
                         Button(role: .destructive) {
                             // Find the index of the session to delete
                             if let _ = historyManager.sessions.firstIndex(where: { $0.id == session.id }) { // Use _ as index is unused
                                 historyManager.deleteSession(withId: session.id)
                                 // If the deleted session was the current one, switch to the newest or create one
                                 if currentSession.id == session.id {
                                     if let newCurrent = historyManager.sessions.first {
                                         currentSession = newCurrent
                                     } else {
                                         // If no sessions left, create a new one
                                         startNewChatAction()
                                     }
                                 }
                             }
                         } label: {
                             Label("Delete", systemImage: "trash")
                         }
                     }
                }
            }
            .listStyle(.plain)

            // Spacer removed to allow list to fill space
            // Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
    }
    
    // Helper to generate a title for the session
    private func sessionTitle(for session: ChatSession) -> String {
        if let firstUserMessage = session.messages.first(where: { $0.role == .user })?.content {
            return firstUserMessage
        } else if let firstMessage = session.messages.first?.content {
             return firstMessage // Fallback to any first message
        } else {
            return "New Chat" // Default if empty
        }
    }
}

// Preview struct remains largely the same, just showing the effect of changes
struct SidebarView_Previews: PreviewProvider {
    // Helper struct to manage state within the static preview context
    struct PreviewWrapper: View {
        @StateObject var manager = HistoryManager()
        @State var previewSession: ChatSession
        @State var show = true

        init() {
            let tempManager = HistoryManager()
            // Add dates for testing formatting
            let date1 = Calendar.current.date(byAdding: .day, value: -1, to: Date())! // Yesterday
            let date2 = Calendar.current.date(byAdding: .minute, value: -30, to: Date())! // 30 mins ago
            let date3 = Calendar.current.date(byAdding: .day, value: -5, to: Date())! // 5 days ago
            
            tempManager.sessions = [
                ChatSession(messages: [ChatMessage(role: .user, content: "Hello there yesterday")], provider: "Preview", createdAt: date1, lastModified: date1),
                ChatSession(messages: [ChatMessage(role: .user, content: "Another chat example from 30 mins ago")], provider: "Preview", createdAt: date2, lastModified: Date()),
                ChatSession(provider: "Preview", createdAt: date3) // Empty one from 5 days ago
            ]
            // Sort them again after adding
             tempManager.sessions.sort { $0.createdAt > $1.createdAt }
            
            _manager = StateObject(wrappedValue: tempManager)
            _previewSession = State(initialValue: tempManager.sessions.first ?? ChatSession(provider: "Default"))
        }

        var body: some View {
             SidebarView(historyManager: manager,
                         currentSession: $previewSession,
                         showSidebar: $show,
                         startNewChatAction: { print("Preview: Start New Chat") })
                 .frame(width: 300) // Give it a typical sidebar width for preview
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
} 