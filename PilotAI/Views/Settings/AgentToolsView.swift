import SwiftUI

public struct AgentToolsView: View {
    @EnvironmentObject private var state: AppState
    
    public init() {}
    
    public var body: some View {
        List {
            Section(header: Text("Built-in Agent Tools"), footer: Text("Enable or disable specific function-calling capabilities available to the LLM agent.")) {
                Toggle(isOn: $state.settings.enableWebSearchTool) {
                    Label("Web Search Tool", systemImage: "globe")
                }
                Toggle(isOn: $state.settings.enableTerminalTool) {
                    Label("Terminal Tool", systemImage: "terminal.fill")
                }
                Toggle(isOn: $state.settings.enableMemoryTool) {
                    Label("Memory Persistence Tool", systemImage: "brain.head.profile")
                }
                Toggle(isOn: $state.settings.enableFileAccessTool) {
                    Label("File Read / Write Tool", systemImage: "doc.text.fill")
                }
            }
        }
        .onChange(of: state.settings.enableWebSearchTool) { state.saveSettings() }
        .onChange(of: state.settings.enableTerminalTool) { state.saveSettings() }
        .onChange(of: state.settings.enableMemoryTool) { state.saveSettings() }
        .onChange(of: state.settings.enableFileAccessTool) { state.saveSettings() }
        .navigationTitle("Agent Tools")
        .navigationBarTitleDisplayMode(.inline)
    }
}
