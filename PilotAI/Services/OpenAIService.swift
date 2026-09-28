import Foundation

public struct StreamChunk {
    public let textDelta: String?
    public let reasoningDelta: String?
    public let toolCallDelta: ToolCall?
    public let isFinished: Bool
    
    public init(textDelta: String? = nil, reasoningDelta: String? = nil, toolCallDelta: ToolCall? = nil, isFinished: Bool = false) {
        self.textDelta = textDelta
        self.reasoningDelta = reasoningDelta
        self.toolCallDelta = toolCallDelta
        self.isFinished = isFinished
    }
}

public final class OpenAIService {
    public static let shared = OpenAIService()
    
    public func streamChat(
        provider: ModelProvider,
        modelId: String,
        messages: [Message],
        systemPrompt: String? = nil,
        tools: [[String: Any]]? = nil
    ) -> AsyncThrowingStream<StreamChunk, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    if provider.type == .anthropic {
                        try await self.streamAnthropic(
                            provider: provider,
                            modelId: modelId,
                            messages: messages,
                            systemPrompt: systemPrompt,
                            continuation: continuation
                        )
                    } else {
                        try await self.streamOpenAI(
                            provider: provider,
                            modelId: modelId,
                            messages: messages,
                            systemPrompt: systemPrompt,
                            tools: tools,
                            continuation: continuation
                        )
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    private func streamOpenAI(
        provider: ModelProvider,
        modelId: String,
        messages: [Message],
        systemPrompt: String?,
        tools: [[String: Any]]?,
        continuation: AsyncThrowingStream<StreamChunk, Error>.Continuation
    ) async throws {
        var endpoint = provider.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !endpoint.hasSuffix("/chat/completions") && !endpoint.hasSuffix("/responses") {
            if endpoint.hasSuffix("/") {
                endpoint += "chat/completions"
            } else {
                endpoint += "/chat/completions"
            }
        }
        
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if !provider.apiKey.isEmpty {
            request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        for header in provider.customHeaders {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        var apiMessages: [[String: Any]] = []
        if let sys = systemPrompt, !sys.isEmpty {
            apiMessages.append(["role": "system", "content": sys])
        }
        
        for msg in messages {
            var m: [String: Any] = ["role": msg.role.rawValue, "content": msg.content]
            if let tools = msg.toolCalls, !tools.isEmpty {
                m["tool_calls"] = tools.map { t in
                    [
                        "id": t.id,
                        "type": "function",
                        "function": [
                            "name": t.name,
                            "arguments": t.arguments
                        ]
                    ]
                }
            }
            apiMessages.append(m)
        }
        
        var body: [String: Any] = [
            "model": modelId,
            "messages": apiMessages,
            "stream": true
        ]
        
        if let tools = tools, !tools.isEmpty {
            body["tools"] = tools
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            var errText = ""
            for try await line in asyncBytes.lines { errText += line }
            throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errText)"
            ])
        }
        
        for try await line in asyncBytes.lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix(":") { continue }
            if trimmed == "data: [DONE]" {
                continuation.yield(StreamChunk(isFinished: true))
                break
            }
            guard trimmed.hasPrefix("data: ") else { continue }
            let jsonStr = String(trimmed.dropFirst(6))
            guard let jsonData = jsonStr.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first else { continue }
            
            let delta = first["delta"] as? [String: Any]
            let text = delta?["content"] as? String
            let reasoning = delta?["reasoning_content"] as? String ?? delta?["reasoning"] as? String
            
            continuation.yield(StreamChunk(textDelta: text, reasoningDelta: reasoning))
        }
        continuation.finish()
    }
    
    private func streamAnthropic(
        provider: ModelProvider,
        modelId: String,
        messages: [Message],
        systemPrompt: String?,
        continuation: AsyncThrowingStream<StreamChunk, Error>.Continuation
    ) async throws {
        var endpoint = provider.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !endpoint.hasSuffix("/v1/messages") && !endpoint.hasSuffix("/messages") {
            if endpoint.hasSuffix("/") {
                endpoint += "v1/messages"
            } else {
                endpoint += "/v1/messages"
            }
        }
        
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(provider.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(provider.anthropicVersion.isEmpty ? "2023-06-01" : provider.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        
        for header in provider.customHeaders {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        var apiMessages: [[String: Any]] = []
        for msg in messages {
            let role = msg.role == .user ? "user" : "assistant"
            apiMessages.append(["role": role, "content": msg.content])
        }
        
        var body: [String: Any] = [
            "model": modelId,
            "messages": apiMessages,
            "max_tokens": 4096,
            "stream": true
        ]
        
        if let sys = systemPrompt, !sys.isEmpty {
            body["system"] = sys
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            var errText = ""
            for try await line in asyncBytes.lines { errText += line }
            throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errText)"
            ])
        }
        
        for try await line in asyncBytes.lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix(":") { continue }
            if trimmed.hasPrefix("data: ") {
                let jsonStr = String(trimmed.dropFirst(6))
                guard let jsonData = jsonStr.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { continue }
                
                let type = json["type"] as? String ?? ""
                if type == "message_stop" {
                    continuation.yield(StreamChunk(isFinished: true))
                    break
                }
                
                if type == "content_block_delta",
                   let delta = json["delta"] as? [String: Any] {
                    let deltaType = delta["type"] as? String ?? ""
                    if deltaType == "text_delta", let text = delta["text"] as? String {
                        continuation.yield(StreamChunk(textDelta: text))
                    } else if deltaType == "thinking_delta", let thinking = delta["thinking"] as? String {
                        continuation.yield(StreamChunk(reasoningDelta: thinking))
                    }
                }
            }
        }
        continuation.finish()
    }
}
