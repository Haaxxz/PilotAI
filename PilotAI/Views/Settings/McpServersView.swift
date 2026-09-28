import SwiftUI

public struct McpServersView: View {
    @EnvironmentObject private var state: AppState
    @State private var showAddSheet = false
    @State private var editingServer: McpServer? = nil
    
    public init() {}
    
    public var body: some View {
        List {
            Section(header: Text("Model Context Protocol (MCP)")) {
                Text("Connect external tools, databases, and services to your AI agent via MCP servers.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Configured Servers")) {
                if state.mcpServers.isEmpty {
                    Text("No MCP servers configured.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(state.mcpServers) { server in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(server.name).font(.headline)
                                Text("\(server.transportType.rawValue) · \(server.urlOrCommand)")
                                    .font(.caption).fontDesign(.monospaced)
                                    .foregroundColor(.secondary).lineLimit(1)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { server.isEnabled },
                                set: { val in
                                    var updated = server
                                    updated.isEnabled = val
                                    state.updateMcpServer(updated)
                                }
                            ))
                            .labelsHidden()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { editingServer = server }
                    }
                    .onDelete { idxSet in
                        idxSet.map { state.mcpServers[$0] }.forEach { state.deleteMcpServer(id: $0.id) }
                    }
                }
            }
            
            Section {
                Button(action: {
                    editingServer = McpServer(name: "", urlOrCommand: "http://localhost:3000/sse")
                }) {
                    Label("Add MCP Server", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("MCP Servers")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingServer) { server in
            McpServerEditorSheet(server: server) { updated in
                if state.mcpServers.contains(where: { $0.id == updated.id }) {
                    state.updateMcpServer(updated)
                } else {
                    state.addMcpServer(updated)
                }
                editingServer = nil
            } onCancel: { editingServer = nil }
        }
    }
}

struct McpServerEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let server: McpServer
    let onSave: (McpServer) -> Void
    let onCancel: () -> Void
    
    @State private var name: String
    @State private var transportType: McpServer.TransportType
    @State private var urlOrCommand: String
    @State private var isEnabled: Bool
    
    init(server: McpServer, onSave: @escaping (McpServer) -> Void, onCancel: @escaping () -> Void) {
        self.server = server
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: server.name)
        _transportType = State(initialValue: server.transportType)
        _urlOrCommand = State(initialValue: server.urlOrCommand)
        _isEnabled = State(initialValue: server.isEnabled)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Info")) {
                    TextField("Server Name", text: $name)
                    Picker("Transport", selection: $transportType) {
                        ForEach(McpServer.TransportType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField(transportType == .sse ? "Server URL (e.g. http://localhost:8080/sse)" : "Executable Command", text: $urlOrCommand)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                Section {
                    Toggle("Enable Server", isOn: $isEnabled)
                }
            }
            .navigationTitle(server.name.isEmpty ? "New MCP Server" : "Edit MCP Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel", action: onCancel) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var s = server
                        s.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        s.transportType = transportType
                        s.urlOrCommand = urlOrCommand.trimmingCharacters(in: .whitespacesAndNewlines)
                        s.isEnabled = isEnabled
                        onSave(s)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || urlOrCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
