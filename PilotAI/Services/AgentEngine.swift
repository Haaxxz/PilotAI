import Foundation

public final class AgentEngine {
    public static let shared = AgentEngine()
    
    private var currentTask: Task<Void, Never>?
    
    public func send(
        prompt: String,
        conversation: Conversation,
        provider: ModelProvider,
        character: Character? = nil,
        memory: MemoryDocument,
        onUpdate: @escaping (Message) -> Void,
        onCompletion: @escaping (Result<Message, Error>) -> Void
    ) {
        currentTask?.cancel()
        
        currentTask = Task { @MainActor in
            var assistantMsg = Message(
                role: .assistant,
                content: "",
                reasoningContent: nil,
                isStreaming: true,
                modelName: conversation.modelId
            )
            onUpdate(assistantMsg)
            
            // Build system prompt
            var systemComponents: [String] = []
            
            if let char = character {
                systemComponents.append(char.systemPrompt)
            } else {
                systemComponents.append("You are PilotAI, an advanced mobile autonomous coding and reasoning assistant. Respond clearly, accurately, and assist the user proactively.")
            }
            
            if memory.isAutoInjectEnabled && !memory.markdown.isEmpty {
                systemComponents.append("\n[Core User Memories & Instructions]:\n" + memory.markdown)
            }
            
            let systemPrompt = systemComponents.joined(separator: "\n\n")
            
            var history = conversation.messages
            history.append(Message(role: .user, content: prompt))
            
            do {
                let stream = OpenAIService.shared.streamChat(
                    provider: provider,
                    modelId: conversation.modelId,
                    messages: history,
                    systemPrompt: systemPrompt
                )
                
                for try await chunk in stream {
                    if Task.isCancelled { break }
                    
                    if let text = chunk.textDelta {
                        assistantMsg.content += text
                    }
                    if let reasoning = chunk.reasoningDelta {
                        if assistantMsg.reasoningContent == nil {
                            assistantMsg.reasoningContent = ""
                        }
                        assistantMsg.reasoningContent? += reasoning
                    }
                    
                    onUpdate(assistantMsg)
                }
                
                assistantMsg.isStreaming = false
                onUpdate(assistantMsg)
                onCompletion(.success(assistantMsg))
            } catch {
                if !Task.isCancelled {
                    assistantMsg.isStreaming = false
                    if assistantMsg.content.isEmpty {
                        assistantMsg.content = "⚠️ Error: \(error.localizedDescription)\n\nPlease check your API key and base URL under Model Providers in Settings."
                    }
                    onUpdate(assistantMsg)
                    onCompletion(.failure(error))
                }
            }
        }
    }
    
    public func stop() {
        currentTask?.cancel()
        currentTask = nil
    }
}
