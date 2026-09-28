import SwiftUI

public extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

public struct InputBarView: View {
    @Binding public var text: String
    public let isGenerating: Bool
    public let onSend: () -> Void
    public let onStop: () -> Void
    
    @State private var webSearchEnabled: Bool = false
    @State private var reasoningEnabled: Bool = false
    @State private var showAttachmentOptions: Bool = false
    @State private var attachedImageName: String? = nil
    
    @FocusState private var isFocused: Bool
    
    public init(text: Binding<String>, isGenerating: Bool, onSend: @escaping () -> Void, onStop: @escaping () -> Void) {
        self._text = text
        self.isGenerating = isGenerating
        self.onSend = onSend
        self.onStop = onStop
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            Divider()
            
            // Attachment preview badge if attached
            if let img = attachedImageName {
                HStack {
                    Image(systemName: "photo.fill").foregroundColor(.blue)
                    Text(img).font(.caption).lineLimit(1)
                    Spacer()
                    Button(action: { attachedImageName = nil }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal, 16)
            }
            
            // Input controls bar
            HStack(alignment: .bottom, spacing: 6) {
                // Attachments button
                Button(action: { showAttachmentOptions = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 6)
                .confirmationDialog("Add Attachment", isPresented: $showAttachmentOptions, titleVisibility: .visible) {
                    Button("Photo / Image") { attachedImageName = "Image_\(Int(Date().timeIntervalSince1970)).png" }
                    Button("Document / File") { attachedImageName = "Doc_\(Int(Date().timeIntervalSince1970)).txt" }
                    Button("Cancel", role: .cancel) {}
                }
                
                // Web Search toggle
                Button(action: { webSearchEnabled.toggle() }) {
                    Image(systemName: "globe")
                        .font(.system(size: 18))
                        .foregroundColor(webSearchEnabled ? .blue : .secondary)
                        .padding(5)
                        .background(webSearchEnabled ? Color.blue.opacity(0.15) : Color.clear)
                        .clipShape(Circle())
                }
                .padding(.bottom, 4)
                
                // Deep Thinking toggle
                Button(action: { reasoningEnabled.toggle() }) {
                    Image(systemName: "brain")
                        .font(.system(size: 18))
                        .foregroundColor(reasoningEnabled ? .purple : .secondary)
                        .padding(5)
                        .background(reasoningEnabled ? Color.purple.opacity(0.15) : Color.clear)
                        .clipShape(Circle())
                }
                .padding(.bottom, 4)
                
                // Text input field
                HStack {
                    TextField("Ask PilotAI anything…", text: $text, axis: .vertical)
                        .focused($isFocused)
                        .lineLimit(1...5)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                
                // Keyboard dismiss button when focused
                if isFocused {
                    Button(action: { isFocused = false }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 6)
                    }
                }
                
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
                            attachedImageName = nil
                            isFocused = false
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary.opacity(0.5) : Color.blue)
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
            .background(Color(.systemBackground))
        }
    }
}
