import SwiftUI
import UIKit

struct AnswerView: View {
    let question: Question
    let grade: Int
    let onSubmit: (Int) -> Void

    @State private var selectedIndex: Int? = nil
    @State private var submittedIndex: Int? = nil

    private let letters = ["ア", "イ", "ウ", "エ"]

    private var isCorrect: Bool? {
        guard let s = submittedIndex else { return nil }
        return s == question.correctIndex
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // タイトル・著者カード
                    if !question.title.isEmpty || !question.author.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "book.closed.fill")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 0, verticalSpacing: 4) {
                                if !question.title.isEmpty {
                                    GridRow {
                                        Text("タイトル：")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .gridColumnAlignment(.leading)
                                        Text(question.title)
                                            .font(.title3.bold())
                                            .foregroundStyle(.primary)
                                    }
                                }
                                if !question.author.isEmpty {
                                    GridRow {
                                        Text("作　　者：")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .gridColumnAlignment(.leading)
                                        Text(question.author)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.accentColor.opacity(0.10))
                        .padding(.bottom, 12)
                    }

                    // 文章
                    RubyTextView(text: question.text, grade: grade)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24)
                        .background(Color(.systemGray6))

                    Divider()

                    // 設問と選択肢
                    VStack(alignment: .leading, spacing: 24) {
                        RubyTextView(
                            text: question.questionText,
                            grade: grade,
                            uiFont: {
                                let base = UIFont.preferredFont(forTextStyle: .title3)
                                if let desc = base.fontDescriptor.withSymbolicTraits(.traitBold) {
                                    return UIFont(descriptor: desc, size: 0)
                                }
                                return base
                            }()
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 24)

                        VStack(spacing: 16) {
                            ForEach(question.choices.indices, id: \.self) { idx in
                                ChoiceButton(
                                    label: question.choices[idx],
                                    letter: letters[idx],
                                    state: choiceState(for: idx),
                                    isDisabled: submittedIndex != nil
                                ) {
                                    selectedIndex = idx
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    }
                }
            }

            Divider()

            // 結果バナー（回答後のみ）
            if let correct = isCorrect {
                HStack(spacing: 12) {
                    Text(correct ? "正解" : "不正解")
                        .font(.title2.bold())
                    Spacer()
                    Text("タップして次へ")
                        .font(.caption)
                        .opacity(0.8)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(correct ? Color.green : Color.red)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if submittedIndex == nil {
                Button {
                    if let chosen = selectedIndex {
                        withAnimation(.easeOut(duration: 0.25)) {
                            submittedIndex = chosen
                        }
                    }
                } label: {
                    Text("こたえる")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                }
                .background(selectedIndex == nil ? Color(.systemGray4) : Color.accentColor)
                .disabled(selectedIndex == nil)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let s = submittedIndex {
                onSubmit(s)
            }
        }
    }

    private func choiceState(for idx: Int) -> ChoiceState {
        guard let submitted = submittedIndex else {
            return selectedIndex == idx ? .selected : .normal
        }
        let correct = submitted == question.correctIndex
        if correct && idx == submitted { return .correct }
        if !correct && idx == submitted { return .wrong }
        return .normal
    }
}

private enum ChoiceState {
    case normal, selected, correct, wrong
}

private struct ChoiceButton: View {
    let label: String
    let letter: String
    let state: ChoiceState
    let isDisabled: Bool
    let action: () -> Void

    private var bgColor: Color {
        switch state {
        case .normal:    return Color(.systemGray6)
        case .selected:  return Color.accentColor.opacity(0.12)
        case .correct:   return Color.green.opacity(0.15)
        case .wrong:     return Color.red.opacity(0.12)
        }
    }

    private var borderColor: Color {
        switch state {
        case .normal:   return .clear
        case .selected: return Color.accentColor
        case .correct:  return .green
        case .wrong:    return .red
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Text(letter)
                    .font(.headline.bold())
                    .frame(width: 28)
                Text(label)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                Spacer()
                if state == .correct {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                } else if state == .wrong {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
