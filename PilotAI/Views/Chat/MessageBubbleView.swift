import SwiftUI

public struct MessageBubbleView: View {
    public let message: Message
    public var onDelete: (() -> Void)?
    @State private var copied: Bool = false
    
    public init(message: Message, onDelete: (() -> Void)? = nil) {
        self.message = message
        self.onDelete = onDelete
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .assistant {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(Circle())
            } else {
                Spacer(minLength: 40)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Reasoning block
                if let reasoning = message.reasoningContent, !reasoning.isEmpty {
                    ThinkingView(text: reasoning, isStreaming: message.isStreaming && message.content.isEmpty)
                }
                
                // Tool calls
                if let tools = message.toolCalls, !tools.isEmpty {
                    ToolExecutionView(toolCalls: tools)
                }
                
                // Main content
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(message.role == .user ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(message.role == .user ? Color.blue : Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .textSelection(.enabled)
                        .contextMenu {
                            Button(action: { UIPasteboard.general.string = message.content }) {
                                Label("Copy Text", systemImage: "doc.on.doc")
                            }
                            ShareLink(item: message.content) {
                                Label("Share Text", systemImage: "square.and.arrow.up")
                            }
                            if let onDelete = onDelete {
                                Button(role: .destructive, action: onDelete) {
                                    Label("Delete Message", systemImage: "trash")
                                }
                            }
                        }
                } else if message.isStreaming && (message.reasoningContent == nil || message.reasoningContent!.isEmpty) {
                    HStack(spacing: 4) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(Color.secondary)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                }
                
                // Message metadata and actions
                HStack(spacing: 8) {
                    if let model = message.modelName {
                        Text(model)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    if message.role == .assistant && !message.content.isEmpty {
                        Button(action: {
                            UIPasteboard.general.string = message.content
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                copied = false
                            }
                        }) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if message.role == .user {
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.secondary)
                    .clipShape(Circle())
            } else {
                Spacer(minLength: 40)
            }
        }
    }
}
