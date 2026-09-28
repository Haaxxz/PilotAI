import Foundation

public struct Skill: Identifiable, Codable, Equatable {
    public var id: String
    public var name: String
    public var description: String
    public var promptInstructions: String
    public var isEnabled: Bool
    
    public init(id: String = UUID().uuidString, name: String, description: String, promptInstructions: String, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.promptInstructions = promptInstructions
        self.isEnabled = isEnabled
    }
    
    public static let defaults: [Skill] = [
        Skill(id: "web-search", name: "Web Search", description: "Search the web for up-to-date information", promptInstructions: "Use web search when the user asks about current events, facts, or technical documentation."),
        Skill(id: "code-analysis", name: "Code Analysis", description: "Analyze and explain code structure, bugs, and performance", promptInstructions: "Provide detailed breakdown of code syntax, potential bugs, and optimization suggestions."),
        Skill(id: "summarization", name: "Content Summarizer", description: "Summarize long texts, articles, or transcripts", promptInstructions: "Condense long content into concise key points and executive summaries.")
    ]
}
