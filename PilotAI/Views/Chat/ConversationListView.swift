import SwiftUI

public struct ConversationListView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            List {
                Section(header: Text("Conversations")) {
                    ForEach(state.conversations) { conv in
                        Button(action: {
                            state.selectedConversationId = conv.id
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: conv.mode.iconName)
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(conv.title)
                                        .font(.system(size: 15, weight: state.selectedConversationId == conv.id ? .semibold : .regular))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    HStack {
                                        Text(conv.modelId)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text(conv.updatedAt, style: .date)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if state.selectedConversationId == conv.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = state.conversations[index]
                            state.deleteConversation(id: item.id)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        state.newConversation()
                        dismiss()
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
    }
}
