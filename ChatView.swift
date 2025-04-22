import SwiftUI
// Combine no longer strictly needed unless used elsewhere
// import Combine

// ChatMessage struct and HistoryManager are defined elsewhere

struct ChatView: View {
    // Shared History Manager
    @StateObject private var historyManager = HistoryManager() // Standard initialization
    
    // Current state - Initialize with a temporary default
    @State private var currentSession: ChatSession 
    @State private var currentMessage: String = ""
    @State private var showingHistorySheet = false // State to control history sheet - RESTORED
    // @State private var showSidebar: Bool = false // TEMP DISABLED
    
    let provider: String

    // Initializer: Just set provider and a placeholder session
    init(provider: String) {
        self.provider = provider
        // Initialize state with a temporary session. .onAppear will load the correct one.
        _currentSession = State(initialValue: ChatSession(messages: [ChatMessage(role: .assistant, content: "Loading...")], provider: provider))
    }

    var body: some View {
        // let _ = print("DEBUG: ChatView body re-evaluated. Session ID: \\(currentSession.id), Message Count: \\(currentSession.messages.count)") // DEBUG - REMOVED
        // Use ZStack for layering sidebar and main content
        ZStack {
            // Main Chat View Content
            VStack(spacing: 0) {
                // DEBUG Text showing message count
                Text("Messages: \(currentSession.messages.count) - Session: \(currentSession.id.uuidString.prefix(8))")
                    .font(.caption)
                    .padding(4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(currentSession.messages) { message in
                            MessageView(message: message)
                                .id(message.id) // Ensure each message has a stable identity
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                .id(currentSession.id) // Force ScrollView to recreate when session changes
                .background(Color(.systemBackground))
                .onTapGesture {
                    hideKeyboard()
                }

                // Input area
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.gray)
                    }

                    TextField("Ask anything", text: $currentMessage)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                               .fill(Color(.systemGray6))
                        )

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(currentMessage.isEmpty ? Color.gray : Color.accentColor)
                            .clipShape(Circle())
                    }
                    .disabled(currentMessage.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            // .navigationTitle(provider) // Title could show session info later - REMOVED
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { 
                // Hamburger button toggles sidebar - RESTORED (but action is empty for now)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { 
                        // Action is intentionally empty for now - REVERTED - UPDATED AGAIN
                         // print("DEBUG: History/Hamburger button pressed (no action)") // Optional debug print
                         hideKeyboard() // Dismiss keyboard before showing sheet - RESTORED
                         showingHistorySheet = true // Set state to true to show the sheet - RESTORED
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.black)
                    }
                } 
                // Top-right button still starts a new chat directly - RESTORED
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: startNewChat) { 
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.black) 
                    }
                } 
            }
            .navigationBarBackButtonHidden(true)
            .onAppear { // Load initial session here
                 if let loadedSession = historyManager.sessions.first {
                    currentSession = loadedSession
                    print("ChatView onAppear loaded session: \(loadedSession.id.uuidString)")
                 } else {
                    currentSession = historyManager.createNewSession(provider: provider)
                    print("ChatView onAppear created new session: \(currentSession.id.uuidString)")
                 }
                 // Ensure historyManager reloads if needed (though it should load on init)
                 // historyManager.loadSessions() 
            }
            // Dimming overlay when sidebar is shown - TEMP DISABLED - REMOVED
            /* .overlay(
                Group {
                    if showSidebar {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation { showSidebar = false }
                            }
                    }
                }
            ) */
            // Disable interaction with main content when sidebar is visible - TEMP DISABLED - REMOVED
            // .disabled(showSidebar)

            // Sidebar View Layer - TEMP DISABLED - REMOVED
            /* if showSidebar {
                SidebarView(historyManager: historyManager,
                            currentSession: $currentSession,
                            showSidebar: $showSidebar,
                            startNewChatAction: self.startNewChat) // Pass the function
                    .frame(width: UIScreen.main.bounds.width * 0.75) // Sidebar width
                    .offset(x: showSidebar ? 0 : -UIScreen.main.bounds.width * 0.75) // Animate from left
                    .transition(.move(edge: .leading)) // Smooth transition
                    .frame(maxWidth: .infinity, alignment: .leading) // Align to left
                    .ignoresSafeArea() // RESTORED: Put back ignoresSafeArea
            } */
        }
        // .animation(.easeInOut, value: showSidebar) // Animate sidebar appearance/disappearance - TEMP DISABLED (showSidebar removed) - REMOVED
        // .statusBar(hidden: false) // REMOVED: Revert status bar change
        .sheet(isPresented: $showingHistorySheet) { // Add sheet modifier - RESTORED
            HistorySheetView(historyManager: historyManager, 
                             currentSession: $currentSession,
                             isPresented: $showingHistorySheet)
        }
    }
    
    // Function to start a new chat session (used by button & sidebar)
    func startNewChat() {
        print("Starting new chat...")
        // Save the current session *if* it has messages AND it exists in history - SIMPLIFIED/REMOVED
        /* if !currentSession.messages.isEmpty && historyManager.sessions.contains(where: { $0.id == currentSession.id }) {
            print("Saving previous session (ID: \\(currentSession.id)) before starting new one.")
            // No need to call save explicitly, it's saved on message add/bot response
        } else if !currentSession.messages.isEmpty {
             print("Saving newly started session (ID: \\(currentSession.id)) before starting new one.")
             historyManager.saveSession(currentSession) // Potentially problematic save call?
        } else {
            print("Previous session was empty or not saved yet, not saving.")
        } */
        
        // Create and set the new session
        let newSession = historyManager.createNewSession(provider: provider)
        currentSession = newSession // This is the key state update
        print("Created and set new session ID: \(newSession.id.uuidString)")

        // Clear the input field
        currentMessage = ""
    }

    // Updated sendMessage
    func sendMessage() {
        guard !currentMessage.isEmpty else { 
            // print("DEBUG: sendMessage called but message is empty.") // DEBUG REMOVED
            return 
        }
        // print("DEBUG: sendMessage called with message: \\(currentMessage)") // DEBUG REMOVED

        let userMessage = ChatMessage(role: .user, content: currentMessage)
        // print("DEBUG: Created userMessage with ID: \\(userMessage.id)") // DEBUG REMOVED
        currentSession.messages.append(userMessage)
        // print("DEBUG: Appended userMessage. currentSession message count: \\(currentSession.messages.count)") // DEBUG REMOVED
        
        let userInput = currentMessage // This is used later in the bot response, so we keep it
        currentMessage = ""
        hideKeyboard()
        
        // print("DEBUG: Attempting to save session ID: \\(currentSession.id)") // DEBUG REMOVED
        historyManager.saveSession(currentSession) // RESTORED
        // print("DEBUG: Saved session after user message. Session ID: \\(currentSession.id)") // DEBUG REMOVED

        // Simulate bot response - RESTORED
        // print("DEBUG: Dispatching bot response simulation...") // DEBUG REMOVED
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // print("DEBUG: Inside bot response dispatch block.") // DEBUG REMOVED
            let botResponseContent = "Response for: \"\\(userInput)\" (Provider: \\(provider))"
            let botMessage = ChatMessage(role: .assistant, content: botResponseContent)
             // print("DEBUG: Created botMessage with ID: \\(botMessage.id)") // DEBUG REMOVED
           
            // Check if the session is still the same one before appending response
            // print("DEBUG: Checking if session \\(currentSession.id) still matches user message session...") // DEBUG REMOVED
            if currentSession.messages.last?.id == userMessage.id {
                // print("DEBUG: Session matches. Appending bot message.") // DEBUG REMOVED
                currentSession.messages.append(botMessage)
                 // print("DEBUG: Appended botMessage. currentSession message count: \\(currentSession.messages.count)") // DEBUG REMOVED
                // print("DEBUG: Attempting to save session after bot message...") // DEBUG REMOVED
                historyManager.saveSession(currentSession) // RESTORED
                // print("DEBUG: Saved session after bot message. Session ID: \\(currentSession.id)") // DEBUG REMOVED
            } else {
                 // print("DEBUG: Session changed before bot could reply. Discarding response for session associated with user message ID \\(userMessage.id). Current session ID: \\(currentSession.id)") // DEBUG REMOVED
            }
        } 
    }

    // Scroll helper (unchanged)
    func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let lastMessageId = currentSession.messages.last?.id else { return }
        // Removed withAnimation here, relying on onChange animation
        proxy.scrollTo(lastMessageId, anchor: .bottom)
    }

    // Keyboard helper (unchanged)
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MessageView (unchanged from previous step)
struct MessageView: View {
    let message: ChatMessage 

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                Text(message.content)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            } else {
                Text(message.content)
                    .padding(12)
                     .background(Color(.systemGray5))
                     .foregroundColor(Color(.label))
                    .cornerRadius(16)
                Spacer()
            }
        }
    }
}

// Preview (unchanged)
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { 
             ChatView(provider: "Preview Provider")
        }
    }
} 

