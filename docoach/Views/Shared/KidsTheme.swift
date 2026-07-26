import SwiftUI
import UIKit
import CoreText

/// 子供向けリデザインのデザイントークン。
/// 値は claude.ai/design の `DoCoach-Kids.dc.html` から取っている。
enum Kids {

    // MARK: - Colors

    /// 画面の下地（クリーム）
    static let bg = Color(hex: 0xFFF6E9)
    /// 画面外周のグラデーション上端／下端
    static let bgTop = Color(hex: 0xFFF3DD)
    static let bgBottom = Color(hex: 0xF6DCC0)

    static let card = Color.white
    /// カードの「ぬりつぶし影」
    static let cardShadow = Color(hex: 0xF0E4D2)

    static let blue = Color(hex: 0x3B82F6)
    static let blueLight = Color(hex: 0x5CB0FF)
    static let blueHero = Color(hex: 0x4AA8FF)
    static let blueDeep = Color(hex: 0x2469C9)

    static let orange = Color(hex: 0xFF7A3C)
    static let orangeLight = Color(hex: 0xFF9E5E)
    static let orangeDeep = Color(hex: 0xE05A1E)

    static let yellow = Color(hex: 0xFFD23F)
    static let yellowDeep = Color(hex: 0xE0A400)
    static let yellowText = Color(hex: 0x7A5200)

    static let textDark = Color(hex: 0x4A3F3A)
    static let textBody = Color(hex: 0x3A322E)
    static let textMuted = Color(hex: 0xA99B8B)
    static let textMuted2 = Color(hex: 0x8A7B6C)
    static let textFaint = Color(hex: 0xBCAF9E)

    /// 「もどる」等のベージュボタン
    static let beige = Color(hex: 0xEFE5D6)
    static let beigeDeep = Color(hex: 0xEADDCB)

    /// バーのトラック
    static let track = Color(hex: 0xF1EADF)
    static let barRed = Color(hex: 0xFF6B6B)
    static let barOrange = Color(hex: 0xFF9E3C)
    static let barGreen = Color(hex: 0x46D39A)
    static let green = Color(hex: 0x22A876)

    /// タブバーの区切り線
    static let tabBorder = Color(hex: 0xF1E7D8)

    // 選択肢の状態色
    static let choiceIdleBorder = Color(hex: 0xF0E4D2)
    static let choiceSelBorder = Color(hex: 0x3B9DF6)
    static let choiceSelBg = Color(hex: 0xEAF4FF)
    static let choiceSelText = Color(hex: 0x1E5FA8)
    static let choiceSelShadow = Color(hex: 0xC7E0F7)
    static let correctBorder = Color(hex: 0x37C98C)
    static let correctBg = Color(hex: 0xE6FAF1)
    static let correctText = Color(hex: 0x178A5E)
    static let correctShadow = Color(hex: 0xB6ECD5)
    static let wrongBorder = Color(hex: 0xFF6B6B)
    static let wrongBg = Color(hex: 0xFFECEC)
    static let wrongText = Color(hex: 0xC93B3B)
    static let wrongShadow = Color(hex: 0xF6C9C9)

    // タグバッジ
    static let tagBlueText = Color(hex: 0x3B82F6)
    static let tagBlueBg = Color(hex: 0xEAF4FF)
    static let tagBlueBorder = Color(hex: 0xBBD9F7)
    static let tagOrangeText = Color(hex: 0xE68A2E)
    static let tagOrangeBg = Color(hex: 0xFFF3E4)
    static let tagOrangeBorder = Color(hex: 0xF7D9B3)

    // MARK: - Gradients

    static var blueButton: LinearGradient {
        LinearGradient(colors: [blueLight, blue], startPoint: .top, endPoint: .bottom)
    }
    static var orangeButton: LinearGradient {
        LinearGradient(colors: [orangeLight, orange], startPoint: .top, endPoint: .bottom)
    }
    static var heroCard: LinearGradient {
        LinearGradient(colors: [blueHero, blue], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var screenBackground: LinearGradient {
        LinearGradient(colors: [bgTop, bg], startPoint: .top, endPoint: .bottom)
    }

    // MARK: - Fonts

    /// バンドルした M PLUS Rounded 1c。デザインの 400/500→Regular、700/800→Bold、900→Black に対応。
    enum Face: String {
        case regular = "MPLUSRounded1c-Regular"
        case bold = "MPLUSRounded1c-Bold"
        case black = "MPLUSRounded1c-Black"
    }

    /// `GENERATE_INFOPLIST_FILE = YES` を使っている都合上 `UIAppFonts` 配列を Info.plist に書けないため、
    /// 起動時に CoreText へ直接登録する（`docoachApp` の init から一度だけ呼ぶ）。
    static func registerFonts() {
        for face in [Face.regular, .bold, .black] {
            guard let url = Bundle.main.url(forResource: face.rawValue, withExtension: "ttf") else {
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func font(_ size: CGFloat, _ face: Face = .bold) -> Font {
        .custom(face.rawValue, size: size)
    }

    /// 本文など、ユーザーの文字サイズ設定に追随させたいところで使う。
    static func scaledFont(_ size: CGFloat, _ face: Face = .regular, relativeTo style: Font.TextStyle) -> Font {
        .custom(face.rawValue, size: size, relativeTo: style)
    }

    /// RubyTextView（UITextView ラッパー）用。登録に失敗していてもシステムフォントに落ちる。
    static func uiFont(_ size: CGFloat, _ face: Face = .regular) -> UIFont {
        UIFont(name: face.rawValue, size: size) ?? .systemFont(ofSize: size, weight: face == .regular ? .regular : .bold)
    }
}

// MARK: - ぬりつぶし影（CSS の `box-shadow: 0 Npx 0 color`）

/// 下方向にずらした単色の角丸を背面に敷いて、CSS の分厚い影を再現する。
struct HardShadow: ViewModifier {
    let radius: CGFloat
    let depth: CGFloat
    let color: Color

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(color)
                    .offset(y: depth)
            )
    }
}

extension View {
    /// 白カード＋ぬりつぶし影。
    func kidsCard(radius: CGFloat = 22, depth: CGFloat = 6, fill: Color = Kids.card, shadow: Color = Kids.cardShadow) -> some View {
        self
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
            .modifier(HardShadow(radius: radius, depth: depth, color: shadow))
            .padding(.bottom, depth)
    }

    func hardShadow(radius: CGFloat, depth: CGFloat, color: Color) -> some View {
        modifier(HardShadow(radius: radius, depth: depth, color: color))
    }
}

// MARK: - 押すと沈むボタン

/// CSS の `style-active="transform:translateY(Npx);box-shadow:0 3px 0 …"` を再現する。
struct ChunkyButtonStyle<Background: ShapeStyle>: ButtonStyle {
    let background: Background
    let shadow: Color
    var radius: CGFloat = 24
    var depth: CGFloat = 8

    func makeBody(configuration: Configuration) -> some View {
        let sunk = configuration.isPressed
        return configuration.label
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(background))
            .modifier(HardShadow(radius: radius, depth: sunk ? 3 : depth, color: shadow))
            .offset(y: sunk ? depth - 3 : 0)
            .padding(.bottom, depth)
            .animation(.easeOut(duration: 0.08), value: sunk)
    }
}

// MARK: - Color(hex:)

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
