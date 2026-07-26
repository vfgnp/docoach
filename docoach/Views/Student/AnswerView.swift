import SwiftUI
import UIKit

struct AnswerView: View {
    let question: Question
    let grade: Int
    /// セッション内の進捗（ヘッダーのバーとカウンタ用）
    var index: Int = 0
    var total: Int = 1
    var onClose: (() -> Void)? = nil
    let onSubmit: (Int) -> Void

    @State private var selectedIndex: Int? = nil
    @State private var submittedIndex: Int? = nil

    private let letters = ["ア", "イ", "ウ", "エ"]

    private var isCorrect: Bool? {
        guard let s = submittedIndex else { return nil }
        return s == question.correctIndex
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
            footer
        }
        .background(Kids.screenBackground.ignoresSafeArea())
        // 回答後は画面のどこをタップしても次へ（従来どおりの操作感）
        .contentShape(Rectangle())
        .onTapGesture {
            if let s = submittedIndex { onSubmit(s) }
        }
    }

    // MARK: - ヘッダー（✕・進捗バー・カウンタ）

    private var header: some View {
        HStack(spacing: 14) {
            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(Kids.textMuted2)
                        .frame(width: 42, height: 42)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Kids.beige))
                }
                .buttonStyle(.plain)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Kids.beige)
                    Capsule()
                        .fill(Kids.blueButton)
                        .frame(width: progressRatio * geo.size.width)
                }
            }
            .frame(height: 16)

            Text("\(index + 1)")
                .font(Kids.font(17, .black))
                .foregroundStyle(Kids.textDark)
            + Text(" / \(total)")
                .font(Kids.font(17, .black))
                .foregroundStyle(Color(hex: 0xB0A392))
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var progressRatio: Double {
        guard total > 0 else { return 0 }
        return Double(index + 1) / Double(total)
    }

    // MARK: - 本文・設問・選択肢

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !question.title.isEmpty || !question.author.isEmpty {
                    titleCard
                }

                RubyTextView(
                    text: question.text,
                    grade: grade,
                    uiFont: Kids.uiFont(21, .regular),
                    textColor: UIColor(Kids.textBody),
                    lineSpacing: 12
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .kidsCard(radius: 20, depth: 5)
                .padding(.top, 14)

                questionRow.padding(.top, 22)

                VStack(spacing: 12) {
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
                .padding(.top, 18)

                if submittedIndex != nil {
                    explainBanner.padding(.top, 18)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
    }

    private var titleCard: some View {
        HStack(spacing: 12) {
            Text("📗").font(.system(size: 24))
            VStack(alignment: .leading, spacing: 1) {
                if !question.title.isEmpty {
                    Text("タイトル")
                        .font(Kids.font(13, .bold))
                        .foregroundStyle(Color(hex: 0x7C93AD))
                    Text(question.title)
                        .font(Kids.font(19, .black))
                        .foregroundStyle(Color(hex: 0x2C4A6B))
                }
                if !question.author.isEmpty {
                    Text(question.author)
                        .font(Kids.font(14, .bold))
                        .foregroundStyle(Color(hex: 0x7C93AD))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Kids.tagBlueBg))
    }

    private var questionRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("Q")
                .font(Kids.font(14, .black))
                .foregroundStyle(Kids.yellowText)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Kids.yellow))
                .hardShadow(radius: 12, depth: 3, color: Kids.yellowDeep)

            RubyTextView(
                text: question.questionText,
                grade: grade,
                uiFont: Kids.uiFont(22, .black),
                textColor: UIColor(Kids.textBody),
                lineSpacing: 6
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 正解／不正解の色だけ出す。正解の選択肢そのものは明かさない（従来の方針を維持）。
    private var explainBanner: some View {
        let correct = isCorrect ?? false
        return VStack(alignment: .leading, spacing: 4) {
            Text(correct ? "そのとおり！" : "おしい！")
                .font(Kids.font(16, .black))
            Text(correct ? "よくできました。つぎにすすもう！" : "もう一度チャレンジしよう。さいごにまとめて といなおせるよ。")
                .font(Kids.font(16, .bold))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(correct ? Kids.correctText : Color(hex: 0xC06A22))
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(correct ? Kids.correctBg : Kids.tagOrangeBg)
        )
    }

    // MARK: - フッター（こたえる／結果バナー）

    @ViewBuilder
    private var footer: some View {
        if submittedIndex == nil {
            Button {
                if let chosen = selectedIndex {
                    withAnimation(.easeOut(duration: 0.25)) { submittedIndex = chosen }
                }
            } label: {
                Text("こたえる")
                    .font(Kids.font(24, .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(selectedIndex == nil ? AnyShapeStyle(Color(hex: 0xE4D9C8)) : AnyShapeStyle(Kids.blueButton))
            }
            .buttonStyle(.plain)
            .disabled(selectedIndex == nil)
        } else {
            resultBanner
        }
    }

    private var resultBanner: some View {
        let correct = isCorrect ?? false
        return HStack {
            Text(correct ? "せいかい！ 🎉" : "ざんねん…")
                .font(Kids.font(24, .black))
            Spacer()
            Text("タップでつぎへ ›")
                .font(Kids.font(15, .bold))
                .opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            correct
            ? LinearGradient(colors: [Color(hex: 0x4FD69C), Color(hex: 0x2FB77E)], startPoint: .top, endPoint: .bottom)
            : LinearGradient(colors: [Color(hex: 0xFFAE6A), Kids.orange], startPoint: .top, endPoint: .bottom)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func choiceState(for idx: Int) -> ChoiceState {
        guard let submitted = submittedIndex else {
            return selectedIndex == idx ? .selected : .normal
        }
        let correct = submitted == question.correctIndex
        if correct && idx == submitted { return .correct }
        if !correct && idx == submitted { return .wrong }
        return .dimmed
    }
}

enum ChoiceState {
    case normal, selected, correct, wrong, dimmed
}

private struct ChoiceButton: View {
    let label: String
    let letter: String
    let state: ChoiceState
    let isDisabled: Bool
    let action: () -> Void

    private var border: Color {
        switch state {
        case .normal, .dimmed: return Kids.choiceIdleBorder
        case .selected:        return Kids.choiceSelBorder
        case .correct:         return Kids.correctBorder
        case .wrong:           return Kids.wrongBorder
        }
    }

    private var bg: Color {
        switch state {
        case .normal:   return Kids.card
        case .dimmed:   return Color(hex: 0xF8F1E6)
        case .selected: return Kids.choiceSelBg
        case .correct:  return Kids.correctBg
        case .wrong:    return Kids.wrongBg
        }
    }

    private var fg: Color {
        switch state {
        case .normal:   return Kids.textDark
        case .dimmed:   return Color(hex: 0xB3A798)
        case .selected: return Kids.choiceSelText
        case .correct:  return Kids.correctText
        case .wrong:    return Kids.wrongText
        }
    }

    private var shadow: Color? {
        switch state {
        case .normal:   return Kids.cardShadow
        case .selected: return Kids.choiceSelShadow
        case .correct:  return Kids.correctShadow
        case .wrong:    return Kids.wrongShadow
        case .dimmed:   return nil
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(letter)
                    .font(Kids.font(17, .black))
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Color.white))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(fg, lineWidth: 2)
                    )
                Text(label)
                    .font(Kids.font(20, .bold))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(fg)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(bg))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(border, lineWidth: 3)
            )
            .modifier(OptionalHardShadow(radius: 20, depth: 5, color: shadow))
            .opacity(state == .dimmed ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .padding(.bottom, shadow == nil ? 0 : 5)
    }
}

/// 影の色が nil のときは何もしないラッパー
private struct OptionalHardShadow: ViewModifier {
    let radius: CGFloat
    let depth: CGFloat
    let color: Color?

    func body(content: Content) -> some View {
        if let color {
            content.hardShadow(radius: radius, depth: depth, color: color)
        } else {
            content
        }
    }
}
