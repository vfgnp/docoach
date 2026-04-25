import SwiftUI

struct GradePickerView: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 48) {
            Text("学年を選んでね")
                .font(.largeTitle.bold())

            HStack(spacing: 24) {
                ForEach([4, 5, 6], id: \.self) { grade in
                    Button {
                        appState.selectedGrade = grade
                        isPresented = false
                    } label: {
                        VStack(spacing: 12) {
                            Text("小学")
                                .font(.title3)
                            Text("\(grade)年生")
                                .font(.system(size: 48, weight: .bold))
                        }
                        .frame(width: 180, height: 180)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(appState.selectedGrade == grade
                                      ? Color.accentColor
                                      : Color(.systemGray5))
                        )
                        .foregroundStyle(
                            appState.selectedGrade == grade ? .white : .primary
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(40)
        .presentationDetents([.medium])
    }
}
