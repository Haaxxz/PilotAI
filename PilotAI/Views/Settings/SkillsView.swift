import SwiftUI

public struct SkillsView: View {
    @EnvironmentObject private var state: AppState
    @State private var showAddSheet = false
    @State private var editingSkill: Skill? = nil
    
    public init() {}
    
    public var body: some View {
        List {
            Section(header: Text("Agent Skills"), footer: Text("Enabled skills provide system instructions and specialized capabilities to the AI agent during conversations.")) {
                ForEach(state.skills) { skill in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(skill.name).font(.headline)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { skill.isEnabled },
                                set: { val in
                                    var updated = skill
                                    updated.isEnabled = val
                                    state.updateSkill(updated)
                                }
                            ))
                            .labelsHidden()
                        }
                        Text(skill.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture { editingSkill = skill }
                }
                .onDelete { idxSet in
                    idxSet.map { state.skills[$0] }.forEach { state.deleteSkill(id: $0.id) }
                }
            }
            
            Section {
                Button(action: {
                    editingSkill = Skill(name: "", description: "", promptInstructions: "")
                }) {
                    Label("Add Custom Skill", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Agent Skills")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingSkill) { skill in
            SkillEditorSheet(skill: skill) { updated in
                if state.skills.contains(where: { $0.id == updated.id }) {
                    state.updateSkill(updated)
                } else {
                    state.addSkill(updated)
                }
                editingSkill = nil
            } onCancel: { editingSkill = nil }
        }
    }
}

struct SkillEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let skill: Skill
    let onSave: (Skill) -> Void
    let onCancel: () -> Void
    
    @State private var name: String
    @State private var description: String
    @State private var promptInstructions: String
    @State private var isEnabled: Bool
    
    init(skill: Skill, onSave: @escaping (Skill) -> Void, onCancel: @escaping () -> Void) {
        self.skill = skill
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: skill.name)
        _description = State(initialValue: skill.description)
        _promptInstructions = State(initialValue: skill.promptInstructions)
        _isEnabled = State(initialValue: skill.isEnabled)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Skill Info")) {
                    TextField("Skill Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section(header: Text("System Instructions"), footer: Text("Prompt injected into context when this skill is active.")) {
                    TextEditor(text: $promptInstructions)
                        .frame(minHeight: 100)
                        .font(.system(size: 13, design: .monospaced))
                }
                
                Section {
                    Toggle("Enable Skill", isOn: $isEnabled)
                }
            }
            .navigationTitle(skill.name.isEmpty ? "New Skill" : "Edit Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel", action: onCancel) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var s = skill
                        s.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        s.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
                        s.promptInstructions = promptInstructions
                        s.isEnabled = isEnabled
                        onSave(s)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
