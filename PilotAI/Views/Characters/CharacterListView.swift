import SwiftUI
import UniformTypeIdentifiers

public struct CharacterListView: View {
    @EnvironmentObject private var state: AppState
    @State private var selectedCharacter: Character? = nil
    @State private var showEditor: Bool = false
    @State private var editingCharacter: Character? = nil
    @State private var showFileImporter: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(state.characters) { char in
                        characterCard(char)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Characters")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showFileImporter = true }) {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Button(action: {
                            editingCharacter = nil
                            showEditor = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.png, .json], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let secure = url.startAccessingSecurityScopedResource()
                    defer { if secure { url.stopAccessingSecurityScopedResource() } }
                    if let char = CharacterCardParser.parseCharacter(from: url) {
                        state.characters.insert(char, at: 0)
                        state.saveCharacters()
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            .sheet(item: $selectedCharacter) { char in
                characterDetailSheet(char)
            }
            .sheet(isPresented: $showEditor) {
                CharacterEditorView(character: editingCharacter) { updatedChar in
                    if let index = state.characters.firstIndex(where: { $0.id == updatedChar.id }) {
                        state.characters[index] = updatedChar
                    } else {
                        state.characters.append(updatedChar)
                    }
                    state.saveCharacters()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func characterCard(_ char: Character) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(char.avatarEmoji)
                    .font(.system(size: 32))
                    .frame(width: 50, height: 50)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(char.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(char.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            if !char.greeting.isEmpty {
                Text("\"\(char.greeting)\"")
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(10)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
            }
            
            HStack {
                Button(action: {
                    selectedCharacter = char
                }) {
                    Text("Details")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                if !char.isBuiltin {
                    Button(action: {
                        editingCharacter = char
                        showEditor = true
                    }) {
                        Text("Edit")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .padding(.leading, 8)
                    
                    Button(action: {
                        state.characters.removeAll { $0.id == char.id }
                        state.saveCharacters()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .padding(.leading, 8)
                }
                
                Spacer()
                
                Button(action: {
                    state.newConversation(mode: .roleplay, characterId: char.id)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                        Text("Start Chat")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(18)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func characterDetailSheet(_ char: Character) -> some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    HStack {
                        Text("Avatar")
                        Spacer()
                        Text(char.avatarEmoji).font(.title)
                    }
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(char.name).foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Greeting")) {
                    Text(char.greeting.isEmpty ? "None" : char.greeting)
                        .font(.system(size: 14))
                }
                
                Section(header: Text("Persona & Description")) {
                    Text(char.description)
                        .font(.system(size: 14))
                    Text(char.persona)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("System Instructions")) {
                    Text(char.systemPrompt)
                        .font(.system(size: 12, design: .monospaced))
                }
            }
            .navigationTitle(char.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedCharacter = nil
                    }
                }
            }
        }
    }
}
