import Foundation

public enum MessageRole: String, Codable, CaseIterable {
    case system = "system"
    case user = "user"
    case assistant = "assistant"
    case tool = "tool"
}

public struct ToolCall: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let arguments: String
    public var output: String?
    public var isExecuting: Bool
    
    public init(id: String = UUID().uuidString, name: String, arguments: String, output: String? = nil, isExecuting: Bool = false) {
        self.id = id
        self.name = name
        self.arguments = arguments
        self.output = output
        self.isExecuting = isExecuting
    }
}

public struct Message: Identifiable, Codable, Equatable {
    public let id: String
    public let role: MessageRole
    public var content: String
    public var reasoningContent: String?
    public var toolCalls: [ToolCall]?
    public var isStreaming: Bool
    public let timestamp: Date
    public var modelName: String?
    
    public init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String,
        reasoningContent: String? = nil,
        toolCalls: [ToolCall]? = nil,
        isStreaming: Bool = false,
        timestamp: Date = Date(),
        modelName: String? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.reasoningContent = reasoningContent
        self.toolCalls = toolCalls
        self.isStreaming = isStreaming
        self.timestamp = timestamp
        self.modelName = modelName
    }
}
