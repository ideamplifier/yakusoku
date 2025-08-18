import SwiftUI
import SwiftData

struct AddCommitmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var pros = ""
    @State private var cons = ""
    @State private var ifThen = ""
    @State private var showingExamples = false
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("예: 인스턴트 식품 안 먹기", text: $title)
                        .font(.headline)
                } header: {
                    Label("나와의 약속", systemImage: "star.fill")
                } footer: {
                    Text("구체적이고 측정 가능한 약속을 적어주세요")
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
                } footer: {
                    Text("장단점을 구체적으로 적으면 동기부여에 도움이 됩니다")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("If-Then 전략")
                            
                            Button {
                                showingExamples.toggle()
                            } label: {
                                Image(systemName: "questionmark.circle")
                                    .foregroundStyle(.tint)
                            }
                        }
                        
                        TextEditor(text: $ifThen)
                            .frame(minHeight: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2))
                            )
                        
                        if showingExamples {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("예시:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text("• 편의점에 들어가면 → 따뜻한 차와 바나나를 산다")
                                    .font(.caption)
                                Text("• 야식이 땡기면 → 물 한 잔 마시고 10분 기다린다")
                                    .font(.caption)
                                Text("• 스트레스 받으면 → 5분 산책을 한다")
                                    .font(.caption)
                            }
                            .padding(12)
                            .background(Color.secondary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                } header: {
                    Text("실행 의도")
                } footer: {
                    Text("특정 상황에서 어떻게 행동할지 미리 정해두세요")
                }
                
                Section {
                    Button {
                        addSampleCommitment()
                    } label: {
                        Label("예시 약속 채우기", systemImage: "wand.and.stars")
                    }
                }
            }
            .navigationTitle("새로운 약속")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        saveCommitment()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private func saveCommitment() {
        let commitment = Commitment(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            pros: pros.isEmpty ? nil : pros,
            cons: cons.isEmpty ? nil : cons,
            ifThen: ifThen.isEmpty ? nil : ifThen,
            priority: 0
        )
        
        modelContext.insert(commitment)
        try? modelContext.save()
        dismiss()
    }
    
    private func addSampleCommitment() {
        title = "인스턴트 식품 안 먹기"
        pros = "피부가 좋아지고, 컨디션이 좋아지고, 노화가 늦춰짐"
        cons = "피부가 안 좋아지고, 컨디션이 나빠지고, 노화가 촉진됨"
        ifThen = "편의점에 들어가면 → 따뜻한 차와 바나나를 산다"
    }
}

#Preview {
    AddCommitmentView()
        .modelContainer(for: Commitment.self)
}