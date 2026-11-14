import SwiftUI

@main
struct LibOSApp: App {
    @State private var state = AppState()
    var body: some Scene {
        WindowGroup {
            ContentView(state: state)
                .tint(Theme.navy)
                .preferredColorScheme(.light)
        }
    }
}
