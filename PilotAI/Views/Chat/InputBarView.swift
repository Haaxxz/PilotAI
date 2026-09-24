import SwiftUI

public struct InputBarView: View {
    @Binding public var text: String
    public let isGenerating: Bool
    public let onSend: () -> Void
    public let onStop: () -> Void
    
    @FocusState private var isFocused: Bool
    
    public init(text: Binding<String>, isGenerating: Bool, onSend: @escaping () -> Void, onStop: @escaping () -> Void) {
        self._text = text
        self.isGenerating = isGenerating
        self.onSend = onSend
        self.onStop = onStop
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(alignment: .bottom, spacing: 10) {
                // Attachments button
                Button(action: {
                    // Attachment action
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 6)
                
                // Text input
                HStack {
                    TextField("Ask PilotAI anything…", text: $text, axis: .vertical)
                        .focused($isFocused)
                        .lineLimit(1...5)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                
                // Send / Stop button
                if isGenerating {
                    Button(action: onStop) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.red)
                    }
                } else {
                    Button(action: {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSend()
                            text = ""
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary.opacity(0.5) : Color.blue)
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
    }
}
