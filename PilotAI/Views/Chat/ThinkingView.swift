import SwiftUI

public struct ThinkingView: View {
    public let text: String
    public let isStreaming: Bool
    @State private var isExpanded: Bool = true
    
    public init(text: String, isStreaming: Bool = false) {
        self.text = text
        self.isStreaming = isStreaming
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.purple)
                    
                    Text("Thinking Process")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if isStreaming {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 6, height: 6)
                            .opacity(0.8)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(text)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
                    .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
}
