import Foundation

public struct MemoryDocument: Codable, Equatable {
    public var markdown: String
    public var isAutoInjectEnabled: Bool
    public var lastModified: Date
    
    public init(
        markdown: String = "",
        isAutoInjectEnabled: Bool = true,
        lastModified: Date = Date()
    ) {
        self.markdown = markdown
        self.isAutoInjectEnabled = isAutoInjectEnabled
        self.lastModified = lastModified
    }
    
    public static var `default`: MemoryDocument {
        MemoryDocument(
            markdown: """
            # PilotAI Core Memories
            
            - User's primary working directory: ~/Projects
            - Preferred platforms: iOS & Android
            - Coding preference: Clean architecture, strong typing, comprehensive tests
            """,
            isAutoInjectEnabled: true,
            lastModified: Date()
        )
    }
}
