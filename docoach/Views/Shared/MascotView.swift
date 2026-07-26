import SwiftUI

/// Doコーチのマスコット（とらねこ）。
/// `DoCoach-Kids.dc.html` の CSS 実装を SwiftUI に移植したもの。
/// CSS では親の `font-size` を基準に全パーツを `em` で置いていたので、
/// ここでも `unit`（= 1em 相当）を 1 つ受け取って全パーツをその倍数で組む。
struct MascotView: View {
    /// マスコット全体の高さ。CSS の 11.6em にあたる。
    var height: CGFloat = 80
    /// ふわふわ上下する
    var bobbing: Bool = true

    /// CSS の 1em
    private var u: CGFloat { height / 11.6 }
    private var boxWidth: CGFloat { u * 11 }

    @State private var bob = false

    private enum Palette {
        static let outline = Color(hex: 0x3A2E2A)
        static let furTop = Color(hex: 0xFABF74)
        static let furBottom = Color(hex: 0xEE9C46)
        static let earTop = Color(hex: 0xF8BC72)
        static let earBottom = Color(hex: 0xED9942)
        static let innerEar = Color(hex: 0xF58BA0)
        static let stripe = Color(hex: 0xD77E37)
        static let nose = Color(hex: 0xE86A80)
        static let cheek = Color(red: 245 / 255, green: 120 / 255, blue: 120 / 255, opacity: 0.5)
    }

    private var fur: LinearGradient {
        LinearGradient(colors: [Palette.furTop, Palette.furBottom], startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            ears
            head
            face
            paws
        }
        .frame(width: boxWidth, height: height)
        .shadow(color: Color(red: 70 / 255, green: 45 / 255, blue: 20 / 255, opacity: 0.25), radius: u * 0.5, y: u * 0.5)
        .rotationEffect(.degrees(bob ? 3 : -3))
        .offset(y: bob ? -u * 1.2 : 0)
        .onAppear {
            guard bobbing else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
    }

    // MARK: - パーツ

    private var ears: some View {
        ZStack(alignment: .topLeading) {
            ear(isLeft: true)
            ear(isLeft: false)
        }
    }

    private func ear(isLeft: Bool) -> some View {
        let size = u * 3.2
        let outerRadius = u
        let notch = u * 0.3
        // CSS: border-radius 1em 1em 0.3em 1em（右耳は BR/BL が入れ替わる）
        let radii = RectangleCornerRadii(
            topLeading: outerRadius,
            bottomLeading: isLeft ? outerRadius : notch,
            bottomTrailing: isLeft ? notch : outerRadius,
            topTrailing: outerRadius
        )
        return UnevenRoundedRectangle(cornerRadii: radii, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Palette.earTop, Palette.earBottom],
                    startPoint: isLeft ? .topLeading : .topTrailing,
                    endPoint: isLeft ? .bottomTrailing : .bottomLeading
                )
            )
            .overlay(
                UnevenRoundedRectangle(cornerRadii: radii, style: .continuous)
                    .strokeBorder(Palette.outline, lineWidth: u * 0.45)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: u * 0.45, style: .continuous)
                    .fill(Palette.innerEar)
                    .frame(width: u * 1.2, height: u * 1.2)
                    .offset(y: u)
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isLeft ? -12 : 12))
            .offset(x: isLeft ? u * 1.3 : boxWidth - u * 1.3 - size, y: u * 0.5)
    }

    private var head: some View {
        let w = u * 9.2
        let h = u * 8.3
        return ZStack {
            // CSS の box-shadow 0 0 0 0.35em #fff（白フチ）
            Ellipse()
                .fill(Color.white)
                .frame(width: w + u * 0.7, height: h + u * 0.7)
            Ellipse()
                .fill(fur)
                .overlay(Ellipse().strokeBorder(Palette.outline, lineWidth: u * 0.5))
                .frame(width: w, height: h)
        }
        .frame(width: w, height: h)
        .offset(x: u * 0.9, y: u * 1.7)
    }

    private var face: some View {
        ZStack(alignment: .topLeading) {
            stripes
            eye(isLeft: true)
            eye(isLeft: false)
            cheek(isLeft: true)
            cheek(isLeft: false)
            nose
            mouth
        }
    }

    private var stripes: some View {
        ZStack(alignment: .topLeading) {
            Capsule().fill(Palette.stripe)
                .frame(width: u * 1.3, height: u * 0.5)
                .offset(x: u * 4.55, y: u * 2.5)
            Capsule().fill(Palette.stripe)
                .frame(width: u * 0.95, height: u * 0.45)
                .rotationEffect(.degrees(-28))
                .offset(x: u * 3.6, y: u * 2.35)
            Capsule().fill(Palette.stripe)
                .frame(width: u * 0.95, height: u * 0.45)
                .rotationEffect(.degrees(28))
                .offset(x: boxWidth - u * 3.6 - u * 0.95, y: u * 2.35)
        }
    }

    private func eye(isLeft: Bool) -> some View {
        let w = u * 1.5
        let h = u * 2
        return Ellipse()
            .fill(Palette.outline)
            .frame(width: w, height: h)
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(Color.white)
                    .frame(width: u * 0.55, height: u * 0.55)
                    .offset(x: u * 0.35, y: u * 0.3)
            }
            .offset(x: isLeft ? u * 3.2 : boxWidth - u * 3.2 - w, y: u * 4.5)
    }

    private func cheek(isLeft: Bool) -> some View {
        let w = u * 1.8
        return Ellipse()
            .fill(Palette.cheek)
            .frame(width: w, height: u * 1.05)
            .offset(x: isLeft ? u * 2.5 : boxWidth - u * 2.5 - w, y: u * 6)
    }

    private var nose: some View {
        UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: u * 0.3, bottomLeading: u * 0.5,
                bottomTrailing: u * 0.5, topTrailing: u * 0.3
            ),
            style: .continuous
        )
        .fill(Palette.nose)
        .frame(width: u, height: u * 0.78)
        .offset(x: boxWidth / 2 - u * 0.5, y: u * 5.75)
    }

    /// CSS の「左右＋下だけ border、下角を半径いっぱいに丸めた箱」＝下半分の円弧。
    private var mouth: some View {
        SemiCircleArc()
            .stroke(Palette.outline, style: StrokeStyle(lineWidth: u * 0.4, lineCap: .round))
            .frame(width: u * 2.5, height: u * 1.25)
            .offset(x: boxWidth / 2 - u * 1.25, y: u * 6.5)
    }

    private var paws: some View {
        ZStack(alignment: .topLeading) {
            paw(isLeft: true)
            paw(isLeft: false)
        }
    }

    private func paw(isLeft: Bool) -> some View {
        let w = u * 2.2
        let h = u * 1.7
        return RoundedRectangle(cornerRadius: u * 0.9, style: .continuous)
            .fill(fur)
            .overlay(
                RoundedRectangle(cornerRadius: u * 0.9, style: .continuous)
                    .strokeBorder(Palette.outline, lineWidth: u * 0.45)
            )
            .frame(width: w, height: h)
            .offset(x: isLeft ? u * 2.3 : boxWidth - u * 2.3 - w, y: height - h)
    }
}

/// 下半分だけの円弧（口）
private struct SemiCircleArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY),
            radius: rect.height,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )
        return p
    }
}

#Preview {
    VStack(spacing: 24) {
        MascotView(height: 80)
        MascotView(height: 160)
        MascotView(height: 200, bobbing: false)
    }
    .padding(40)
    .background(Kids.bg)
}
