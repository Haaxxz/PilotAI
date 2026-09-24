import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    @Published public var conversations: [Conversation] = []
    @Published public var selectedConversationId: String? = nil
    @Published public var providers: [ModelProvider] = []
    @Published public var characters: [Character] = []
    @Published public var memory: MemoryDocument = .default
    @Published public var settings: AppSettings = AppSettings()
    @Published public var isGenerating: Bool = false
    @Published public var terminalOutput: [String] = [
        "PilotAI Interactive Shell [iOS Environment]",
        "Type 'help' or any command to simulate execution.",
        "Persistent session active.\n"
    ]
    
    private let storage = StorageService.shared
    private let engine = AgentEngine.shared
    
    public init() {
        self.conversations = storage.loadConversations()
        self.providers = storage.loadProviders()
        self.characters = storage.loadCharacters()
        self.memory = storage.loadMemory()
        self.settings = storage.loadSettings()
        
        if let first = conversations.first {
            self.selectedConversationId = first.id
        } else {
            newConversation()
        }
    }
    
    public var selectedConversation: Conversation? {
        get {
            guard let id = selectedConversationId else { return conversations.first }
            return conversations.first(where: { $0.id == id }) ?? conversations.first
        }
        set {
            if let val = newValue, let index = conversations.firstIndex(where: { $0.id == val.id }) {
                conversations[index] = val
                storage.saveConversations(conversations)
            }
        }
    }
    
    public var currentProvider: ModelProvider? {
        guard let conv = selectedConversation else {
            return providers.first(where: { $0.id == settings.defaultProviderId }) ?? providers.first
        }
        return providers.first(where: { $0.id == conv.providerId }) ?? providers.first
    }
    
    public var currentCharacter: Character? {
        guard let conv = selectedConversation, let charId = conv.characterId else { return nil }
        return characters.first(where: { $0.id == charId })
    }
    
    // MARK: - Actions
    
    public func newConversation(mode: ConversationMode = .agent, characterId: String? = nil) {
        let provider = providers.first(where: { $0.id == settings.defaultProviderId }) ?? providers.first ?? ModelProvider.defaults[0]
        let model = provider.defaultModelId
        
        var initialMessages: [Message] = []
        var title = "New Conversation"
        
        if let charId = characterId, let char = characters.first(where: { $0.id == charId }) {
            title = "\(char.name) Chat"
            if !char.greeting.isEmpty {
                initialMessages.append(Message(role: .assistant, content: char.greeting, modelName: model))
            }
        }
        
        let newConv = Conversation(
            title: title,
            messages: initialMessages,
            providerId: provider.id,
            modelId: model,
            mode: mode,
            characterId: characterId
        )
        conversations.insert(newConv, at: 0)
        selectedConversationId = newConv.id
        storage.saveConversations(conversations)
    }
    
    public func deleteConversation(id: String) {
        conversations.removeAll(where: { $0.id == id })
        if selectedConversationId == id {
            selectedConversationId = conversations.first?.id
        }
        storage.saveConversations(conversations)
    }
    
    public func sendMessage(_ text: String) {
        guard let conv = selectedConversation, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let prov = currentProvider else { return }
        
        let userMsg = Message(role: .user, content: text)
        var updatedMessages = conv.messages
        updatedMessages.append(userMsg)
        
        // Auto update title on first message
        var title = conv.title
        if conv.messages.filter({ $0.role == .user }).isEmpty {
            title = String(text.prefix(28)).trimmingCharacters(in: .whitespacesAndNewlines)
            if title.isEmpty { title = "Conversation" }
        }
        
        var updatedConv = conv
        updatedConv.title = title
        updatedConv.messages = updatedMessages
        updatedConv.updatedAt = Date()
        selectedConversation = updatedConv
        
        isGenerating = true
        
        engine.send(
            prompt: text,
            conversation: updatedConv,
            provider: prov,
            character: currentCharacter,
            memory: memory,
            onUpdate: { [weak self] streamingMsg in
                guard let self = self else { return }
                var currentList = self.selectedConversation?.messages ?? []
                if let last = currentList.last, last.role == .assistant && last.isStreaming {
                    currentList[currentList.count - 1] = streamingMsg
                } else {
                    currentList.append(streamingMsg)
                }
                self.selectedConversation?.messages = currentList
            },
            onCompletion: { [weak self] result in
                guard let self = self else { return }
                self.isGenerating = false
                self.storage.saveConversations(self.conversations)
            }
        )
    }
    
    public func stopGenerating() {
        engine.stop()
        isGenerating = false
        if var conv = selectedConversation, let last = conv.messages.last, last.isStreaming {
            var updated = last
            updated.isStreaming = false
            conv.messages[conv.messages.count - 1] = updated
            selectedConversation = conv
        }
    }
    
    public func runTerminalCommand(_ cmd: String) {
        terminalOutput.append("$ \(cmd)")
        let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        switch trimmed {
        case "help":
            terminalOutput.append("Available commands: help, info, clear, models, status, uname, date")
        case "info":
            terminalOutput.append("PilotAI Mobile Agent Engine v3.0.5 (iOS arm64)")
            terminalOutput.append("Bundle ID: com.pilotai")
        case "clear":
            terminalOutput.removeAll()
        case "models":
            for p in providers {
                terminalOutput.append("Provider: \(p.name) (\(p.models.count) models)")
            }
        case "status":
            terminalOutput.append("Memory Active: \(memory.isAutoInjectEnabled ? "YES" : "NO")")
            terminalOutput.append("Conversations Count: \(conversations.count)")
        case "uname":
            terminalOutput.append("Darwin Kernel arm64 iOS / PilotAI-Sandboxed")
        case "date":
            terminalOutput.append(Date().description)
        default:
            terminalOutput.append("pilot: command executed: '\(cmd)'")
        }
        terminalOutput.append("")
    }
    
    public func saveMemory(_ newDoc: MemoryDocument) {
        self.memory = newDoc
        storage.saveMemory(newDoc)
    }
    
    public func saveProviders() {
        storage.saveProviders(providers)
    }
    
    public func saveSettings() {
        storage.saveSettings(settings)
    }
    
    public func saveCharacters() {
        storage.saveCharacters(characters)
    }
}
