import SwiftUI

public struct CharacterEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let character: Character? // nil = creating new
    let onSave: (Character) -> Void
    
    @State private var name: String
    @State private var avatarEmoji: String
    @State private var description: String
    @State private var greeting: String
    @State private var persona: String
    @State private var systemPrompt: String
    
    private let commonEmojis = ["🤖", "🧠", "🦊", "🐉", "🧙‍♂️", "👩‍💻", "🕵️", "🎭", "🧜‍♀️", "🦸", "👾", "🌟", "⚡", "🔮", "🌙", "🦅", "🐺", "🎪", "🧪", "🏴‍☠️"]
    
    public init(character: Character? = nil, onSave: @escaping (Character) -> Void) {
        self.character = character
        self.onSave = onSave
        _name = State(initialValue: character?.name ?? "")
        _avatarEmoji = State(initialValue: character?.avatarEmoji ?? "🤖")
        _description = State(initialValue: character?.description ?? "")
        _greeting = State(initialValue: character?.greeting ?? "")
        _persona = State(initialValue: character?.persona ?? "")
        _systemPrompt = State(initialValue: character?.systemPrompt ?? "")
    }
    
    public var body: some View {
        NavigationView {
            Form {
                // Avatar
                Section(header: Text("Avatar")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(commonEmojis, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 48, height: 48)
                                    .background(avatarEmoji == emoji ? Color.blue.opacity(0.2) : Color(.tertiarySystemBackground))
                                    .cornerRadius(12)
                                    .onTapGesture { avatarEmoji = emoji }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                    }
                    HStack {
                        Text("Custom:")
                        TextField("Enter emoji", text: $avatarEmoji)
                            .frame(width: 60)
                        Text(avatarEmoji).font(.title2)
                    }
                }
                
                Section(header: Text("Identity")) {
                    TextField("Name", text: $name)
                    TextField("Short description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section(header: Text("Greeting"), footer: Text("This message appears at the start of a new conversation.")) {
                    TextField("Opening message...", text: $greeting, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Persona"), footer: Text("Background story, traits, and role.")) {
                    TextField("Personality, backstory...", text: $persona, axis: .vertical)
                        .lineLimit(4...10)
                }
                
                Section(header: Text("System Prompt"), footer: Text("Direct instructions for the AI. Overrides the default agent prompt.")) {
                    TextField("You are...", text: $systemPrompt, axis: .vertical)
                        .lineLimit(4...12)
                        .font(.system(size: 13, design: .monospaced))
                }
            }
            .navigationTitle(character == nil ? "New Character" : "Edit Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let saved = Character(
                            id: character?.id ?? UUID().uuidString,
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unnamed" : name.trimmingCharacters(in: .whitespacesAndNewlines),
                            avatarEmoji: avatarEmoji.isEmpty ? "🤖" : avatarEmoji,
                            description: description,
                            greeting: greeting,
                            persona: persona,
                            systemPrompt: systemPrompt,
                            isBuiltin: character?.isBuiltin ?? false
                        )
                        onSave(saved)
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
