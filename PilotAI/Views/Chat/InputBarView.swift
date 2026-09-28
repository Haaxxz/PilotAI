import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

public extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

public struct InputBarView: View {
    @EnvironmentObject private var state: AppState
    @Binding public var text: String
    public let isGenerating: Bool
    public let onSend: (Bool, Bool) -> Void
    public let onStop: () -> Void
    
    @State private var webSearchEnabled: Bool = false
    @State private var reasoningEnabled: Bool = false
    @State private var showAttachmentOptions: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    @State private var attachedImageName: String? = nil
    @State private var attachedImageData: Data? = nil
    @State private var attachedFileURL: URL? = nil
    
    @FocusState private var isFocused: Bool
    
    public init(text: Binding<String>, isGenerating: Bool, onSend: @escaping (Bool, Bool) -> Void, onStop: @escaping () -> Void) {
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
                    Image(systemName: img.hasSuffix(".png") || img.hasSuffix(".jpg") || img.hasSuffix(".jpeg") || img.hasSuffix(".heic") ? "photo.fill" : "doc.fill")
                        .foregroundColor(.blue)
                    Text(img)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Button(action: {
                        attachedImageName = nil
                        attachedImageData = nil
                        attachedFileURL = nil
                        selectedPhotoItem = nil
                    }) {
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
                    Button("Photo / Image") { showPhotoPicker = true }
                    Button("Document / File") { showFileImporter = true }
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
                
                // Context / Token usage badge
                if let conv = state.selectedConversation, !conv.messages.isEmpty {
                    let charCount = conv.messages.reduce(0) { $0 + $1.content.count }
                    let tokenEst = charCount / 4
                    if tokenEst > 0 {
                        Text("~\(tokenEst < 1000 ? "\(tokenEst)" : String(format: "%.1fk", Double(tokenEst) / 1000.0)) tks")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(6)
                            .padding(.bottom, 6)
                    }
                }
                
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
                    Button(action: handleSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(canSend ? Color.blue : Color.secondary.opacity(0.5))
                    }
                    .disabled(!canSend)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
            .background(Color(.systemBackground))
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        self.attachedImageData = data
                        self.attachedImageName = "Photo_\(Int(Date().timeIntervalSince1970)).png"
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.item, .content, .data, .plainText, .pdf, .image, .json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let accessing = url.startAccessingSecurityScopedResource()
                defer {
                    if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                if let data = try? Data(contentsOf: url) {
                    self.attachedImageData = data
                    self.attachedFileURL = url
                    self.attachedImageName = url.lastPathComponent
                }
            case .failure(let error):
                print("File import error: \(error.localizedDescription)")
            }
        }
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || attachedImageName != nil
    }
    
    private func handleSend() {
        guard canSend else { return }
        
        var fullPrompt = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let fileName = attachedImageName {
            if let data = attachedImageData, let docContent = String(data: data, encoding: .utf8), docContent.count < 15000 {
                if fullPrompt.isEmpty {
                    fullPrompt = "Attached file: \(fileName)\n\n\(docContent)"
                } else {
                    fullPrompt = "\(fullPrompt)\n\n--- Attached File: \(fileName) ---\n\(docContent)"
                }
            } else {
                if fullPrompt.isEmpty {
                    fullPrompt = "[Attached File: \(fileName)]"
                } else {
                    fullPrompt = "\(fullPrompt)\n\n[Attached File: \(fileName)]"
                }
            }
        }
        
        text = fullPrompt
        onSend(webSearchEnabled, reasoningEnabled)
        text = ""
        attachedImageName = nil
        attachedImageData = nil
        attachedFileURL = nil
        selectedPhotoItem = nil
        isFocused = false
    }
}

