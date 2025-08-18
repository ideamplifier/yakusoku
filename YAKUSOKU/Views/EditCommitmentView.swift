import SwiftUI
import SwiftData

struct EditCommitmentView: View {
    let commitment: Commitment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var pros: String
    @State private var cons: String
    @State private var ifThen: String
    
    init(commitment: Commitment) {
        self.commitment = commitment
        _title = State(initialValue: commitment.title)
        _pros = State(initialValue: commitment.pros ?? "")
        _cons = State(initialValue: commitment.cons ?? "")
        _ifThen = State(initialValue: commitment.ifThen ?? "")
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("약속", text: $title)
                        .font(.headline)
                } header: {
                    Label("나와의 약속", systemImage: "star.fill")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("지켰을 때 장점", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundStyle(.green)
                            
                            TextEditor(text: $pros)
                                .frame(minHeight: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.2))
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("어겼을 때 단점", systemImage: "xmark.circle")
                                .font(.caption)
                                .foregroundStyle(.red)
                            
                            TextEditor(text: $cons)
                                .frame(minHeight: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.2))
                                )
                        }
                    }
                } header: {
                    Text("동기부여")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("If-Then 전략")
                        
                        TextEditor(text: $ifThen)
                            .frame(minHeight: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2))
                            )
                    }
                } header: {
                    Text("실행 의도")
                }
            }
            .navigationTitle("약속 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private func saveChanges() {
        commitment.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        commitment.pros = pros.isEmpty ? nil : pros
        commitment.cons = cons.isEmpty ? nil : cons
        commitment.ifThen = ifThen.isEmpty ? nil : ifThen
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let commitment = Commitment(
        title: "인스턴트 식품 안 먹기",
        pros: "피부가 좋아짐",
        cons: "피부가 안 좋아짐",
        ifThen: "편의점에 들어가면 따뜻한 차를 산다"
    )
    
    return EditCommitmentView(commitment: commitment)
        .modelContainer(for: Commitment.self)
}