import SwiftUI

public struct MainTabView: View {
    @EnvironmentObject private var state: AppState
    
    public init() {}
    
    public var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
            
            CharacterListView()
                .tabItem {
                    Label("Characters", systemImage: "person.crop.circle.fill")
                }
            
            MemoryView()
                .tabItem {
                    Label("Memory", systemImage: "brain.head.profile")
                }
            
            TerminalView()
                .tabItem {
                    Label("Terminal", systemImage: "terminal.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
