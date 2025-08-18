import SwiftUI

// MARK: - Zen Garden Color Theme
enum ZenColors {
    // 기본 색상
    static let background = Color(hex: "F8FAF5")  // 연한 민트 그레이
    static let cardBackground = Color.white
    static let secondaryBackground = Color(hex: "E8F5E3")
    
    // 액센트 색상
    static let primaryGreen = Color(hex: "4CAF50")  // 메인 그린
    static let secondaryGreen = Color(hex: "81C784")  // 연한 그린
    static let tertiaryGreen = Color(hex: "C8E6C9")  // 아주 연한 그린
    
    // 평가 색상
    static let goodColor = Color(hex: "66BB6A")  // 성공 그린
    static let mehColor = Color(hex: "FFB74D")  // 보통 오렌지
    static let poorColor = Color(hex: "EF5350")  // 실패 레드
    
    // 텍스트 색상
    static let primaryText = Color(hex: "2E3D27")
    static let secondaryText = Color(hex: "5C6B53")
    static let tertiaryText = Color(hex: "8A9682")
}

// MARK: - Zen Style Modifiers
struct ZenCardStyle: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                ZStack {
                    Color.white
                    LinearGradient(
                        colors: [
                            Color.white,
                            ZenColors.tertiaryGreen.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                ZenColors.primaryGreen.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: ZenColors.primaryGreen.opacity(0.08),
                radius: 20,
                x: 0,
                y: 10
            )
            .scaleEffect(isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onTapGesture { }
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: .infinity,
                pressing: { pressing in
                    isPressed = pressing
                },
                perform: { }
            )
    }
}

struct ZenButtonStyle: ButtonStyle {
    let isSelected: Bool
    let selectionColor: Color?
    
    init(isSelected: Bool, selectionColor: Color? = nil) {
        self.isSelected = isSelected
        self.selectionColor = selectionColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let color = selectionColor ?? ZenColors.primaryGreen
        
        return configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .background(
                ZStack {
                    if isSelected {
                        color.opacity(0.15)
                    } else {
                        Color.white.opacity(0.8)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? color.opacity(0.4) : Color.gray.opacity(0.1),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isSelected ? color.opacity(0.15) : Color.black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                y: 2
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct ZenGlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

struct ZenFloatingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        ZenColors.primaryGreen,
                        ZenColors.secondaryGreen
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(Circle())
            .shadow(
                color: ZenColors.primaryGreen.opacity(0.3),
                radius: configuration.isPressed ? 8 : 12,
                y: configuration.isPressed ? 4 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - View Extensions
extension View {
    func zenCard() -> some View {
        modifier(ZenCardStyle())
    }
    
    func zenGlass() -> some View {
        modifier(ZenGlassBackground())
    }
    
    func zenButton(isSelected: Bool = false, selectionColor: Color? = nil) -> some View {
        buttonStyle(ZenButtonStyle(isSelected: isSelected, selectionColor: selectionColor))
    }
    
    func zenFloatingButton() -> some View {
        buttonStyle(ZenFloatingButton())
    }
}

// MARK: - Haptic Feedback Helper
struct HapticFeedback {
    static func light() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.prepare()
        impact.impactOccurred()
    }
    
    static func medium() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()
    }
    
    static func success() {
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.success)
    }
    
    static func warning() {
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.warning)
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}