import SwiftUI
import UIKit

struct AnswerView: View {
    let question: Question
    let onSubmit: (Int) -> Void

    @State private var selectedIndex: Int? = nil

    private let letters = ["ア", "イ", "ウ", "エ"]

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
                    RubyTextView(text: question.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24)
                        .background(Color(.systemGray6))

                    Divider()

                    // 設問と選択肢
                    VStack(alignment: .leading, spacing: 24) {
                        RubyTextView(
                            text: question.questionText,
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
                                    isSelected: selectedIndex == idx
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

            Button {
                if let chosen = selectedIndex {
                    onSubmit(chosen)
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
}

private struct ChoiceButton: View {
    let label: String
    let letter: String
    let isSelected: Bool
    let action: () -> Void

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
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
