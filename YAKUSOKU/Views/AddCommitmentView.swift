import SwiftUI
import SwiftData

struct AddCommitmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.yakusokuTheme) private var theme
    
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
                VStack(spacing: YK.Space.lg) {
                    titleSection
                    motivationSection
                    strategySection
                    
                    Spacer(minLength: YK.Space.xxl)
                }
                .padding(YK.Space.lg)
            }
            .background(theme.paper.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        TrafficDots(size: 6)
                        Text("새로운 약속")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.ink)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .font(.system(size: 16))
                    .foregroundColor(theme.ink)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        saveCommitment()
                        HapticFeedback.success()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canSave ? YK.ColorToken.green : theme.inkMuted.opacity(0.4))
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var titleSection: some View {
        theme.card {
            VStack(alignment: .leading, spacing: YK.Space.sm) {
                Text("약속")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.inkMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                TextField("예: 매일 운동하기", text: $title)
                    .font(.system(size: 16))
                    .padding(YK.Space.sm)
                    .background(theme.paper.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: YK.Radius.md)
                            .stroke(theme.line, lineWidth: 1)
                    )
                
                Text("구체적이고 측정 가능한 약속을 적어주세요")
                    .font(.system(size: 12))
                    .foregroundColor(theme.inkMuted)
            }
        }
    }
    
    private var motivationSection: some View {
        theme.card {
            VStack(alignment: .leading, spacing: YK.Space.md) {
                Text("동기부여")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
                
                VStack(alignment: .leading, spacing: YK.Space.sm) {
                    HStack(spacing: YK.Space.xs) {
                        Circle()
                            .fill(YK.ColorToken.green)
                            .frame(width: 8, height: 8)
                        Text("지켰을 때 장점")
                            .font(.system(size: 13))
                            .foregroundColor(theme.inkMuted)
                    }
                    
                    TextEditor(text: $pros)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 14))
                        .frame(minHeight: 60)
                        .padding(YK.Space.xs)
                        .background(theme.paper.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: YK.Radius.md)
                                .stroke(theme.line, lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: YK.Space.sm) {
                    HStack(spacing: YK.Space.xs) {
                        Circle()
                            .fill(YK.ColorToken.red)
                            .frame(width: 8, height: 8)
                        Text("어겼을 때 단점")
                            .font(.system(size: 13))
                            .foregroundColor(theme.inkMuted)
                    }
                    
                    TextEditor(text: $cons)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 14))
                        .frame(minHeight: 60)
                        .padding(YK.Space.xs)
                        .background(theme.paper.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: YK.Radius.md)
                                .stroke(theme.line, lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private var strategySection: some View {
        theme.card {
            VStack(alignment: .leading, spacing: YK.Space.md) {
                HStack {
                    Text("실행 의도")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.ink)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingExamples.toggle()
                        }
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.inkMuted)
                    }
                }
                
                VStack(alignment: .leading, spacing: YK.Space.sm) {
                    Text("If-Then 전략")
                        .font(.system(size: 13))
                        .foregroundColor(theme.inkMuted)
                    
                    TextEditor(text: $ifThen)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 14))
                        .frame(minHeight: 60)
                        .padding(YK.Space.xs)
                        .background(theme.paper.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: YK.Radius.md)
                                .stroke(theme.line, lineWidth: 1)
                        )
                }
                
                if showingExamples {
                    VStack(alignment: .leading, spacing: YK.Space.xs) {
                        Text("예시:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.inkMuted)
                        
                        VStack(alignment: .leading, spacing: YK.Space.xxs) {
                            Text("• 스트레스 받으면 → 5분 산책을 한다")
                            Text("• 야식이 땡기면 → 물 한 잔 마시고 10분 기다린다")
                            Text("• 편의점에 가면 → 과일과 물을 산다")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(theme.inkMuted.opacity(0.8))
                    }
                    .padding(YK.Space.sm)
                    .background(theme.line.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: YK.Radius.md))
                }
                
                Button {
                    addSampleCommitment()
                    HapticFeedback.light()
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14, weight: .medium))
                        Text("예시 채우기")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(theme.inkMuted)
                    .frame(maxWidth: .infinity)
                    .padding(YK.Space.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: YK.Radius.md)
                            .stroke(theme.line, lineWidth: 1)
                    )
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
        title = "매일 30분 운동하기"
        pros = "체력이 좋아지고, 스트레스가 줄어들고, 건강해짐"
        cons = "체력이 떨어지고, 스트레스가 쌓이고, 건강이 나빠짐"
        ifThen = "퇴근하면 → 바로 운동복으로 갈아입는다"
    }
}

#Preview {
    AddCommitmentView()
        .environment(\.yakusokuTheme, MinimalRetroTheme())
        .modelContainer(for: Commitment.self)
}