import Foundation

public struct PilotAIBackupPayload: Codable {
    public let format: String
    public let schemaVersion: Int
    public let exportedAt: Int64
    public var providers: [ModelProvider]?
    public var selectedProviderId: String?
    public var selectedModelId: String?
    public var conversations: [Conversation]?
    public var memoryMd: String?
    public var characters: [Character]?
    
    public init(
        format: String = "eta-backup",
        schemaVersion: Int = 2,
        exportedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        providers: [ModelProvider]? = nil,
        selectedProviderId: String? = nil,
        selectedModelId: String? = nil,
        conversations: [Conversation]? = nil,
        memoryMd: String? = nil,
        characters: [Character]? = nil
    ) {
        self.format = format
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.providers = providers
        self.selectedProviderId = selectedProviderId
        self.selectedModelId = selectedModelId
        self.conversations = conversations
        self.memoryMd = memoryMd
        self.characters = characters
    }
}

public final class BackupService {
    public static let shared = BackupService()
    
    public func exportBackup(
        providers: [ModelProvider],
        conversations: [Conversation],
        memory: MemoryDocument,
        characters: [Character],
        selectedProviderId: String,
        selectedModelId: String
    ) throws -> Data {
        let payload = PilotAIBackupPayload(
            format: "eta-backup",
            schemaVersion: 2,
            exportedAt: Int64(Date().timeIntervalSince1970 * 1000),
            providers: providers,
            selectedProviderId: selectedProviderId,
            selectedModelId: selectedModelId,
            conversations: conversations,
            memoryMd: memory.markdown,
            characters: characters
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }
    
    public func importBackup(data: Data) throws -> PilotAIBackupPayload {
        let decoder = JSONDecoder()
        let payload = try decoder.decode(PilotAIBackupPayload.self, from: data)
        guard payload.format == "eta-backup" || payload.format == "pilotai-backup" else {
            throw NSError(domain: "PilotAIBackup", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid backup format: \(payload.format)"])
        }
        return payload
    }
}
