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

                HStack(spacing: 22) {
                    ForEach([4, 5, 6], id: \.self) { grade in
                        GradeCard(grade: grade, isSelected: appState.selectedGrade == grade) {
                            appState.selectedGrade = grade
                            isPresented = false
                        }
                    }
                }
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("小学")
                    .font(Kids.font(17, .bold))
                    .opacity(0.85)
                Text("\(grade)")
                    .font(Kids.font(52, .black))
                + Text("年")
                    .font(Kids.font(22, .black))
            }
            .foregroundStyle(isSelected ? Color.white : Kids.textMuted2)
            .frame(width: 150, height: 170)
        }
        .buttonStyle(
            ChunkyButtonStyle(
                background: isSelected ? AnyShapeStyle(Kids.blueButton) : AnyShapeStyle(Kids.card),
                shadow: isSelected ? Kids.blueDeep : Kids.beigeDeep,
                radius: 26,
                depth: 9
            )
        )
        .offset(y: isSelected ? -4 : 0)
    }
}
