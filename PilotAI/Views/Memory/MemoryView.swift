import SwiftUI

public struct MemoryView: View {
    @EnvironmentObject private var state: AppState
    @State private var markdownText: String = ""
    @State private var autoInject: Bool = true
    @State private var showSaveAlert: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Configuration"), footer: Text("When enabled, this core memory block will be automatically injected into system prompts across all conversations.")) {
                    Toggle("Auto-Inject Memories", isOn: $autoInject)
                }
                
                Section(header: Text("Core Memories (Markdown)")) {
                    TextEditor(text: $markdownText)
                        .font(.system(size: 14, design: .monospaced))
                        .frame(minHeight: 280)
                }
                
                Section {
                    HStack {
                        Text("Characters")
                        Spacer()
                        Text("\(markdownText.count)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Estimated Tokens")
                        Spacer()
                        Text("~\(markdownText.count / 4)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Memory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updated = state.memory
                        updated.markdown = markdownText
                        updated.isAutoInjectEnabled = autoInject
                        updated.lastModified = Date()
                        state.saveMemory(updated)
                        showSaveAlert = true
                    }
                }
            }
            .onAppear {
                markdownText = state.memory.markdown
                autoInject = state.memory.isAutoInjectEnabled
            }
            .alert("Memory Saved", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your core memories are now active and synchronized.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
