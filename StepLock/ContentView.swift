import SwiftUI
import FamilyControls

struct ContentView: View {
    // Create and track the state of our ShieldManager
    @State private var shieldManager = ShieldManager.shared
    
    // A boolean to control when the app-picker popup shows up
    @State private var isPickerPresented = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Visual icon for the app
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("StepLock")
                .font(.largeTitle.bold())
            
            // Button to trigger the system's app selection window
            Button(action: { isPickerPresented = true }) {
                Label("Select Apps to Lock", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            // This is the Apple system-provided selection screen
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $shieldManager.selection)
            
            // Displays a live count of how many apps are currently selected
            Text("Selected \(shieldManager.selection.applicationTokens.count) Apps")
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
            // This runs as soon as the screen opens
            Task {
                // Request the user's permission to control Screen Time
                // Without this, the picker will not open
                try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            }
        }
    }
}

#Preview {
    ContentView()
}
