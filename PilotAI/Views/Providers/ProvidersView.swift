import SwiftUI

// MARK: - ProvidersView (Provider List)
public struct ProvidersView: View {
    @EnvironmentObject private var state: AppState
    @State private var searchQuery: String = ""
    @State private var showAddSheet: Bool = false
    @State private var newProviderType: NewProviderType = .openai
    @State private var providerToDelete: ModelProvider? = nil
    @State private var selectedProviderForDetail: ModelProvider? = nil

    public init() {}

    enum NewProviderType { case openai, anthropic }

    var filteredProviders: [ModelProvider] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return state.providers }
        return state.providers.filter {
            $0.name.lowercased().contains(q) ||
            $0.baseURL.lowercased().contains(q) ||
            $0.type.displayName.lowercased().contains(q)
        }
    }

    public var body: some View {
        List {
            // Search
            Section {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search providers…", text: $searchQuery)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Add New Provider
            Section(header: Text("Add New Provider")) {
                Button(action: {
                    newProviderType = .openai
                    showAddSheet = true
                }) {
                    Label("OpenAI Compatible", systemImage: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                Button(action: {
                    newProviderType = .anthropic
                    showAddSheet = true
                }) {
                    Label("Anthropic", systemImage: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }

            // Provider List
            Section(header: Text(filteredProviders.isEmpty ? "No Providers" : "\(filteredProviders.count) Provider(s)")) {
                ForEach(filteredProviders) { provider in
                    NavigationLink(destination: ProviderDetailView(providerId: provider.id).environmentObject(state)) {
                        ProviderRow(provider: provider, isActive: provider.id == state.settings.defaultProviderId) {
                            state.settings.defaultProviderId = provider.id
                            state.saveSettings()
                        }
                    }
                    .opacity(provider.isEnabled ? 1.0 : 0.6)
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        let p = filteredProviders[i]
                        if !p.isBuiltIn { providerToDelete = p }
                    }
                }
            }
        }
        .navigationTitle("Model Providers")
        .sheet(isPresented: $showAddSheet) {
            ProviderDetailView(newType: newProviderType).environmentObject(state)
        }
        .alert("Remove Provider", isPresented: Binding(
            get: { providerToDelete != nil },
            set: { if !$0 { providerToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let p = providerToDelete { state.deleteProvider(id: p.id) }
                providerToDelete = nil
            }
            Button("Cancel", role: .cancel) { providerToDelete = nil }
        } message: {
            Text("Are you sure you want to remove \"\(providerToDelete?.name ?? "")\"? This action cannot be undone.")
        }
    }
}

private struct ProviderRow: View {
    let provider: ModelProvider
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(provider.name)
                    .font(.system(size: 16, weight: .semibold))
                Text(provider.baseURL)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(provider.type.displayName)
                        .font(.caption2)
                    Text("·")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(provider.models.count) model(s)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if provider.isBuiltIn {
                        Text("Built-in")
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                    }
                    if !provider.isEnabled {
                        Text("Disabled")
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }
            }
            Spacer()
            Button(action: onSelect) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isActive ? .blue : .secondary)
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ProviderDetailView (Config + Models tabs)
public struct ProviderDetailView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    let providerId: String?
    let newType: ProvidersView.NewProviderType?

    @State private var selectedTab: Int = 0
    @State private var draft: ModelProvider
    private let isNew: Bool

    public init(providerId: String? = nil, newType: ProvidersView.NewProviderType? = nil) {
        self.providerId = providerId
        self.newType = newType
        self.isNew = providerId == nil
        // Draft initialized in onAppear; use placeholder here
        if let nt = newType {
            let p: ModelProvider
            if nt == .anthropic {
                p = ModelProvider(name: "", type: .anthropic, baseURL: "https://api.anthropic.com/v1", defaultModelId: "")
            } else {
                p = ModelProvider(name: "", type: .custom, defaultModelId: "")
            }
            _draft = State(initialValue: p)
        } else {
            _draft = State(initialValue: ModelProvider(name: "", type: .custom, defaultModelId: ""))
        }
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !isNew {
                    Picker("", selection: $selectedTab) {
                        Text("Configuration").tag(0)
                        Text("Models").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                if selectedTab == 0 {
                    ProviderConfigTab(draft: $draft, isNew: isNew) {
                        if isNew {
                            state.addProvider(draft)
                            dismiss()
                        } else {
                            state.updateProvider(draft)
                        }
                    } onDelete: {
                        state.deleteProvider(id: draft.id)
                        dismiss()
                    } onReset: {
                        state.resetProvider(id: draft.id)
                        if let p = state.providers.first(where: { $0.id == draft.id }) {
                            draft = p
                        }
                    }
                } else {
                    ProviderModelsTab(provider: $draft)
                }
            }
            .navigationTitle(isNew ? "New Provider" : draft.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isNew {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .onAppear {
                if let pid = providerId,
                   let p = state.providers.first(where: { $0.id == pid }) {
                    draft = p
                }
            }
            .onChange(of: state.providers) {
                if let pid = providerId,
                   let p = state.providers.first(where: { $0.id == pid }) {
                    draft = p
                }
            }
        }
    }
}

// MARK: - ProviderConfigTab
private struct ProviderConfigTab: View {
    @EnvironmentObject private var state: AppState
    @Binding var draft: ModelProvider
    let isNew: Bool
    let onSave: () -> Void
    let onDelete: () -> Void
    let onReset: () -> Void

    @State private var showApiKey = false
    @State private var isTesting = false
    @State private var statusMessage: String? = nil
    @State private var showDeleteAlert = false
    @State private var showResetAlert = false
    @State private var newHeaderKey = ""
    @State private var newHeaderVal = ""

    var body: some View {
        Form {
            // Connection
            Section(header: Text("Connection")) {
                TextField("Name", text: $draft.name)
                TextField("Base URL", text: $draft.baseURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                HStack {
                    if showApiKey {
                        TextField("API Key", text: $draft.apiKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("API Key", text: $draft.apiKey)
                    }
                    Button(action: { showApiKey.toggle() }) {
                        Image(systemName: showApiKey ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                if draft.type == .anthropic {
                    TextField("anthropic-version", text: $draft.anthropicVersion)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }

            // Endpoint mode (non-Anthropic only)
            if draft.type != .anthropic {
                Section(header: Text("Endpoint Mode")) {
                    Picker("Mode", selection: $draft.endpointMode) {
                        Text("Chat Completions").tag("chat_completions")
                        Text("Responses API").tag("responses")
                    }
                    .pickerStyle(.segmented)
                    if draft.endpointMode == "responses" {
                        Toggle("Server-Side Web Search", isOn: $draft.hostedWebSearchEnabled)
                    }
                }
            }

            // Headers
            Section(header: Text("Custom Headers")) {
                ForEach($draft.customHeaders) { $h in
                    HStack {
                        Text(h.key).font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(h.value).font(.system(size: 12, design: .monospaced)).foregroundColor(.secondary)
                    }
                }
                .onDelete { idx in draft.customHeaders.remove(atOffsets: idx) }
                HStack {
                    TextField("Header", text: $newHeaderKey).font(.system(size: 13))
                    TextField("Value", text: $newHeaderVal).font(.system(size: 13))
                    Button(action: {
                        guard !newHeaderKey.isEmpty else { return }
                        draft.customHeaders.append(CustomHeader(key: newHeaderKey, value: newHeaderVal))
                        newHeaderKey = ""
                        newHeaderVal = ""
                    }) {
                        Image(systemName: "plus.circle.fill").foregroundColor(.blue)
                    }
                }
            }

            // Preferences
            Section(header: Text("Preferences")) {
                Toggle("Enable Provider", isOn: $draft.isEnabled)
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Prompt").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $draft.systemPrompt)
                        .frame(minHeight: 80)
                        .font(.system(size: 13))
                }
            }

            // Test + Save
            Section {
                Button(action: testConnection) {
                    HStack {
                        if isTesting { ProgressView().scaleEffect(0.8) }
                        Text(isTesting ? "Testing…" : "Test Connection")
                    }
                }.disabled(isTesting)

                if let msg = statusMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(msg.lowercased().contains("success") ? .green : .red)
                }

                Button(action: onSave) {
                    Text(isNew ? "Create Provider" : "Save Configuration")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
                .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // Danger zone
            if !isNew {
                Section {
                    if draft.isBuiltIn {
                        Button("Reset to Defaults", role: .destructive) { showResetAlert = true }
                    } else {
                        Button("Remove Provider", role: .destructive) { showDeleteAlert = true }
                    }
                }
            }
        }
        .alert("Remove Provider", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will permanently remove \"\(draft.name)\"." ) }
        .alert("Reset Provider", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive, action: onReset)
            Button("Cancel", role: .cancel) {}
        } message: { Text("Reset \"\(draft.name)\" to factory defaults? Your API key will be preserved.") }
    }

    private func testConnection() {
        isTesting = true
        statusMessage = "Testing…"
        Task {
            do {
                let urlStr = draft.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/models"
                guard let url = URL(string: urlStr) else { throw URLError(.badURL) }
                var req = URLRequest(url: url)
                if !draft.apiKey.isEmpty {
                    req.setValue("Bearer \(draft.apiKey)", forHTTPHeaderField: "Authorization")
                }
                for h in draft.customHeaders { req.setValue(h.value, forHTTPHeaderField: h.key) }
                let (_, resp) = try await URLSession.shared.data(for: req)
                await MainActor.run {
                    let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                    statusMessage = code < 300 ? "Success: HTTP \(code)" : "Failed: HTTP \(code)"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Failed: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
}

// MARK: - ProviderModelsTab
private struct ProviderModelsTab: View {
    @EnvironmentObject private var state: AppState
    @Binding var provider: ModelProvider
    @State private var searchQuery = ""
    @State private var isFetching = false
    @State private var fetchMessage: String? = nil
    @State private var editingModel: ModelDefinition? = nil
    @State private var isCreatingModel = false
    @State private var modelToDelete: ModelDefinition? = nil

    var filteredModels: [ModelDefinition] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return provider.models }
        return provider.models.filter {
            $0.name.lowercased().contains(q) || $0.id.lowercased().contains(q)
        }
    }

    var body: some View {
        List {
            Section(header: Text("Model Management")) {
                Button(action: fetchModels) {
                    HStack {
                        if isFetching { ProgressView().scaleEffect(0.8) }
                        Label(isFetching ? "Fetching…" : "Pull from Remote", systemImage: "arrow.down.circle.fill")
                    }
                }.disabled(isFetching)

                Button(action: {
                    isCreatingModel = true
                    editingModel = ModelDefinition(id: UUID().uuidString, name: "Custom Model")
                }) {
                    Label("Add Custom Model", systemImage: "plus.circle.fill")
                }

                if let msg = fetchMessage {
                    Text(msg).font(.caption)
                        .foregroundColor(msg.lowercased().contains("success") || msg.first?.isNumber == true ? .green : .secondary)
                }
            }

            Section(header: Text("\(provider.models.count) Model(s)")) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search models…", text: $searchQuery).autocorrectionDisabled()
                }
                
                if filteredModels.isEmpty {
                    Text(provider.models.isEmpty ? "No models yet. Pull from remote or add manually." : "No matching models.")
                        .foregroundColor(.secondary).font(.subheadline)
                        .padding(.vertical, 8)
                } else {
                    ForEach(filteredModels) { model in
                        ModelRow(model: model, isActive: model.id == state.selectedConversation?.modelId) {
                            editingModel = model
                            isCreatingModel = false
                        } onSelect: {
                            if var conv = state.selectedConversation {
                                conv.modelId = model.id
                                state.selectedConversation = conv
                            }
                        }
                    }
                    .onDelete { idx in
                        let toDelete = idx.map { filteredModels[$0] }
                        toDelete.forEach { state.deleteModel(from: provider.id, modelId: $0.id) }
                    }
                }
            }
        }
        .sheet(item: $editingModel) { model in
            ModelEditSheet(
                model: model,
                isNew: isCreatingModel,
                onSave: { updated in
                    if isCreatingModel {
                        state.addModel(to: provider.id, model: updated)
                    } else {
                        state.updateModel(in: provider.id, model: updated)
                    }
                    editingModel = nil
                },
                onCancel: { editingModel = nil }
            )
        }
    }

    private func fetchModels() {
        isFetching = true
        fetchMessage = nil
        Task {
            await state.fetchModels(for: provider.id)
            await MainActor.run {
                isFetching = false
                let count = state.providers.first(where: { $0.id == provider.id })?.models.count ?? 0
                fetchMessage = "\(count) models synced"
            }
        }
    }
}

private struct ModelRow: View {
    let model: ModelDefinition
    let isActive: Bool
    let onEdit: () -> Void
    let onSelect: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(model.name).font(.system(size: 15, weight: .medium))
                Text(model.id).font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                HStack(spacing: 6) {
                    if model.supportsVision {
                        Label("Vision", systemImage: "eye.fill").font(.caption2).foregroundColor(.secondary)
                    }
                    if model.supportsReasoning {
                        Label("Reasoning", systemImage: "brain").font(.caption2).foregroundColor(.purple)
                    }
                    if isActive {
                        Text("Active").font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1)).foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
            Spacer()
            Button(action: onEdit) {
                Image(systemName: "slider.horizontal.3").foregroundColor(.secondary)
            }.buttonStyle(.plain)
            Button(action: onSelect) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isActive ? .blue : .secondary)
            }.buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ModelEditSheet
struct ModelEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let model: ModelDefinition
    let isNew: Bool
    let onSave: (ModelDefinition) -> Void
    let onCancel: () -> Void

    @State private var displayName: String
    @State private var modelId: String
    @State private var supportsVision: Bool
    @State private var supportsReasoning: Bool
    @State private var contextWindowText: String

    init(model: ModelDefinition, isNew: Bool, onSave: @escaping (ModelDefinition) -> Void, onCancel: @escaping () -> Void) {
        self.model = model
        self.isNew = isNew
        self.onSave = onSave
        self.onCancel = onCancel
        _displayName = State(initialValue: isNew ? "" : model.name)
        _modelId = State(initialValue: isNew ? "" : model.id)
        _supportsVision = State(initialValue: model.supportsVision)
        _supportsReasoning = State(initialValue: model.supportsReasoning)
        _contextWindowText = State(initialValue: model.contextWindowOverride.map { String($0) } ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Model Info")) {
                    TextField("Display Name", text: $displayName)
                    TextField("Model ID", text: $modelId)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.system(size: 14, design: .monospaced))
                }
                Section(header: Text("Capabilities")) {
                    Toggle("Supports Vision", isOn: $supportsVision)
                    Toggle("Supports Reasoning", isOn: $supportsReasoning)
                }
                Section(header: Text("Context Window"), footer: Text("Leave blank to use the provider default.")) {
                    TextField("e.g. 128000", text: $contextWindowText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(isNew ? "Add Model" : "Edit Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let ctxOverride = Int(contextWindowText.trimmingCharacters(in: .whitespaces))
                        let updated = ModelDefinition(
                            id: isNew ? UUID().uuidString : model.id,
                            name: displayName.trimmingCharacters(in: .whitespaces).isEmpty ? modelId : displayName.trimmingCharacters(in: .whitespaces),
                            supportsVision: supportsVision,
                            supportsReasoning: supportsReasoning,
                            contextWindow: ctxOverride ?? model.contextWindow,
                            contextWindowOverride: ctxOverride
                        )
                        onSave(updated)
                    }
                    .disabled(modelId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
