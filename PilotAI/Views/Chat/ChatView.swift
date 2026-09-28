import SwiftUI

public struct ChatView: View {
    @EnvironmentObject private var state: AppState
    @State private var inputText: String = ""
    @State private var showHistorySheet: Bool = false
    @State private var showModelPicker: Bool = false
    
    public init() {}
    
    private var currentModelName: String {
        guard let conv = state.selectedConversation else {
            return state.currentProvider?.models.first?.name ?? "Default"
        }
        if let m = state.currentProvider?.models.first(where: { $0.id == conv.modelId }) {
            return m.name
        }
        return conv.modelId
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main Message List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if let conv = state.selectedConversation {
                                if conv.messages.isEmpty {
                                    emptyWelcomeView
                                        .padding(.top, 40)
                                } else {
                                    ForEach(conv.messages) { message in
                                        MessageBubbleView(message: message)
                                            .id(message.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .onChange(of: state.selectedConversation?.messages.count) {
                        if state.settings.autoScroll, let last = state.selectedConversation?.messages.last {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Bottom Input Bar
                InputBarView(
                    text: $inputText,
                    isGenerating: state.isGenerating,
                    onSend: {
                        state.sendMessage(inputText)
                    },
                    onStop: {
                        state.stopGenerating()
                    }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showHistorySheet = true }) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 16))
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Button(action: { showModelPicker = true }) {
                        VStack(spacing: 2) {
                            Text(state.selectedConversation?.title ?? "PilotAI")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            HStack(spacing: 4) {
                                Text("\(state.currentProvider?.name ?? "Provider") · \(currentModelName)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.blue)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { state.newConversation() }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16))
                    }
                }
            }
            .sheet(isPresented: $showHistorySheet) {
                ConversationListView()
                    .environmentObject(state)
            }
            .sheet(isPresented: $showModelPicker) {
                ModelPickerSheetView()
                    .environmentObject(state)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var emptyWelcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            
            VStack(spacing: 6) {
                Text("What would you like to build?")
                    .font(.system(size: 20, weight: .bold))
                
                Text("PilotAI is ready to write code, analyze data, and assist across platforms.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 10) {
                suggestionCard(title: "Code Architecture", prompt: "Explain clean architecture for a cross-platform mobile app")
                suggestionCard(title: "Roleplay Companions", prompt: "Tell me about Xiaoman and Traveler roleplay characters")
                suggestionCard(title: "Terminal Execution", prompt: "How do I run persistent terminal commands inside PilotAI?")
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    private func suggestionCard(title: String, prompt: String) -> some View {
        Button(action: {
            inputText = prompt
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(prompt)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

struct ModelPickerSheetView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(state.providers.filter { $0.isEnabled }) { provider in
                    Section(header: Text(provider.name)) {
                        ForEach(provider.models) { model in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(model.name).font(.system(size: 15, weight: .medium))
                                    Text(model.id).font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                                }
                                Spacer()
                                if provider.id == state.currentProvider?.id && model.id == (state.selectedConversation?.modelId ?? state.currentProvider?.defaultModelId) {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                state.selectModel(providerId: provider.id, modelId: model.id)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Provider & Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
