import SwiftUI

public struct ChatView: View {
    @EnvironmentObject private var state: AppState
    @State private var inputText: String = ""
    @State private var showHistorySheet: Bool = false
    @State private var showModelPicker: Bool = false
    
    public init() {}
    
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
                        HStack(spacing: 4) {
                            Text(state.selectedConversation?.title ?? "PilotAI")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
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
            .confirmationDialog("Select Model", isPresented: $showModelPicker, titleVisibility: .visible) {
                if let prov = state.currentProvider {
                    ForEach(prov.models) { model in
                        Button(model.name) {
                            state.selectedConversation?.modelId = model.id
                        }
                    }
                }
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
            state.sendMessage(prompt)
            inputText = ""
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
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
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
