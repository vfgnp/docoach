import SwiftUI
import UIKit
import CoreText

/// {漢字|かんじ} 形式のルビマークアップを含むテキストをルビ付きで表示するビュー
///
/// 使用例:
///   RubyTextView(text: "今日{今日|きょう}は{天気|てんき}が良い。")
struct RubyTextView: UIViewRepresentable {
    let text: String
    /// 児童の学年。この学年以下で習ZZう漢字にはルビを表示しない（0 = 全てのルビを表示）
    var grade: Int = 0
    var uiFont: UIFont = .preferredFont(forTextStyle: .body)
    var textColor: UIColor = .label
    var lineSpacing: CGFloat = 8

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = false
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return tv
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        textView.attributedText = makeAttributedString()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width
        return uiView.sizeThatFits(CGSize(width: width, height: .infinity))
    }

    // MARK: - Attributed String Builder

    private func makeAttributedString() -> NSAttributedString {
        let result = NSMutableAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing

        var i = text.startIndex
        var plainStart = i

        while i < text.endIndex {
            guard text[i] == "{" else {
                i = text.index(after: i)
                continue
            }

            // { を見つけたら {base|ruby} パターンを探す
            let afterOpen = text.index(after: i)
            guard let pipeIdx = text[afterOpen...].firstIndex(of: "|") else {
                i = text.index(after: i)
                continue
            }
            let afterPipe = text.index(after: pipeIdx)
            guard let closeIdx = text[afterPipe...].firstIndex(of: "}") else {
                i = text.index(after: i)
                continue
            }

            // { より前のプレーンテキストを追加
            if plainStart < i {
                let plain = String(text[plainStart..<i])
                result.append(NSAttributedString(
                    string: plain,
                    attributes: normalAttributes(paragraphStyle)
                ))
            }

            let base = String(text[afterOpen..<pipeIdx])
            let ruby = String(text[afterPipe..<closeIdx])

            // 児童の学年以下で習う漢字はルビを省略する
            if grade > 0 && !RubyAnnotatorService.needsRuby(base: base, forGrade: grade) {
                result.append(NSAttributedString(string: base, attributes: normalAttributes(paragraphStyle)))
            } else {
                result.append(makeRubyString(base: base, ruby: ruby, paragraphStyle: paragraphStyle))
            }

            i = text.index(after: closeIdx)
            plainStart = i
        }

        // 末尾のプレーンテキストを追加
        if plainStart < text.endIndex {
            result.append(NSAttributedString(
                string: String(text[plainStart...]),
                attributes: normalAttributes(paragraphStyle)
            ))
        }

        return result
    }

    private func normalAttributes(_ paragraphStyle: NSParagraphStyle) -> [NSAttributedString.Key: Any] {
        [
            .font: uiFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]
    }

    private func makeRubyString(base: String, ruby: String, paragraphStyle: NSParagraphStyle) -> NSAttributedString {
        let rubyStr = ruby as CFString
        // kCTRubyPositionCount = 4 (before, after, interCharacter, inline)
        var texts: [Unmanaged<CFString>?] = [
            Unmanaged.passUnretained(rubyStr), // .before = 本文の上
            nil, nil, nil
        ]
        let annotation = CTRubyAnnotationCreate(.auto, .auto, 0.5, &texts)
        return NSAttributedString(string: base, attributes: [
            .font: uiFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
            kCTRubyAnnotationAttributeName as NSAttributedString.Key: annotation
        ])
    }
}
