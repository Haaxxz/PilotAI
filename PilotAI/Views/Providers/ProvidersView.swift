import SwiftUI

public struct ProviderDetailView: View {
    @EnvironmentObject private var state: AppState
    @Binding public var provider: ModelProvider
    @State private var showApiKey: Bool = false
    @State private var newHeaderKey: String = ""
    @State private var newHeaderVal: String = ""
    @State private var isTesting: Bool = false
    @State private var testResult: String? = nil
    
    public init(provider: Binding<ModelProvider>) {
        self._provider = provider
    }
    
    public var body: some View {
        Form {
            Section(header: Text("General")) {
                TextField("Provider Name", text: $provider.name)
                
                HStack {
                    Text("Type")
                    Spacer()
                    Text(provider.type.displayName)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Endpoint & Authentication")) {
                TextField("Base URL", text: $provider.baseURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                HStack {
                    if showApiKey {
                        TextField("API Key", text: $provider.apiKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("API Key", text: $provider.apiKey)
                    }
                    
                    Button(action: { showApiKey.toggle() }) {
                        Image(systemName: showApiKey ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Custom Request Headers")) {
                ForEach($provider.customHeaders) { $h in
                    HStack {
                        Text(h.key)
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(h.value)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete { indices in
                    provider.customHeaders.remove(atOffsets: indices)
                    state.saveProviders()
                }
                
                HStack {
                    TextField("Header Name", text: $newHeaderKey)
                    TextField("Value", text: $newHeaderVal)
                    Button(action: {
                        if !newHeaderKey.isEmpty {
                            provider.customHeaders.append(CustomHeader(key: newHeaderKey, value: newHeaderVal))
                            newHeaderKey = ""
                            newHeaderVal = ""
                            state.saveProviders()
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Section(header: Text("Models")) {
                ForEach(provider.models) { model in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.name)
                                .font(.system(size: 15))
                            Text(model.id)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if model.supportsVision {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        if model.supportsReasoning {
                            Image(systemName: "brain")
                                .font(.system(size: 11))
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
            
            Section {
                Button(action: testConnection) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isTesting ? "Testing Connection…" : "Test Connection")
                    }
                }
                .disabled(isTesting)
                
                if let res = testResult {
                    Text(res)
                        .font(.system(size: 13))
                        .foregroundColor(res.contains("Success") ? .green : .red)
                }
            }
        }
        .navigationTitle(provider.name)
        .onDisappear {
            state.saveProviders()
        }
    }
    
    private func testConnection() {
        isTesting = true
        testResult = nil
        
        Task {
            do {
                guard let url = URL(string: provider.baseURL) else {
                    throw URLError(.badURL)
                }
                var req = URLRequest(url: url)
                req.httpMethod = "GET"
                if !provider.apiKey.isEmpty {
                    req.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
                }
                
                let (_, response) = try await URLSession.shared.data(for: req)
                if let http = response as? HTTPURLResponse {
                    testResult = "Success: HTTP \(http.statusCode)"
                }
            } catch {
                testResult = "Failed: \(error.localizedDescription)"
            }
            isTesting = false
        }
    }
}

public struct ProvidersView: View {
    @EnvironmentObject private var state: AppState
    
    public init() {}
    
    public var body: some View {
        List {
            ForEach($state.providers) { $prov in
                NavigationLink(destination: ProviderDetailView(provider: $prov).environmentObject(state)) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prov.name)
                                .font(.system(size: 16, weight: .semibold))
                            Text("\(prov.models.count) models available")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !prov.apiKey.isEmpty {
                            Image(systemName: "key.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Model Providers")
    }
}
