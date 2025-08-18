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
                            .foregroundStyle(ZenColors.primaryGreen)
                        
                        TextField("예: 인스턴트 식품 안 먹기", text: $title)
                            .font(.headline)
                            .padding(16)
                            .background(ZenColors.tertiaryGreen.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(ZenColors.primaryGreen.opacity(0.2), lineWidth: 1)
                            )
                        
                        Text("구체적이고 측정 가능한 약속을 적어주세요")
                            .font(.caption)
                            .foregroundStyle(ZenColors.secondaryText)
                    }
                    .zenCard()
                    
                    // 동기부여
                    VStack(alignment: .leading, spacing: 16) {
                        Text("동기부여")
                            .font(.headline)
                            .foregroundStyle(ZenColors.primaryText)
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("지켰을 때 장점", systemImage: "checkmark.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(ZenColors.goodColor)
                                
                                TextEditor(text: $pros)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(ZenColors.goodColor.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(ZenColors.goodColor.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("어겼을 때 단점", systemImage: "xmark.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(ZenColors.poorColor)
                                
                                TextEditor(text: $cons)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                    .background(ZenColors.poorColor.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(ZenColors.poorColor.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        
                        Text("장단점을 구체적으로 적으면 동기부여에 도움이 됩니다")
                            .font(.caption)
                            .foregroundStyle(ZenColors.secondaryText)
                    }
                    .zenCard()
                    
                    // If-Then 전략
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("실행 의도")
                                .font(.headline)
                                .foregroundStyle(ZenColors.primaryText)
                            
                            Button {
                                withAnimation(.spring(duration: 0.3)) {
                                    showingExamples.toggle()
                                }
                            } label: {
                                Image(systemName: showingExamples ? "questionmark.circle.fill" : "questionmark.circle")
                                    .foregroundStyle(ZenColors.primaryGreen)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("If-Then 전략")
                                .font(.subheadline)
                                .foregroundStyle(ZenColors.secondaryGreen)
                            
                            TextEditor(text: $ifThen)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 80)
                                .padding(12)
                                .background(ZenColors.tertiaryGreen.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(ZenColors.primaryGreen.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        if showingExamples {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("예시:")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(ZenColors.primaryText)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("• 편의점에 들어가면 → 따뜻한 차와 바나나를 산다")
                                    Text("• 야식이 땡기면 → 물 한 잔 마시고 10분 기다린다")
                                    Text("• 스트레스 받으면 → 5분 산책을 한다")
                                }
                                .font(.caption)
                                .foregroundStyle(ZenColors.secondaryText)
                            }
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [ZenColors.tertiaryGreen.opacity(0.2), ZenColors.tertiaryGreen.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
                        Text("특정 상황에서 어떻게 행동할지 미리 정해두세요")
                            .font(.caption)
                            .foregroundStyle(ZenColors.secondaryText)
                    }
                    .zenCard()
                    
                    // 예시 버튼
                    Button {
                        addSampleCommitment()
                        HapticFeedback.light()
                    } label: {
                        Label("예시 약속 채우기", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [ZenColors.primaryGreen.opacity(0.1), ZenColors.secondaryGreen.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(ZenColors.primaryGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(ZenColors.primaryGreen.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(ZenColors.background)
            .navigationTitle("새로운 약속")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(ZenColors.secondaryText)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        saveCommitment()
                        HapticFeedback.success()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(canSave ? ZenColors.primaryGreen : ZenColors.tertiaryText)
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