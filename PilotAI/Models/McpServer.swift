import Foundation

public struct McpServer: Identifiable, Codable, Equatable {
    public var id: String
    public var name: String
    public var transportType: TransportType
    public var urlOrCommand: String
    public var isEnabled: Bool
    public var envVars: [String: String]
    public var headers: [String: String]
    
    public enum TransportType: String, Codable, CaseIterable {
        case sse = "SSE (HTTP)"
        case stdio = "stdio (Command)"
    }
    
    public init(id: String = UUID().uuidString, name: String, transportType: TransportType = .sse, urlOrCommand: String, isEnabled: Bool = true, envVars: [String: String] = [:], headers: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.transportType = transportType
        self.urlOrCommand = urlOrCommand
        self.isEnabled = isEnabled
        self.envVars = envVars
        self.headers = headers
    }
}
