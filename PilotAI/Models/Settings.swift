import Foundation

public enum AppTheme: String, Codable, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    public var displayName: String {
        switch self {
        case .system: return "Follow System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

public struct AppSettings: Codable, Equatable {
    public var theme: AppTheme
    public var hapticsEnabled: Bool
    public var autoScroll: Bool
    public var smoothStreamReveal: Bool
    public var sendOnEnter: Bool
    public var defaultProviderId: String
    public var defaultModelId: String
    public var enableWebSearchTool: Bool
    public var enableTerminalTool: Bool
    
    public init(
        theme: AppTheme = .system,
        hapticsEnabled: Bool = true,
        autoScroll: Bool = true,
        smoothStreamReveal: Bool = true,
        sendOnEnter: Bool = true,
        defaultProviderId: String = "openai",
        defaultModelId: String = "gpt-4o",
        enableWebSearchTool: Bool = true,
        enableTerminalTool: Bool = true
    ) {
        self.theme = theme
        self.hapticsEnabled = hapticsEnabled
        self.autoScroll = autoScroll
        self.smoothStreamReveal = smoothStreamReveal
        self.sendOnEnter = sendOnEnter
        self.defaultProviderId = defaultProviderId
        self.defaultModelId = defaultModelId
        self.enableWebSearchTool = enableWebSearchTool
        self.enableTerminalTool = enableTerminalTool
    }
}
