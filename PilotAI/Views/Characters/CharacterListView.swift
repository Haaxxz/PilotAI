import SwiftUI

public struct CharacterListView: View {
    @EnvironmentObject private var state: AppState
    @State private var selectedCharacter: Character? = nil
    @State private var showNewCharacterSheet: Bool = false
    
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
                    Button(action: { showNewCharacterSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $selectedCharacter) { char in
                characterDetailSheet(char)
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
