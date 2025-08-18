import SwiftUI

struct JMColor {
    static let ink = Color(hex: "#333333")
    static let inkLight = Color(hex: "#666666")
    static let inkLighter = Color(hex: "#999999")
    
    static let paper = Color(hex: "#FFFFFF")
    static let paperGray = Color(hex: "#FAFAFA")
    static let paperDark = Color(hex: "#F5F5F5")
    
    static let line = Color(hex: "#E8E8E8")
    static let lineLighter = Color(hex: "#F0F0F0")
    
    static let accent = Color(hex: "#2C2C2C")
    static let success = Color(hex: "#7BA098")
    static let warning = Color(hex: "#D4A574")
    static let error = Color(hex: "#C47F7F")
}

struct JMTypography {
    static func title() -> Font {
        .system(size: 24, weight: .light, design: .default)
    }
    
    static func heading() -> Font {
        .system(size: 18, weight: .regular, design: .default)
    }
    
    static func body() -> Font {
        .system(size: 15, weight: .regular, design: .default)
    }
    
    static func caption() -> Font {
        .system(size: 13, weight: .regular, design: .default)
    }
    
    static func small() -> Font {
        .system(size: 11, weight: .regular, design: .default)
    }
}

struct JMSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

struct JMRadius {
    static let none: CGFloat = 0
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
}

struct JMCard<Content: View>: View {
    let content: () -> Content
    var padding: CGFloat = JMSpacing.md
    
    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(JMColor.paper)
            .overlay(
                RoundedRectangle(cornerRadius: JMRadius.md)
                    .stroke(JMColor.line, lineWidth: 0.5)
            )
    }
}

struct JMButton: ViewModifier {
    enum Style {
        case primary
        case secondary
        case text
    }
    
    let style: Style
    let isFullWidth: Bool
    
    func body(content: Content) -> some View {
        content
            .font(JMTypography.body())
            .padding(.horizontal, JMSpacing.lg)
            .padding(.vertical, JMSpacing.sm)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(backgroundForStyle)
            .foregroundColor(textColorForStyle)
            .overlay(
                RoundedRectangle(cornerRadius: JMRadius.sm)
                    .stroke(borderColorForStyle, lineWidth: 0.5)
            )
    }
    
    private var backgroundForStyle: Color {
        switch style {
        case .primary: return JMColor.accent
        case .secondary: return JMColor.paper
        case .text: return Color.clear
        }
    }
    
    private var textColorForStyle: Color {
        switch style {
        case .primary: return JMColor.paper
        case .secondary: return JMColor.ink
        case .text: return JMColor.ink
        }
    }
    
    private var borderColorForStyle: Color {
        switch style {
        case .primary: return JMColor.accent
        case .secondary: return JMColor.line
        case .text: return Color.clear
        }
    }
}

extension View {
    func jmButton(_ style: JMButton.Style = .primary, fullWidth: Bool = false) -> some View {
        modifier(JMButton(style: style, isFullWidth: fullWidth))
    }
}

struct JMDivider: View {
    var body: some View {
        Rectangle()
            .fill(JMColor.line)
            .frame(height: 0.5)
    }
}

struct JMProgress: View {
    let value: Double
    var height: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(JMColor.lineLighter)
                    .frame(height: height)
                
                Rectangle()
                    .fill(JMColor.accent)
                    .frame(width: geometry.size.width * min(max(value, 0), 1), height: height)
            }
        }
        .frame(height: height)
    }
}

struct JMBadge: View {
    let text: String
    var color: Color = JMColor.accent
    
    var body: some View {
        Text(text)
            .font(JMTypography.small())
            .padding(.horizontal, JMSpacing.xs)
            .padding(.vertical, JMSpacing.xxs)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: JMRadius.sm))
    }
}

struct JMTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .font(JMTypography.body())
            .padding(JMSpacing.sm)
            .background(JMColor.paperGray)
            .overlay(
                RoundedRectangle(cornerRadius: JMRadius.sm)
                    .stroke(JMColor.line, lineWidth: 0.5)
            )
    }
}

struct JMToggle: View {
    let label: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .font(JMTypography.body())
                .foregroundColor(JMColor.ink)
        }
        .tint(JMColor.accent)
    }
}

struct JMEmptyState: View {
    let title: String
    let subtitle: String?
    let icon: String
    
    var body: some View {
        VStack(spacing: JMSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(JMColor.inkLighter)
            
            VStack(spacing: JMSpacing.xs) {
                Text(title)
                    .font(JMTypography.heading())
                    .foregroundColor(JMColor.ink)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(JMTypography.caption())
                        .foregroundColor(JMColor.inkLight)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(JMSpacing.xxl)
    }
}

struct JMNavigationBar: ViewModifier {
    let title: String
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(JMColor.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    func jmNavigationBar(title: String) -> some View {
        modifier(JMNavigationBar(title: title))
    }
}

