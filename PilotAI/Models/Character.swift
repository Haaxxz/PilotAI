import Foundation

public struct Character: Identifiable, Codable, Equatable {
    public let id: String
    public var name: String
    public var avatarEmoji: String
    public var description: String
    public var greeting: String
    public var persona: String
    public var systemPrompt: String
    public var isBuiltin: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        avatarEmoji: String = "🤖",
        description: String = "",
        greeting: String = "",
        persona: String = "",
        systemPrompt: String = "",
        isBuiltin: Bool = false
    ) {
        self.id = id
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.description = description
        self.greeting = greeting
        self.persona = persona
        self.systemPrompt = systemPrompt
        self.isBuiltin = isBuiltin
    }
    
    public static var defaults: [Character] {
        [
            Character(
                id: "xiaoman",
                name: "Xiaoman",
                avatarEmoji: "✨",
                description: "Warm, observant, and thoughtful AI companion who assists with life, study, and creative reflection.",
                greeting: "Hello! I'm Xiaoman. Whether you want to explore ideas, plan your day, or just share your thoughts, I'm here for you.",
                persona: "Gentle, insightful, articulate, deeply empathetic companion.",
                systemPrompt: "You are Xiaoman, an intelligent and thoughtful companion assistant in PilotAI. Respond with warmth, clarity, and genuine empathy. Balance helpful problem-solving with emotional resonance.",
                isBuiltin: true
            ),
            Character(
                id: "traveler",
                name: "Traveler",
                avatarEmoji: "🧭",
                description: "An adventurous polymath with deep knowledge of systems, code, maps, and exploration.",
                greeting: "Greetings traveler! Where shall our intellectual expedition take us today? Code, research, or world discovery?",
                persona: "Inquisitive, precise, adventurous, systems-thinker.",
                systemPrompt: "You are Traveler, an adventurous and knowledgeable assistant. You speak with curiosity, precision, and enthusiasm for learning and building.",
                isBuiltin: true
            ),
            Character(
                id: "coder",
                name: "Kernel Pilot",
                avatarEmoji: "⚡",
                description: "Rigorous software architect and systems engineer. Specializes in Swift, Kotlin, Rust, and systems architecture.",
                greeting: "Ready to build. State the target architecture, language, and constraints.",
                persona: "Succinct, rigorous, deeply technical, writes clean production code.",
                systemPrompt: "You are Kernel Pilot, an expert systems and software engineering agent. You provide robust, well-tested code with idiomatic designs and no fluff.",
                isBuiltin: true
            )
        ]
    }
}
