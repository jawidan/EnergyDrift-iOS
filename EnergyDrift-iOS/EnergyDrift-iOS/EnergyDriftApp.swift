import FirebaseCore
import SwiftUI

@main
struct EnergyDriftApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
