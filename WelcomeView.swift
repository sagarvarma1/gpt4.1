import SwiftUI

struct WelcomeView: View {
    // @State private var selectedProvider = "OpenAI" // Removed state
    @State private var apiKey = ""
    // @State private var navigateToChat = false // Removed state for navigation
    // let providers = ["OpenAI", "Anthropic", "Google", "Mistral"] // Removed providers

    var body: some View {
        // Use NavigationStack for new navigation API
        NavigationStack {
            VStack(alignment: .center, spacing: 20) {
                Spacer()

                Text("Talk to GPT 4.1") // Updated title
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 40) // Increased padding
                    .multilineTextAlignment(.center)

                // Removed HStack with Picker

                Text("Enter your OpenAI API Key") // Added text label
                    .font(.headline)

                TextField("Enter API key", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                // NavigationLink using value:label: API
                NavigationLink(value: "GPT 4.1") { // Pass the provider name as the value
                    // The Button is now the label for the NavigationLink
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(apiKey.isEmpty ? Color.gray : Color.accentColor) // Use accent color when enabled
                        .foregroundColor(.white)
                        .cornerRadius(10) // Match default borderedProminent style
                        .fontWeight(.semibold) // Match default borderedProminent style
                }
                .disabled(apiKey.isEmpty) // Disable the link if API key is empty
                .padding(.horizontal) // Apply padding here
                .padding(.bottom) // Apply padding here
                // Removed the separate Button and hidden NavigationLink

                Spacer()
            }
            .padding()
            // .navigationTitle("Welcome") // Title not needed/visible if bar hidden
            .navigationBarHidden(true)
            // Add navigationDestination modifier for the String type
            .navigationDestination(for: String.self) { providerValue in
                ChatView(provider: providerValue)
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
} 