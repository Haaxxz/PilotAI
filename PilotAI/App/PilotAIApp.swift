import SwiftUI

@main
public struct PilotAIApp: App {
    @StateObject private var appState = AppState()
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .preferredColorScheme(colorScheme)
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch appState.settings.theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
