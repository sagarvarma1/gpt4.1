import SwiftUI

struct HistorySheetView: View {
    @ObservedObject var historyManager: HistoryManager
    @Binding var currentSession: ChatSession
    @Binding var isPresented: Bool // Binding to control sheet presentation

    // Date formatter for session creation date
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationView { // Embed in NavigationView for title and potential toolbar
            VStack(spacing: 0) {
                // List of sessions
                List {
                    ForEach(historyManager.sessions) { session in
                        Button {
                            if currentSession.id != session.id {
                                // No need to save here, ChatView handles saving
                                currentSession = session
                                print("Switched to session \(session.id)")
                            }
                            isPresented = false // Dismiss the sheet
                        } label: {
                            VStack(alignment: .leading) {
                                Text(sessionTitle(for: session))
                                    .lineLimit(1)
                                    .font(.headline)
                                    // Highlight the selected session
                                    .foregroundColor(currentSession.id == session.id ? Color.accentColor : Color.primary)
                                Text("Created: \(session.createdAt, formatter: dateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("Last Modified: \(session.lastModified, formatter: dateFormatter)")
                                     .font(.caption)
                                     .foregroundColor(.gray)

                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                             Button(role: .destructive) {
                                 // If the deleted session is the current one, we might need to select another
                                 let deletedSessionId = session.id
                                 historyManager.deleteSession(withId: session.id)

                                 // If the active session was deleted, load the newest remaining session
                                 if currentSession.id == deletedSessionId {
                                     if let newestSession = historyManager.sessions.first {
                                         currentSession = newestSession
                                     } else {
                                         // If no sessions left, we could ideally trigger 'startNewChat'
                                         // but that action lives in ChatView.
                                         // For now, just dismiss. ChatView might need adjustment later
                                         // if deleting the *only* session causes issues.
                                         print("Last session deleted. Sheet dismissed.")
                                         isPresented = false
                                     }
                                 }
                             } label: {
                                 Label("Delete", systemImage: "trash")
                             }
                         }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }

    // Helper to generate a title for the session (similar to SidebarView)
    private func sessionTitle(for session: ChatSession) -> String {
        if let firstUserMessage = session.messages.first(where: { $0.role == .user })?.content {
            return firstUserMessage
        } else if let firstMessage = session.messages.first?.content {
             return firstMessage // Fallback to any first message
        } else {
            return "Empty Chat" // Default if empty
        }
    }
}

// Basic Preview Provider (optional)
struct HistorySheetView_Previews: PreviewProvider {
    // Helper struct for preview state
    struct PreviewWrapper: View {
        @StateObject var manager: HistoryManager
        @State var previewSession: ChatSession
        @State var isShowing = true // Start showing for preview

        init() {
            let tempManager = HistoryManager()
            let date1 = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let date2 = Calendar.current.date(byAdding: .minute, value: -30, to: Date())!
            tempManager.sessions = [
                ChatSession(messages: [ChatMessage(role: .user, content: "Preview Message 1")], provider: "Preview", createdAt: date1, lastModified: date1),
                ChatSession(messages: [ChatMessage(role: .user, content: "Another Longer Preview Message Example")], provider: "Preview", createdAt: date2, lastModified: Date()),
                ChatSession(provider: "Preview") // Empty one
            ]
            tempManager.sessions.sort { $0.createdAt > $1.createdAt }
            _manager = StateObject(wrappedValue: tempManager)
            _previewSession = State(initialValue: tempManager.sessions.first ?? ChatSession(provider: "Default"))
        }

        var body: some View {
            // Simulate being presented as a sheet
            Text("Background View")
                .sheet(isPresented: $isShowing) {
                    HistorySheetView(historyManager: manager,
                                     currentSession: $previewSession,
                                     isPresented: $isShowing)
                 }
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
} 