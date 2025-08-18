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
    let title: String
    let subtitle: String?
    let weekDots: [Rating?]
    let todayRating: Rating?
    let onRatingTap: (Rating) -> Void
    
    var body: some View {
        HStack(spacing: YK.Space.md) {
            VStack(alignment: .leading, spacing: YK.Space.xs) {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(theme.ink)
                    .lineLimit(1)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(theme.inkMuted)
                }
                
                // Week dots
                HStack(spacing: 4) {
                    ForEach(0..<7) { index in
                        Circle()
                            .fill(colorForRating(index < weekDots.count ? weekDots[index] : nil))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            
            Spacer()
            
            // Rating selector (3 buttons)
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
        .padding(YK.Space.md)
    }
    
    private func colorForRating(_ rating: Rating?) -> Color {
        switch rating {
        case .good: return YK.ColorToken.green
        case .meh: return YK.ColorToken.yellow
        case .poor: return YK.ColorToken.red
        case nil: return YK.ColorToken.line.opacity(0.3)
        }
    }
}

// HapticFeedback is imported from ZenStyle.swift

// MARK: - Week Progress Component
struct YKWeekProgress: View {
    @Environment(\.yakusokuTheme) var theme
    let completed: Int
    let total: Int
    let successRate: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: YK.Space.xxs) {
                Text("이번 주")
                    .font(.system(size: 12))
                    .foregroundColor(theme.inkMuted)
                
                HStack(spacing: YK.Space.xs) {
                    Text("\(completed)/\(total)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(theme.ink)
                    
                    Text("\(Int(successRate * 100))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(YK.ColorToken.green)
                        .padding(.horizontal, YK.Space.xs)
                        .padding(.vertical, 2)
                        .background(YK.ColorToken.green.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            TrafficDots()
        }
    }
}