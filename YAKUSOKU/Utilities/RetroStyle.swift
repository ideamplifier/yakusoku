import SwiftUI

// MARK: - Retro Color Tokens
struct YKColor {
    static let ink = Color(hex: "#1E1E1E")
    static let cream = Color(hex: "#FFF8EF")
    static let red = Color(hex: "#FD5A46")
    static let yellow = Color(hex: "#FFC567")
    static let green = Color(hex: "#00995E")
    static let card = Color.white
    
    // Support tints
    static let peach = Color(hex: "FFD9C7")
    static let mint = Color(hex: "D6F4E6")
    
    // Text colors
    static let primaryText = ink
    static let secondaryText = ink.opacity(0.6)
    static let tertiaryText = ink.opacity(0.3)
}

// MARK: - StickerCard Modifier
struct StickerCard: ViewModifier {
    var corner: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading) // 배경보다 먼저 확장
            .background(YKColor.card)
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(YKColor.ink, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2) // 톤 다운된 그림자
    }
}

extension View {
    func stickerCard(corner: CGFloat = 20) -> some View {
        modifier(StickerCard(corner: corner))
    }
}

// MARK: - RetroButton Style
struct RetroButtonStyle: ButtonStyle {
    enum Kind {
        case red, green, yellow
        
        var color: Color {
            switch self {
            case .red: return YKColor.red
            case .green: return YKColor.green
            case .yellow: return YKColor.yellow
            }
        }
    }
    
    var kind: Kind = .green
    var isCompact: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .kerning(0.2)
            .foregroundStyle(.white)
            .padding(.vertical, isCompact ? 10 : 14)
            .padding(.horizontal, isCompact ? 16 : 20)
            .frame(maxWidth: isCompact ? nil : .infinity)
            .background(kind.color)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(YKColor.ink, lineWidth: 1.5)
            )
            .cornerRadius(16)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

extension View {
    func retroButton(_ kind: RetroButtonStyle.Kind = .green, isCompact: Bool = false) -> some View {
        buttonStyle(RetroButtonStyle(kind: kind, isCompact: isCompact))
    }
}

// MARK: - TrafficScorePicker (못함/보통/잘함)
enum Score: String, CaseIterable, Identifiable {
    case poor = "못함"
    case meh = "보통"
    case good = "잘함"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .poor: return YKColor.red
        case .meh: return YKColor.yellow
        case .good: return YKColor.green
        }
    }
    
    // Rating enum과 매핑
    init(from rating: Rating) {
        switch rating {
        case .poor: self = .poor
        case .meh: self = .meh
        case .good: self = .good
        }
    }
    
    var toRating: Rating {
        switch self {
        case .poor: return .poor
        case .meh: return .meh
        case .good: return .good
        }
    }
}

struct TrafficScorePicker: View {
    @Binding var selection: Score
    
    var body: some View {
        ZStack {
            // 바깥 캡슐: 한 겹 라인만
            Capsule()
                .fill(.white)
                .overlay(Capsule().stroke(YKColor.ink, lineWidth: 1.5))
            
            // 선택 하이라이트(한 개만 채움)
            GeometryReader { geo in
                let w = geo.size.width / 3
                let h = geo.size.height
                let x: CGFloat = {
                    switch selection {
                    case .poor: return 0
                    case .meh: return w
                    case .good: return 2 * w
                    }
                }()
                
                RoundedRectangle(cornerRadius: h/2 - 3, style: .continuous)
                    .fill(selection.color)
                    .frame(width: w - 6, height: h - 6)
                    .offset(x: x + 3, y: 3)
                    .animation(.spring(response: 0.22, dampingFraction: 0.9), value: selection)
            }
            
            // 라벨과 구분선
            HStack(spacing: 0) {
                segmentLabel("못함", score: .poor)
                
                Rectangle()
                    .fill(YKColor.ink.opacity(0.15))
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                segmentLabel("보통", score: .meh)
                
                Rectangle()
                    .fill(YKColor.ink.opacity(0.15))
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                segmentLabel("잘함", score: .good)
            }
        }
        .frame(height: 48)
    }
    
    private func segmentLabel(_ text: String, score: Score) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(selection == score ? .white : YKColor.ink)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
                    selection = score
                    HapticFeedback.light()
                }
            }
    }
}

// MARK: - Simple Face Component
struct SimpleFace: View {
    let score: Score
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // 눈
            HStack(spacing: 8) {
                Circle()
                    .frame(width: 4, height: 4)
                Circle()
                    .frame(width: 4, height: 4)
            }
            .offset(y: -4)
            
            // 입
            Path { path in
                switch score {
                case .poor:
                    // 슬픈 입
                    path.move(to: CGPoint(x: 8, y: 8))
                    path.addQuadCurve(
                        to: CGPoint(x: 24, y: 8),
                        control: CGPoint(x: 16, y: 14)
                    )
                case .meh:
                    // 일자 입
                    path.move(to: CGPoint(x: 10, y: 10))
                    path.addLine(to: CGPoint(x: 22, y: 10))
                case .good:
                    // 웃는 입
                    path.move(to: CGPoint(x: 8, y: 6))
                    path.addQuadCurve(
                        to: CGPoint(x: 24, y: 6),
                        control: CGPoint(x: 16, y: 14)
                    )
                }
            }
            .stroke(isSelected ? Color.white : YKColor.ink, lineWidth: 2)
        }
        .foregroundStyle(isSelected ? .white : YKColor.ink)
    }
}

// MARK: - Retro Tag/Pill
struct RetroTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 13).weight(.medium))
            .foregroundStyle(YKColor.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.16))
            .clipShape(Capsule())
    }
}

// MARK: - Floating Action Button
struct RetroFloatingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(16)
            .background(YKColor.green)
            .foregroundStyle(.white)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(YKColor.ink, lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    func retroFloatingButton() -> some View {
        buttonStyle(RetroFloatingButton())
    }
}