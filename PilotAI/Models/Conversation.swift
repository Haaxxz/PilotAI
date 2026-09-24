import Foundation

public enum ConversationMode: String, Codable, CaseIterable {
    case chat = "chat"
    case agent = "agent"
    case roleplay = "roleplay"
    
    public var title: String {
        switch self {
        case .chat: return "Direct Chat"
        case .agent: return "Autonomous Agent"
        case .roleplay: return "Roleplay Character"
        }
    }
    
    public var iconName: String {
        switch self {
        case .chat: return "message.fill"
        case .agent: return "cpu.fill"
        case .roleplay: return "person.crop.circle.fill"
        }
    }
}

public struct Conversation: Identifiable, Codable, Equatable {
    public let id: String
    public var title: String
    public var messages: [Message]
    public var providerId: String
    public var modelId: String
    public var mode: ConversationMode
    public var characterId: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        title: String = "New Conversation",
        messages: [Message] = [],
        providerId: String = "openai",
        modelId: String = "gpt-4o",
        mode: ConversationMode = .agent,
        characterId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.providerId = providerId
        self.modelId = modelId
        self.mode = mode
        self.characterId = characterId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
