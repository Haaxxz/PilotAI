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
        webSearchEnabled: Bool = false,
        reasoningEnabled: Bool = false,
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
            
            // If Web Search is enabled, perform a live search query and inject results
            if webSearchEnabled {
                let searchContext = await performWebSearch(query: prompt)
                if !searchContext.isEmpty {
                    systemComponents.append("\n[Live Web Search Context]:\n" + searchContext)
                }
            }
            
            // If Reasoning/Brain mode is enabled, request step-by-step thinking
            if reasoningEnabled {
                systemComponents.append("\n[Deep Thinking / Brain Mode ACTIVE]: Provide a detailed, step-by-step reasoning analysis of your thought process before giving the final answer. If you use internal reasoning, enclose your thought process inside <think> ... </think> tags.")
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
                
                var inThinkBlock = false
                
                for try await chunk in stream {
                    if Task.isCancelled { break }
                    
                    if let text = chunk.textDelta {
                        if text.contains("<think>") {
                            inThinkBlock = true
                            let parts = text.components(separatedBy: "<think>")
                            if let before = parts.first, !before.isEmpty {
                                assistantMsg.content += before
                            }
                            if parts.count > 1 {
                                let inside = parts[1]
                                if assistantMsg.reasoningContent == nil { assistantMsg.reasoningContent = "" }
                                assistantMsg.reasoningContent? += inside
                            }
                        } else if inThinkBlock && text.contains("</think>") {
                            inThinkBlock = false
                            let parts = text.components(separatedBy: "</think>")
                            if let inside = parts.first {
                                if assistantMsg.reasoningContent == nil { assistantMsg.reasoningContent = "" }
                                assistantMsg.reasoningContent? += inside
                            }
                            if parts.count > 1 {
                                assistantMsg.content += parts[1]
                            }
                        } else if inThinkBlock {
                            if assistantMsg.reasoningContent == nil { assistantMsg.reasoningContent = "" }
                            assistantMsg.reasoningContent? += text
                        } else {
                            assistantMsg.content += text
                        }
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
    
    private func performWebSearch(query: String) async -> String {
        let cleanQuery = String(query.prefix(120)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let encoded = cleanQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.duckduckgo.com/?q=\(encoded)&format=json&no_html=1&skip_disambig=1") else {
            return ""
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                var resultText = ""
                if let abstract = json["AbstractText"] as? String, !abstract.isEmpty {
                    resultText += "Summary: \(abstract)\n"
                }
                if let related = json["RelatedTopics"] as? [[String: Any]] {
                    let snippets = related.prefix(4).compactMap { $0["Text"] as? String }.joined(separator: "\n- ")
                    if !snippets.isEmpty {
                        resultText += "Key Web References:\n- \(snippets)"
                    }
                }
                return resultText
            }
        } catch {}
        return ""
    }
}

