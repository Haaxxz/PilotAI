import Foundation

public final class StorageService {
    public static let shared = StorageService()
    
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    public init() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc
        
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }
    
    // MARK: - Conversations
    private var conversationsFileURL: URL {
        documentsDirectory.appendingPathComponent("conversations.json")
    }
    
    public func loadConversations() -> [Conversation] {
        guard let data = try? Data(contentsOf: conversationsFileURL),
              let list = try? decoder.decode([Conversation].self, from: data) else {
            return [Conversation(title: "Getting Started with PilotAI", messages: [
                Message(role: .assistant, content: "Welcome to **PilotAI** for iOS! You can chat with cutting-edge models, use tools, create roleplay characters, and maintain persistent memory across conversations.")
            ])]
        }
        return list
    }
    
    public func saveConversations(_ conversations: [Conversation]) {
        if let data = try? encoder.encode(conversations) {
            try? data.write(to: conversationsFileURL, options: .atomic)
        }
    }
    
    // MARK: - Providers
    private var providersFileURL: URL {
        documentsDirectory.appendingPathComponent("providers.json")
    }
    
    public func loadProviders() -> [ModelProvider] {
        guard let data = try? Data(contentsOf: providersFileURL),
              let list = try? decoder.decode([ModelProvider].self, from: data) else {
            return ModelProvider.defaults
        }
        return list
    }
    
    public func saveProviders(_ providers: [ModelProvider]) {
        if let data = try? encoder.encode(providers) {
            try? data.write(to: providersFileURL, options: .atomic)
        }
    }
    
    // MARK: - Characters
    private var charactersFileURL: URL {
        documentsDirectory.appendingPathComponent("characters.json")
    }
    
    public func loadCharacters() -> [Character] {
        guard let data = try? Data(contentsOf: charactersFileURL),
              let list = try? decoder.decode([Character].self, from: data) else {
            return Character.defaults
        }
        return list
    }
    
    public func saveCharacters(_ characters: [Character]) {
        if let data = try? encoder.encode(characters) {
            try? data.write(to: charactersFileURL, options: .atomic)
        }
    }
    
    // MARK: - Memory
    private var memoryFileURL: URL {
        documentsDirectory.appendingPathComponent("memory.json")
    }
    
    public func loadMemory() -> MemoryDocument {
        guard let data = try? Data(contentsOf: memoryFileURL),
              let doc = try? decoder.decode(MemoryDocument.self, from: data) else {
            return MemoryDocument.default
        }
        return doc
    }
    
    public func saveMemory(_ memory: MemoryDocument) {
        if let data = try? encoder.encode(memory) {
            try? data.write(to: memoryFileURL, options: .atomic)
        }
    }
    
    // MARK: - Settings
    private var settingsFileURL: URL {
        documentsDirectory.appendingPathComponent("settings.json")
    }
    
    public func loadSettings() -> AppSettings {
        guard let data = try? Data(contentsOf: settingsFileURL),
              let set = try? decoder.decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return set
    }
    
    public func saveSettings(_ settings: AppSettings) {
        if let data = try? encoder.encode(settings) {
            try? data.write(to: settingsFileURL, options: .atomic)
        }
    }
    
    // MARK: - MCP Servers
    private var mcpServersFileURL: URL {
        documentsDirectory.appendingPathComponent("mcp_servers.json")
    }
    
    public func loadMcpServers() -> [McpServer] {
        guard let data = try? Data(contentsOf: mcpServersFileURL),
              let list = try? decoder.decode([McpServer].self, from: data) else {
            return []
        }
        return list
    }
    
    public func saveMcpServers(_ servers: [McpServer]) {
        if let data = try? encoder.encode(servers) {
            try? data.write(to: mcpServersFileURL, options: .atomic)
        }
    }
    
    // MARK: - Skills
    private var skillsFileURL: URL {
        documentsDirectory.appendingPathComponent("skills.json")
    }
    
    public func loadSkills() -> [Skill] {
        guard let data = try? Data(contentsOf: skillsFileURL),
              let list = try? decoder.decode([Skill].self, from: data) else {
            return Skill.defaults
        }
        return list
    }
    
    public func saveSkills(_ skills: [Skill]) {
        if let data = try? encoder.encode(skills) {
            try? data.write(to: skillsFileURL, options: .atomic)
        }
    }
}
