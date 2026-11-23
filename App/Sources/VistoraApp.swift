import AppFeature
import SwiftUI

@main
struct VistoraApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(initialState: Self.initialState)
        }
    }

    private static var initialState: AppFeature.State {
        #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if let index = arguments.firstIndex(of: "-vistora-scenario"),
                arguments.indices.contains(index + 1),
                arguments[index + 1] == "settings"
            {
                return AppFeature.State(settings: .init())
            }
        #endif
        return AppFeature.State()
    }
}
