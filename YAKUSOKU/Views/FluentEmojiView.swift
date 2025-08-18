import SwiftUI
import WebKit

// SVG를 표시하기 위한 WebView Wrapper
struct SVGWebView: UIViewRepresentable {
    let svgString: String
    let size: CGSize
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                }
                svg {
                    width: \(size.width)px;
                    height: \(size.height)px;
                }
            </style>
        </head>
        <body>
            \(svgString)
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// 간단한 플랫 이모지 (SwiftUI Native)
struct FluentEmoji: View {
    let rating: Rating
    let size: CGFloat
    
    init(rating: Rating, size: CGFloat = 32) {
        self.rating = rating
        self.size = size
    }
    
    var body: some View {
        // SVG 파일이 제대로 로드되지 않을 경우를 위한 Fallback
        ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.15))
                .frame(width: size, height: size)
            
            faceContent
                .frame(width: size * 0.7, height: size * 0.7)
        }
    }
    
    @ViewBuilder
    private var faceContent: some View {
        VStack(spacing: size * 0.15) {
            // 눈
            HStack(spacing: size * 0.2) {
                eye(isLeft: true)
                eye(isLeft: false)
            }
            
            // 입
            mouth
        }
    }
    
    @ViewBuilder
    private func eye(isLeft: Bool) -> some View {
        switch rating {
        case .poor:
            // 슬픈 눈 (아래로 기울어진)
            Ellipse()
                .fill(Color.black)
                .frame(width: size * 0.08, height: size * 0.12)
                .rotationEffect(.degrees(isLeft ? -15 : 15))
        case .meh:
            // 평범한 눈
            Circle()
                .fill(Color.black)
                .frame(width: size * 0.08, height: size * 0.08)
        case .good:
            // 웃는 눈 (반달 모양)
            Capsule()
                .fill(Color.black)
                .frame(width: size * 0.1, height: size * 0.05)
        }
    }
    
    @ViewBuilder
    private var mouth: some View {
        switch rating {
        case .poor:
            // 슬픈 입
            Path { path in
                path.move(to: CGPoint(x: 0, y: size * 0.05))
                path.addQuadCurve(
                    to: CGPoint(x: size * 0.25, y: size * 0.05),
                    control: CGPoint(x: size * 0.125, y: 0)
                )
            }
            .stroke(Color.black, lineWidth: size * 0.05)
            .frame(width: size * 0.25, height: size * 0.1)
            
        case .meh:
            // 일자 입
            Rectangle()
                .fill(Color.black)
                .frame(width: size * 0.2, height: size * 0.03)
            
        case .good:
            // 웃는 입
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addQuadCurve(
                    to: CGPoint(x: size * 0.25, y: 0),
                    control: CGPoint(x: size * 0.125, y: size * 0.1)
                )
            }
            .stroke(Color.black, lineWidth: size * 0.05)
            .frame(width: size * 0.25, height: size * 0.1)
        }
    }
}

// 대체 플랫 디자인 (더 심플)
struct MinimalFlatEmoji: View {
    let rating: Rating
    let size: CGFloat
    
    init(rating: Rating, size: CGFloat = 32) {
        self.rating = rating
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(rating.color, lineWidth: 2)
                .background(Circle().fill(rating.color.opacity(0.1)))
                .frame(width: size, height: size)
            
            Image(systemName: rating.sfSymbol)
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundStyle(rating.color)
        }
    }
}

extension Rating {
    var sfSymbol: String {
        switch self {
        case .poor: return "minus.circle"
        case .meh: return "equal.circle"
        case .good: return "plus.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .poor: return ZenColors.poorColor
        case .meh: return ZenColors.mehColor
        case .good: return ZenColors.goodColor
        }
    }
}