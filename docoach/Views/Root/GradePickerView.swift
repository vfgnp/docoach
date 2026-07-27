import SwiftUI

struct GradePickerView: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Kids.screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                MascotView(height: 160)

                Text("学年をえらんでね")
                    .font(Kids.font(32, .black))
                    .foregroundStyle(Kids.textDark)
                    .padding(.top, 16)

                Text("きみは何年生かな？")
                    .font(Kids.font(17, .bold))
                    .foregroundStyle(Kids.textMuted)
                    .padding(.top, 6)

                GeometryReader { geo in
                    let spacing: CGFloat = 22
                    let cardWidth = min(150, (geo.size.width - spacing * 2) / 3)

                    HStack(spacing: spacing) {
                        ForEach([4, 5, 6], id: \.self) { grade in
                            GradeCard(grade: grade, isSelected: appState.selectedGrade == grade, width: cardWidth) {
                                appState.selectedGrade = grade
                                isPresented = false
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 170)
                .padding(.top, 36)

                Spacer(minLength: 0)

                Button {
                    isPresented = false
                } label: {
                    Text("もどる")
                        .font(Kids.font(16, .bold))
                        .foregroundStyle(Kids.textMuted2)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Kids.beige)
                        )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
            .padding(40)
        }
    }
}

private struct GradeCard: View {
    let grade: Int
    let isSelected: Bool
    let width: CGFloat
    let action: () -> Void

    // デザインの基準サイズ（150x170）に対する縮小率。iPad では 1.0 のまま、
    // iPhone など横幅が足りない画面でだけカードとフォントを一緒に縮める。
    private var scale: CGFloat { width / 150 }
    private var height: CGFloat { width * (170.0 / 150.0) }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6 * scale) {
                Text("小学")
                    .font(Kids.font(17 * scale, .bold))
                    .opacity(0.85)
                Text("\(grade)")
                    .font(Kids.font(52 * scale, .black))
                + Text("年")
                    .font(Kids.font(22 * scale, .black))
            }
            .foregroundStyle(isSelected ? Color.white : Kids.textMuted2)
            .frame(width: width, height: height)
        }
        .buttonStyle(
            ChunkyButtonStyle(
                background: isSelected ? AnyShapeStyle(Kids.blueButton) : AnyShapeStyle(Kids.card),
                shadow: isSelected ? Kids.blueDeep : Kids.beigeDeep,
                radius: 26 * scale,
                depth: max(4, 9 * scale)
            )
        )
        .offset(y: isSelected ? -4 : 0)
    }
}
