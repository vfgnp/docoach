import SwiftUI

// MARK: - にがてタグのバッジ

/// デザインのタグピル（薄い塗り＋同系の枠線）。
struct KidsTagPill: View {
    let name: String
    /// タグ categoly ごとに青系／橙系を出し分ける
    var warm: Bool = false

    var body: some View {
        Text(name)
            .font(Kids.font(14, .bold))
            .foregroundStyle(warm ? Kids.tagOrangeText : Kids.tagBlueText)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(warm ? Kids.tagOrangeBg : Kids.tagBlueBg)
            )
            .overlay(
                Capsule().strokeBorder(warm ? Kids.tagOrangeBorder : Kids.tagBlueBorder, lineWidth: 1.5)
            )
    }
}

// MARK: - にがて度バー

struct KidsMeterBar: View {
    /// 0...1
    let value: Double
    var height: CGFloat = 14

    static func color(for value: Double) -> Color {
        if value > 0.6 { return Kids.barRed }
        if value > 0.3 { return Kids.barOrange }
        return Kids.barGreen
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Kids.track)
                Capsule()
                    .fill(Self.color(for: value))
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

// MARK: - 大きい「ゴー！」ボタン

/// デザインの主要 CTA。押すと沈む。
struct KidsBigButton<Trailing: View>: View {
    let title: String
    var subtitleIcon: String? = nil
    var palette: Palette = .blue
    var fontSize: CGFloat = 30
    let action: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    enum Palette {
        case blue, orange

        var gradient: LinearGradient {
            switch self {
            case .blue: return Kids.blueButton
            case .orange: return Kids.orangeButton
            }
        }
        var shadow: Color {
            switch self {
            case .blue: return Kids.blueDeep
            case .orange: return Kids.orangeDeep
            }
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = subtitleIcon {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.25))
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .black))
                    }
                    .frame(width: 46, height: 46)
                }
                Text(title)
                    .font(Kids.font(fontSize, .black))
                trailing()
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
        }
        .buttonStyle(
            ChunkyButtonStyle(background: palette.gradient, shadow: palette.shadow, radius: 26, depth: 9)
        )
    }
}

extension KidsBigButton where Trailing == EmptyView {
    init(title: String, subtitleIcon: String? = nil, palette: Palette = .blue, fontSize: CGFloat = 30, action: @escaping () -> Void) {
        self.init(title: title, subtitleIcon: subtitleIcon, palette: palette, fontSize: fontSize, action: action, trailing: { EmptyView() })
    }
}

// MARK: - カウントのピル（「5問」など）

struct KidsCountPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Kids.font(16, .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.28)))
    }
}

// MARK: - 下部タブバー

struct KidsTabBar: View {
    @Binding var selection: Int
    /// 管理タブはデザインに無いので、必要なときだけ出す
    let items: [(icon: String, label: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button {
                    selection = index
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.system(size: 24, weight: .semibold))
                        Text(item.label)
                            .font(Kids.font(13, .black))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(selection == index ? Kids.blue : Kids.textFaint)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(alignment: .top) {
            Kids.tabBorder.frame(height: 2)
        }
        .background(Kids.card)
    }
}

// MARK: - セクション見出し

struct KidsSectionHeader<Trailing: View>: View {
    let emoji: String
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 8) {
            Text(emoji).font(.system(size: 20))
            Text(title)
                .font(Kids.font(20, .black))
                .foregroundStyle(Kids.textDark)
            Spacer(minLength: 0)
            trailing()
        }
    }
}

extension KidsSectionHeader where Trailing == EmptyView {
    init(emoji: String, title: String) {
        self.init(emoji: emoji, title: title, trailing: { EmptyView() })
    }
}
