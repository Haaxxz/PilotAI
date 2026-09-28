import Foundation

public enum ProviderType: String, Codable, CaseIterable {
    case openai = "openai"
    case anthropic = "anthropic"
    case deepseek = "deepseek"
    case kimi = "kimi"
    case alibaba = "alibaba"
    case minimax = "minimax"
    case siliconflow = "siliconflow"
    case openrouter = "openrouter"
    case local = "local"
    case custom = "custom"
    
    public var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .deepseek: return "DeepSeek"
        case .kimi: return "Kimi (Moonshot)"
        case .alibaba: return "Alibaba Bailian"
        case .minimax: return "MiniMax"
        case .siliconflow: return "SiliconFlow"
        case .openrouter: return "OpenRouter"
        case .local: return "Local (Ollama/LM Studio)"
        case .custom: return "Custom OpenAI-Compatible"
        }
    }
    
    public var defaultBaseURL: String {
        switch self {
        case .openai: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com/v1"
        case .deepseek: return "https://api.deepseek.com/v1"
        case .kimi: return "https://api.moonshot.cn/v1"
        case .alibaba: return "https://dashscope.aliyuncs.com/compatible-mode/v1"
        case .minimax: return "https://api.minimax.chat/v1"
        case .siliconflow: return "https://api.siliconflow.cn/v1"
        case .openrouter: return "https://openrouter.ai/api/v1"
        case .local: return "http://127.0.0.1:11434/v1"
        case .custom: return "https://api.openai.com/v1"
        }
    }
}

public struct ModelDefinition: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let supportsVision: Bool
    public let supportsReasoning: Bool
    public let contextWindow: Int
    public let contextWindowOverride: Int?
    public let sortOrder: Int
    
    public init(id: String, name: String, supportsVision: Bool = false, supportsReasoning: Bool = false, contextWindow: Int = 128_000, contextWindowOverride: Int? = nil, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.supportsVision = supportsVision
        self.supportsReasoning = supportsReasoning
        self.contextWindow = contextWindow
        self.contextWindowOverride = contextWindowOverride
        self.sortOrder = sortOrder
    }
}

public struct CustomHeader: Identifiable, Codable, Equatable {
    public var id: String = UUID().uuidString
    public var key: String
    public var value: String
    
    public init(id: String = UUID().uuidString, key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}

public struct ModelProvider: Identifiable, Codable, Equatable {
    public let id: String
    public var name: String
    public var type: ProviderType
    public var baseURL: String
    public var apiKey: String
    public var defaultModelId: String
    public var models: [ModelDefinition]
    public var customHeaders: [CustomHeader]
    public var isEnabled: Bool
    public var isBuiltIn: Bool
    public var systemPrompt: String
    public var endpointMode: String
    public var hostedWebSearchEnabled: Bool
    public var anthropicVersion: String
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: ProviderType,
        baseURL: String? = nil,
        apiKey: String = "",
        defaultModelId: String,
        models: [ModelDefinition] = [],
        customHeaders: [CustomHeader] = [],
        isEnabled: Bool = true,
        isBuiltIn: Bool = false,
        systemPrompt: String = "",
        endpointMode: String = "chat_completions",
        hostedWebSearchEnabled: Bool = false,
        anthropicVersion: String = "2023-06-01"
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.baseURL = baseURL ?? type.defaultBaseURL
        self.apiKey = apiKey
        self.defaultModelId = defaultModelId
        self.models = models
        self.customHeaders = customHeaders
        self.isEnabled = isEnabled
        self.isBuiltIn = isBuiltIn
        self.systemPrompt = systemPrompt
        self.endpointMode = endpointMode
        self.hostedWebSearchEnabled = hostedWebSearchEnabled
        self.anthropicVersion = anthropicVersion
    }
    
    public static var defaults: [ModelProvider] {
        [
            ModelProvider(
                id: "openai",
                name: "OpenAI",
                type: .openai,
                defaultModelId: "gpt-4o",
                models: [
                    ModelDefinition(id: "gpt-4o", name: "GPT-4o", supportsVision: true, supportsReasoning: false, contextWindow: 128_000),
                    ModelDefinition(id: "gpt-4o-mini", name: "GPT-4o Mini", supportsVision: true, supportsReasoning: false, contextWindow: 128_000),
                    ModelDefinition(id: "o1", name: "o1 Reasoning", supportsVision: true, supportsReasoning: true, contextWindow: 200_000),
                    ModelDefinition(id: "o3-mini", name: "o3-mini", supportsVision: false, supportsReasoning: true, contextWindow: 200_000)
                ],
                isBuiltIn: true
            ),
            ModelProvider(
                id: "anthropic",
                name: "Anthropic",
                type: .anthropic,
                defaultModelId: "claude-3-5-sonnet-latest",
                models: [
                    ModelDefinition(id: "claude-3-5-sonnet-latest", name: "Claude 3.5 Sonnet", supportsVision: true, supportsReasoning: true, contextWindow: 200_000),
                    ModelDefinition(id: "claude-3-5-haiku-latest", name: "Claude 3.5 Haiku", supportsVision: true, supportsReasoning: false, contextWindow: 200_000),
                    ModelDefinition(id: "claude-3-opus-latest", name: "Claude 3 Opus", supportsVision: true, supportsReasoning: false, contextWindow: 200_000)
                ],
                isBuiltIn: true
            ),
            ModelProvider(
                id: "deepseek",
                name: "DeepSeek",
                type: .deepseek,
                defaultModelId: "deepseek-chat",
                models: [
                    ModelDefinition(id: "deepseek-chat", name: "DeepSeek-V3", supportsVision: false, supportsReasoning: false, contextWindow: 64_000),
                    ModelDefinition(id: "deepseek-reasoner", name: "DeepSeek-R1", supportsVision: false, supportsReasoning: true, contextWindow: 64_000)
                ],
                isBuiltIn: true
            ),
            ModelProvider(
                id: "kimi",
                name: "Kimi",
                type: .kimi,
                defaultModelId: "moonshot-v1-auto",
                models: [
                    ModelDefinition(id: "moonshot-v1-auto", name: "Moonshot v1 Auto", supportsVision: false, supportsReasoning: false, contextWindow: 128_000),
                    ModelDefinition(id: "moonshot-v1-8k", name: "Moonshot v1 8K", supportsVision: false, supportsReasoning: false, contextWindow: 8_000),
                    ModelDefinition(id: "moonshot-v1-32k", name: "Moonshot v1 32K", supportsVision: false, supportsReasoning: false, contextWindow: 32_000),
                    ModelDefinition(id: "moonshot-v1-128k", name: "Moonshot v1 128K", supportsVision: false, supportsReasoning: false, contextWindow: 128_000)
                ],
                isBuiltIn: true
            ),
            ModelProvider(
                id: "openrouter",
                name: "OpenRouter",
                type: .openrouter,
                defaultModelId: "anthropic/claude-3.5-sonnet",
                models: [
                    ModelDefinition(id: "anthropic/claude-3.5-sonnet", name: "Claude 3.5 Sonnet", supportsVision: true, supportsReasoning: true, contextWindow: 200_000),
                    ModelDefinition(id: "deepseek/deepseek-r1", name: "DeepSeek R1", supportsVision: false, supportsReasoning: true, contextWindow: 128_000),
                    ModelDefinition(id: "openai/gpt-4o", name: "GPT-4o", supportsVision: true, supportsReasoning: false, contextWindow: 128_000),
                    ModelDefinition(id: "google/gemini-2.5-pro-exp-02-05", name: "Gemini 2.5 Pro", supportsVision: true, supportsReasoning: true, contextWindow: 1_000_000)
                ],
                isBuiltIn: true
            )
        ]
    }
}
