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
    @Published public var mcpServers: [McpServer] = []
    @Published public var skills: [Skill] = Skill.defaults
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
        self.mcpServers = storage.loadMcpServers()
        self.skills = storage.loadSkills()
        
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
        if let conv = selectedConversation,
           let prov = providers.first(where: { $0.id == conv.providerId && $0.isEnabled }) {
            return prov
        }
        return providers.first(where: { $0.id == settings.defaultProviderId && $0.isEnabled })
            ?? providers.first(where: { $0.isEnabled })
            ?? providers.first
    }

    public func selectProvider(id: String) {
        guard let prov = providers.first(where: { $0.id == id }) else { return }
        let activeModelId = !prov.defaultModelId.isEmpty ? prov.defaultModelId : (prov.models.first?.id ?? "")
        selectModel(providerId: id, modelId: activeModelId)
    }

    public func selectModel(providerId: String, modelId: String) {
        settings.defaultProviderId = providerId
        settings.defaultModelId = modelId
        saveSettings()
        
        // Update default model inside the target provider
        if let pIdx = providers.firstIndex(where: { $0.id == providerId }) {
            providers[pIdx].defaultModelId = modelId
            storage.saveProviders(providers)
        }
        
        if var conv = selectedConversation {
            conv.providerId = providerId
            conv.modelId = modelId
            selectedConversation = conv
            if let idx = conversations.firstIndex(where: { $0.id == conv.id }) {
                conversations[idx] = conv
                storage.saveConversations(conversations)
            }
        }
    }
    
    public var currentCharacter: Character? {
        guard let conv = selectedConversation, let charId = conv.characterId else { return nil }
        return characters.first(where: { $0.id == charId })
    }
    
    // MARK: - Actions
    
    public func newConversation(mode: ConversationMode = .agent, characterId: String? = nil) {
        let provider = providers.first(where: { $0.id == settings.defaultProviderId && $0.isEnabled })
            ?? providers.first(where: { $0.isEnabled })
            ?? providers.first
            ?? ModelProvider.defaults[0]
            
        let model = provider.models.contains(where: { $0.id == settings.defaultModelId })
            ? settings.defaultModelId
            : (!provider.defaultModelId.isEmpty ? provider.defaultModelId : (provider.models.first?.id ?? ""))
        
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
    
    public func deleteMessage(id: String) {
        guard var conv = selectedConversation else { return }
        conv.messages.removeAll(where: { $0.id == id })
        selectedConversation = conv
        if let idx = conversations.firstIndex(where: { $0.id == conv.id }) {
            conversations[idx] = conv
            storage.saveConversations(conversations)
        }
    }
    
    public func rerunMessage(id: String) {
        guard var conv = selectedConversation else { return }
        guard let idx = conv.messages.firstIndex(where: { $0.id == id }) else { return }
        
        // Find preceding user prompt
        var userPrompt = ""
        for i in (0..<idx).reversed() {
            if conv.messages[i].role == .user {
                userPrompt = conv.messages[i].content
                break
            }
        }
        
        guard !userPrompt.isEmpty else { return }
        
        // Remove assistant message and any subsequent messages
        conv.messages.removeSubrange(idx..<conv.messages.count)
        selectedConversation = conv
        if let convIdx = conversations.firstIndex(where: { $0.id == conv.id }) {
            conversations[convIdx] = conv
            storage.saveConversations(conversations)
        }
        
        // Re-send prompt
        sendMessage(userPrompt)
    }
    
    @discardableResult
    public func undoUserMessage(id: String) -> String? {
        guard var conv = selectedConversation else { return nil }
        guard let idx = conv.messages.firstIndex(where: { $0.id == id }) else { return nil }
        
        let userText = conv.messages[idx].content
        
        // Remove from this user message onwards
        conv.messages.removeSubrange(idx..<conv.messages.count)
        selectedConversation = conv
        if let convIdx = conversations.firstIndex(where: { $0.id == conv.id }) {
            conversations[convIdx] = conv
            storage.saveConversations(conversations)
        }
        
        return userText
    }
    
    public func sendMessage(_ text: String, webSearchEnabled: Bool = false, reasoningEnabled: Bool = false) {
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
            webSearchEnabled: webSearchEnabled,
            reasoningEnabled: reasoningEnabled,
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
        
        if trimmed == "clear" {
            terminalOutput.removeAll()
            return
        }
        
        if settings.enableUnsandboxedGateway, let url = URL(string: settings.remoteGatewayURL.trimmingCharacters(in: .whitespacesAndNewlines)), !settings.remoteGatewayURL.isEmpty {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: String] = ["command": cmd]
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            Task { @MainActor in
                do {
                    let (data, _) = try await URLSession.shared.data(for: req)
                    if let str = String(data: data, encoding: .utf8) {
                        self.terminalOutput.append(str)
                    }
                } catch {
                    self.terminalOutput.append("Gateway Connection Error: \(error.localizedDescription)")
                }
                self.terminalOutput.append("")
            }
            return
        }
        
        switch trimmed {
        case "help":
            terminalOutput.append("Available commands: help, info, clear, models, status, uname, date")
        case "info":
            terminalOutput.append("PilotAI Mobile Agent Engine v3.0.5 (iOS arm64)")
            terminalOutput.append("Bundle ID: com.pilotai")
        case "models":
            for p in providers {
                terminalOutput.append("Provider: \(p.name) (\(p.models.count) models)")
            }
        case "status":
            terminalOutput.append("Memory Active: \(memory.isAutoInjectEnabled ? "YES" : "NO")")
            terminalOutput.append("Conversations Count: \(conversations.count)")
            terminalOutput.append("Unsandboxed Gateway: \(settings.enableUnsandboxedGateway ? "ACTIVE" : "DISABLED")")
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
    
    public func addProvider(_ provider: ModelProvider) {
        providers.append(provider)
        storage.saveProviders(providers)
    }

    public func deleteProvider(id: String) {
        providers.removeAll(where: { $0.id == id })
        storage.saveProviders(providers)
    }

    public func duplicateProvider(id: String) {
        guard let source = providers.first(where: { $0.id == id }) else { return }
        var clone = source
        clone.id = UUID().uuidString
        clone.name = "\(source.name) (Copy)"
        clone.isBuiltIn = false
        providers.append(clone)
        storage.saveProviders(providers)
    }

    public func updateProvider(_ provider: ModelProvider) {
        if let idx = providers.firstIndex(where: { $0.id == provider.id }) {
            providers[idx] = provider
            storage.saveProviders(providers)
        }
    }

    public func resetProvider(id: String) {
        if let def = ModelProvider.defaults.first(where: { $0.id == id }),
           let idx = providers.firstIndex(where: { $0.id == id }) {
            var reset = def
            reset.apiKey = providers[idx].apiKey // preserve API key
            providers[idx] = reset
            storage.saveProviders(providers)
        }
    }

    public func addModel(to providerId: String, model: ModelDefinition) {
        if let idx = providers.firstIndex(where: { $0.id == providerId }) {
            providers[idx].models.append(model)
            storage.saveProviders(providers)
        }
    }

    public func updateModel(in providerId: String, model: ModelDefinition) {
        if let pIdx = providers.firstIndex(where: { $0.id == providerId }),
           let mIdx = providers[pIdx].models.firstIndex(where: { $0.id == model.id }) {
            providers[pIdx].models[mIdx] = model
            storage.saveProviders(providers)
        }
    }

    public func deleteModel(from providerId: String, modelId: String) {
        if let pIdx = providers.firstIndex(where: { $0.id == providerId }) {
            providers[pIdx].models.removeAll(where: { $0.id == modelId })
            storage.saveProviders(providers)
        }
    }

    public func fetchModels(for providerId: String) async {
        guard let provider = providers.first(where: { $0.id == providerId }) else { return }
        guard let url = URL(string: provider.baseURL.hasSuffix("/models") ? provider.baseURL : provider.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/models") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !provider.apiKey.isEmpty {
            request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        }
        for header in provider.customHeaders {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataArray = json["data"] as? [[String: Any]] {
                let fetched: [ModelDefinition] = dataArray.compactMap { obj in
                    guard let id = obj["id"] as? String else { return nil }
                    return ModelDefinition(id: id, name: id)
                }
                await MainActor.run {
                    if let pIdx = self.providers.firstIndex(where: { $0.id == providerId }) {
                        // Merge: keep existing custom models, add new ones
                        var existing = self.providers[pIdx].models
                        let existingIds = Set(existing.map { $0.id })
                        let newModels = fetched.filter { !existingIds.contains($0.id) }
                        existing.append(contentsOf: newModels)
                        self.providers[pIdx].models = existing
                        self.storage.saveProviders(self.providers)
                    }
                }
            }
        } catch {
            // silently fail, UI will show error
        }
    }

    public func addCharacter(_ char: Character) {
        characters.insert(char, at: 0)
        storage.saveCharacters(characters)
    }

    public func updateCharacter(_ char: Character) {
        if let idx = characters.firstIndex(where: { $0.id == char.id }) {
            characters[idx] = char
            storage.saveCharacters(characters)
        }
    }

    public func deleteCharacter(id: String) {
        characters.removeAll(where: { $0.id == id })
        storage.saveCharacters(characters)
    }

    public func addMcpServer(_ server: McpServer) {
        mcpServers.append(server)
        storage.saveMcpServers(mcpServers)
    }
    public func updateMcpServer(_ server: McpServer) {
        if let idx = mcpServers.firstIndex(where: { $0.id == server.id }) {
            mcpServers[idx] = server
            storage.saveMcpServers(mcpServers)
        }
    }
    public func deleteMcpServer(id: String) {
        mcpServers.removeAll(where: { $0.id == id })
        storage.saveMcpServers(mcpServers)
    }

    public func addSkill(_ skill: Skill) {
        skills.append(skill)
        storage.saveSkills(skills)
    }
    public func updateSkill(_ skill: Skill) {
        if let idx = skills.firstIndex(where: { $0.id == skill.id }) {
            skills[idx] = skill
            storage.saveSkills(skills)
        }
    }
    public func deleteSkill(id: String) {
        skills.removeAll(where: { $0.id == id })
        storage.saveSkills(skills)
    }
}
