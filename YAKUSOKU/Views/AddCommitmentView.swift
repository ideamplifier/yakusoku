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
            ScrollView {
                VStack(spacing: 20) {
                    // 약속 제목
                    VStack(alignment: .leading, spacing: 12) {
                        Label("나와의 약속", systemImage: "star.fill")
                            .font(.headline)
                            .foregroundStyle(YKColor.green)
                        
                        TextField("예: 인스턴트 식품 안 먹기", text: $title)
                            .font(.headline)
                            .padding(16)
                            .background(YKColor.mint.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(YKColor.ink.opacity(0.2), lineWidth: 1.5)
                            )
                        
                        Text("구체적이고 측정 가능한 약속을 적어주세요")
                            .font(.caption)
                            .foregroundStyle(YKColor.secondaryText)
                    }
                    .stickerCard()
                    
                    // 동기부여
                    VStack(alignment: .leading, spacing: 16) {
                        Text("동기부여")
                            .font(.headline)
                            .foregroundStyle(YKColor.primaryText)
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("지켰을 때 장점", systemImage: "checkmark.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(YKColor.green)
                                
                                TextEditor(text: $pros)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(YKColor.green.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(YKColor.green.opacity(0.3), lineWidth: 1.5)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("어겼을 때 단점", systemImage: "xmark.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(YKColor.red)
                                
                                TextEditor(text: $cons)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(YKColor.red.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(YKColor.red.opacity(0.3), lineWidth: 1.5)
                                    )
                            }
                        }
                        
                        Text("장단점을 구체적으로 적으면 동기부여에 도움이 됩니다")
                            .font(.caption)
                            .foregroundStyle(YKColor.secondaryText)
                    }
                    .stickerCard()
                    
                    // If-Then 전략
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("실행 의도")
                                .font(.headline)
                                .foregroundStyle(YKColor.primaryText)
                            
                            Button {
                                withAnimation(.spring(duration: 0.3)) {
                                    showingExamples.toggle()
                                }
                            } label: {
                                Image(systemName: showingExamples ? "questionmark.circle.fill" : "questionmark.circle")
                                    .foregroundStyle(YKColor.green)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("If-Then 전략")
                                .font(.subheadline)
                                .foregroundStyle(YKColor.green)
                            
                            TextEditor(text: $ifThen)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 80)
                                .padding(12)
                                .background(YKColor.mint.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(YKColor.ink.opacity(0.2), lineWidth: 1.5)
                                )
                        }
                        
                        if showingExamples {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("예시:")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(YKColor.primaryText)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("• 편의점에 들어가면 → 따뜻한 차와 바나나를 산다")
                                    Text("• 야식이 땡기면 → 물 한 잔 마시고 10분 기다린다")
                                    Text("• 스트레스 받으면 → 5분 산책을 한다")
                                }
                                .font(.caption)
                                .foregroundStyle(YKColor.secondaryText)
                            }
                            .padding(16)
                            .background(YKColor.mint.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
                        Text("특정 상황에서 어떻게 행동할지 미리 정해두세요")
                            .font(.caption)
                            .foregroundStyle(YKColor.secondaryText)
                    }
                    .stickerCard()
                    
                    // 예시 버튼
                    Button {
                        addSampleCommitment()
                        HapticFeedback.light()
                    } label: {
                        Label("예시 약속 채우기", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(YKColor.green.opacity(0.1))
                            .foregroundStyle(YKColor.green)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(YKColor.green.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(YKColor.cream)
            .navigationTitle("새로운 약속")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(YKColor.secondaryText)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        saveCommitment()
                        HapticFeedback.success()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(canSave ? YKColor.green : YKColor.tertiaryText)
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