import SwiftUI
// Combine no longer strictly needed unless used elsewhere
// import Combine

// ChatMessage struct and HistoryManager are defined elsewhere

struct ChatView: View {
    // Shared History Manager
    @StateObject private var historyManager = HistoryManager()
    
    // Current state
    @State private var currentSession: ChatSession
    @State private var currentMessage: String = ""
    @State private var showingHistorySheet = false // State to control history sheet
    // @State private var showSidebar: Bool = false // TEMP DISABLED
    
    let provider: String

    // Initializer loads the latest session or creates a new one
    init(provider: String) {
        self.provider = provider
        
        let manager = HistoryManager() // Temporary instance to load/create initial session
        let initialSession: ChatSession
        
        if let latestSession = manager.sessions.first {
            initialSession = latestSession
            print("Loaded latest session: \(latestSession.id)")
        } else {
            initialSession = manager.createNewSession(provider: provider)
            print("No existing sessions, created new one: \(initialSession.id)")
        }
        
        // Initialize the state AFTER self is available
        _currentSession = State(initialValue: initialSession)
        // Initialize the StateObject using the same temporary manager instance for consistency 
        // (though it will load sessions itself again, which is slightly redundant but harmless here)
        _historyManager = StateObject(wrappedValue: manager)
    }

    var body: some View {
        // Use ZStack for layering sidebar and main content
        ZStack {
            // Main Chat View Content
            VStack(spacing: 0) {
                ScrollView {
                    ScrollViewReader { scrollViewProxy in
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(currentSession.messages) { message in
                                MessageView(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        .onChange(of: currentSession.messages.count) { oldValue, newValue in
                            if newValue > oldValue {
                                scrollToBottom(scrollViewProxy)
                            }
                        }
                        // Scroll to bottom when session changes
                        .onChange(of: currentSession.id) { _, _ in
                            // Needs slight delay for view updates
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { 
                                scrollToBottom(scrollViewProxy)
                            }
                        }
                    }
                }
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
                        // Action is intentionally empty for now - UPDATED
                         // print("DEBUG: History/Hamburger button pressed (no action)") // Optional debug print
                         hideKeyboard() // Dismiss keyboard before showing sheet
                         showingHistorySheet = true // Set state to true to show the sheet
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
            .onAppear {
                 // Now initialization handles loading the latest session
                 print("ChatView appeared with session ID: \(currentSession.id)")
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
        .sheet(isPresented: $showingHistorySheet) { // Add sheet modifier
            HistorySheetView(historyManager: historyManager, 
                             currentSession: $currentSession,
                             isPresented: $showingHistorySheet)
        }
    }
    
    // Function to start a new chat session (used by button & sidebar)
    func startNewChat() {
        print("Starting new chat...")
        // Save the current session *if* it has messages AND it exists in history
        if !currentSession.messages.isEmpty && historyManager.sessions.contains(where: { $0.id == currentSession.id }) {
            print("Saving previous session (ID: \(currentSession.id)) before starting new one.")
            // No need to call save explicitly, it's saved on message add/bot response
        } else if !currentSession.messages.isEmpty {
             print("Saving newly started session (ID: \(currentSession.id)) before starting new one.")
             historyManager.saveSession(currentSession)
        } else {
            print("Previous session was empty or not saved yet, not saving.")
        }
        
        // Create and set the new session
        let newSession = historyManager.createNewSession(provider: provider)
        currentSession = newSession
        print("Created and set new session ID: \(currentSession.id)")
        
        // Clear the input field
        currentMessage = ""
        // Hide sidebar if it was open - REMOVED
        // if showSidebar {
        //     withAnimation { showSidebar = false }
        // }
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
        
        let userInput = currentMessage 
        currentMessage = ""
        hideKeyboard()
        
        // print("DEBUG: Attempting to save session ID: \\(currentSession.id)") // DEBUG REMOVED
        historyManager.saveSession(currentSession)
        // print("DEBUG: Saved session after user message. Session ID: \\(currentSession.id)") // DEBUG REMOVED

        // Simulate bot response
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
                historyManager.saveSession(currentSession)
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

