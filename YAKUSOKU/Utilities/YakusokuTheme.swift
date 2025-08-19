import SwiftUI

// MARK: - Color Tokens
enum YK {
    struct ColorToken {
        static let ink = Color(hex: "#0E0F0F")
        static let paper = Color(hex: "#F5F3EF")
        static let red = Color(hex: "#E6482E")
        static let yellow = Color(hex: "#F4D35E")
        static let green = Color(hex: "#2BA84A")
        static let inkMuted = Color(hex: "#3A3A36")
        static let line = Color(hex: "#DAD7D0")
        
        // Dark mode variants
        static let inkDark = Color(hex: "#EEEEEE")
        static let paperDark = Color(hex: "#111111")
    }
    
    struct Radius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }
    
    struct Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
    }
}

// MARK: - Traffic Dots Component
struct TrafficDots: View {
    var size: CGFloat = 8
    var spacing: CGFloat = 6
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: spacing) {
            Circle()
                .fill(YK.ColorToken.red)
                .frame(width: size, height: size)
                .scaleEffect(animate ? 1.2 : 1.0)
                .animation(.spring(response: 0.3).delay(0), value: animate)
            
            Circle()
                .fill(YK.ColorToken.yellow)
                .frame(width: size, height: size)
                .scaleEffect(animate ? 1.2 : 1.0)
                .animation(.spring(response: 0.3).delay(0.1), value: animate)
            
            Circle()
                .fill(YK.ColorToken.green)
                .frame(width: size, height: size)
                .scaleEffect(animate ? 1.2 : 1.0)
                .animation(.spring(response: 0.3).delay(0.2), value: animate)
        }
        .onAppear {
            animate = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animate = false
            }
        }
    }
}

// MARK: - Theme Protocol
protocol YakusokuTheme {
    var ink: Color { get }
    var paper: Color { get }
    var inkMuted: Color { get }
    var line: Color { get }
    
    func card<Content: View>(@ViewBuilder content: () -> Content) -> AnyView
    func primaryButton(_ label: String, action: @escaping () -> Void) -> AnyView
    func ratingIndicator(_ rating: Rating?) -> AnyView
}

// MARK: - Minimal Retro Theme Implementation
struct MinimalRetroTheme: YakusokuTheme {
    @Environment(\.colorScheme) var colorScheme
    
    var ink: Color {
        colorScheme == .dark ? YK.ColorToken.inkDark : YK.ColorToken.ink
    }
    
    var paper: Color {
        colorScheme == .dark ? YK.ColorToken.paperDark : YK.ColorToken.paper
    }
    
    var inkMuted: Color {
        YK.ColorToken.inkMuted
    }
    
    var line: Color {
        YK.ColorToken.line.opacity(colorScheme == .dark ? 0.2 : 1.0)
    }
    
    func card<Content: View>(@ViewBuilder content: () -> Content) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: YK.Space.md) {
                content()
            }
            .padding(YK.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(paper)
            .overlay(
                RoundedRectangle(cornerRadius: YK.Radius.xl)
                    .stroke(line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: YK.Radius.xl))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
    
    func primaryButton(_ label: String, action: @escaping () -> Void) -> AnyView {
        AnyView(
            Button(action: {
                HapticFeedback.light()
                action()
            }) {
                Text(label)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(paper)
                    .padding(.horizontal, YK.Space.md)
                    .padding(.vertical, YK.Space.sm)
                    .frame(maxWidth: .infinity)
                    .background(ink)
                    .clipShape(RoundedRectangle(cornerRadius: YK.Radius.lg))
            }
        )
    }
    
    func ratingIndicator(_ rating: Rating?) -> AnyView {
        AnyView(
            Circle()
                .fill(colorForRating(rating))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .stroke(YK.ColorToken.line, lineWidth: 1)
                )
        )
    }
    
    private func colorForRating(_ rating: Rating?) -> Color {
        switch rating {
        case .good: return YK.ColorToken.green
        case .meh: return YK.ColorToken.yellow
        case .poor: return YK.ColorToken.red
        case nil: return YK.ColorToken.paper
        }
    }
}

// MARK: - Environment Key
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: any YakusokuTheme = MinimalRetroTheme()
}

extension EnvironmentValues {
    var yakusokuTheme: any YakusokuTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Commitment Row Component
struct YKCommitmentRow: View {
    @Environment(\.yakusokuTheme) var theme
    let commitment: Commitment
    let weekDots: [Rating?]
    let todayRating: Rating?
    let onRatingTap: (Rating) -> Void
    let onRowTap: () -> Void
    
    var body: some View {
        Button(action: onRowTap) {
            VStack(spacing: YK.Space.xs) {
                // Title
                HStack {
                    Text(commitment.title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                
                // 장점/단점 (한 줄씩만)
                VStack(alignment: .leading, spacing: 2) {
                    if let pros = commitment.pros, !pros.isEmpty {
                        HStack {
                            Text("장점: \(pros)")
                                .font(.system(size: 12))
                                .foregroundColor(theme.inkMuted)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                    if let cons = commitment.cons, !cons.isEmpty {
                        HStack {
                            Text("단점: \(cons)")
                                .font(.system(size: 12))
                                .foregroundColor(theme.inkMuted)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                }
                
                // Bottom row: Week dots, rating status, rating buttons
                HStack {
                    // Week dots with day labels (일요일부터 시작)
                    HStack(spacing: 7) {
                        ForEach(0..<7) { dayIndex in
                            let actualIndex = getActualIndex(for: dayIndex)
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(colorForRating(actualIndex < weekDots.count ? weekDots[actualIndex] : nil))
                                    .frame(width: 9, height: 9)
                                
                                Text(dayLabelFixed(for: dayIndex))
                                    .font(.system(size: 9))
                                    .foregroundColor(theme.inkMuted.opacity(0.6))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Rating status text
                    if let rating = todayRating {
                        Text(ratingText(for: rating))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(theme.ink.opacity(0.5))
                    }
                    
                    // Rating buttons
                    HStack(spacing: YK.Space.xs) {
                        ForEach([Rating.poor, Rating.meh, Rating.good], id: \.self) { rating in
                            Button {
                                onRatingTap(rating)
                            } label: {
                                Circle()
                                    .fill(todayRating == rating ? colorForRating(rating) : Color.clear)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                todayRating == rating ? colorForRating(rating) : theme.line,
                                                lineWidth: todayRating == rating ? 2 : 1
                                            )
                                    )
                            }
                        }
                    }
                }
            }
            .padding(YK.Space.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorForRating(_ rating: Rating?) -> Color {
        switch rating {
        case .good: return YK.ColorToken.green
        case .meh: return YK.ColorToken.yellow
        case .poor: return YK.ColorToken.red
        case nil: return YK.ColorToken.line.opacity(0.3)
        }
    }
    
    private func ratingText(for rating: Rating) -> String {
        switch rating {
        case .good: return "잘함"
        case .meh: return "보통"
        case .poor: return "못함"
        }
    }
    
    private func dayLabelFixed(for index: Int) -> String {
        let days = ["S", "M", "T", "W", "R", "F", "S"]
        return days[index]
    }
    
    private func getActualIndex(for dayIndex: Int) -> Int {
        // dayIndex: 0(일) 1(월) 2(화) 3(수) 4(목) 5(금) 6(토)
        // weekDots는 6일전부터 오늘까지 저장됨 (인덱스 0이 6일전, 인덱스 6이 오늘)
        let today = Date()
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: today) - 1 // 0(일) ~ 6(토)
        
        // 해당 요일이 오늘로부터 며칠 전인지 계산
        let daysAgo = (todayWeekday - dayIndex + 7) % 7
        
        // weekDots 배열의 인덱스 계산 (0=6일전, 6=오늘)
        if daysAgo <= 6 {
            return 6 - daysAgo
        }
        return -1 // 7일 이상 전은 표시하지 않음
    }
}

// HapticFeedback is imported from ZenStyle.swift

// MARK: - Week Progress Component
struct YKWeekProgress: View {
    @Environment(\.yakusokuTheme) var theme
    let weekScore: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: YK.Space.xxs) {
                Text("이번 주 나와의")
                    .font(.system(size: 12))
                    .foregroundColor(theme.inkMuted)
                
                Text("약속 점수")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(theme.ink)
            }
            
            Spacer()
            
            // 점수 표시
            HStack(spacing: 4) {
                Text("\(weekScore)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.ink)
                Text("/ 100")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.inkMuted)
            }
        }
        .padding(YK.Space.md)
        .background(Color(hex: "#F0F0F0"))
        .clipShape(RoundedRectangle(cornerRadius: YK.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: YK.Radius.xl)
                .stroke(Color(hex: "#D0D0D0"), lineWidth: 1)
        )
    }
    
    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 80...100:
            return YK.ColorToken.green
        case 60..<80:
            return YK.ColorToken.yellow
        default:
            return YK.ColorToken.red
        }
    }
}