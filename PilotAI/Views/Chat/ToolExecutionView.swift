import SwiftUI

public struct ToolExecutionView: View {
    public let toolCalls: [ToolCall]
    
    public init(toolCalls: [ToolCall]) {
        self.toolCalls = toolCalls
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(toolCalls) { tool in
                HStack(spacing: 8) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tool: \(tool.name)")
                            .font(.system(size: 13, weight: .semibold))
                        
                        if !tool.arguments.isEmpty {
                            Text(tool.arguments)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    if tool.isExecuting {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                    }
                }
                .padding(10)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)
            }
        }
    }
}
