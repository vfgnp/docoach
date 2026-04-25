import Foundation
import CoreFoundation

/// 日本語テキストの漢字に {漢字|よみ} 形式のルビを自動付与するサービス
struct RubyAnnotatorService {

    /// テキストにルビを付与して返す。
    /// 既に {..|}..} 形式のルビが含まれている場合はそのまま返す。
    static func annotate(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        // 既にルビがあればスキップ
        if text.contains("{") { return text }
        return process(text)
    }

    // MARK: - Core Processing

    private static func process(_ text: String) -> String {
        let nsText = text as NSString
        let length = nsText.length
        guard length > 0 else { return text }

        let cfText = text as CFString
        let fullRange = CFRangeMake(0, length)
        let locale = Locale(identifier: "ja_JP") as CFLocale

        guard let tokenizer = CFStringTokenizerCreate(
            kCFAllocatorDefault,
            cfText,
            fullRange,
            kCFStringTokenizerUnitWord,
            locale
        ) else { return text }

        var result = ""
        var lastEnd = 0

        while true {
            let tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
            guard tokenType.rawValue != 0 else { break }

            let cfRange = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let start = cfRange.location
            let end = cfRange.location + cfRange.length

            // トークン前のギャップ（句読点・空白・改行など）をそのまま追加
            if start > lastEnd {
                result += nsText.substring(with: NSRange(location: lastEnd, length: start - lastEnd))
            }

            let tokenStr = nsText.substring(with: NSRange(location: start, length: cfRange.length))

            if containsKanji(tokenStr),
               let latin = CFStringTokenizerCopyCurrentTokenAttribute(
                   tokenizer,
                   kCFStringTokenizerAttributeLatinTranscription
               ) as? String {
                let hiragana = latinToHiragana(latin)

                // 末尾のひらがなをトークンから分離し、漢字部分だけにルビを付与する
                // 例: "帰って" → kanjiPart="帰", suffix="って", reading="かえ"
                let suffix = trailingHiragana(tokenStr)
                let kanjiPart = String(tokenStr.dropLast(suffix.count))
                var readingCore = hiragana
                if !suffix.isEmpty && readingCore.hasSuffix(suffix) {
                    readingCore = String(readingCore.dropLast(suffix.count))
                }

                if !kanjiPart.isEmpty && containsKanji(kanjiPart) {
                    result += "{\(kanjiPart)|\(readingCore)}\(suffix)"
                } else {
                    result += tokenStr
                }
            } else {
                result += tokenStr
            }

            lastEnd = end
        }

        // 末尾のギャップを追加
        if lastEnd < length {
            result += nsText.substring(from: lastEnd)
        }

        return result
    }

    // MARK: - Grade-based Ruby Filtering

    /// base 文字列中の漢字が selectedGrade より上の学年で習うものを含む場合 true を返す。
    /// true → ルビを表示すべき。false → 児童はすでに知っているためルビ不要。
    static func needsRuby(base: String, forGrade grade: Int) -> Bool {
        for scalar in base.unicodeScalars {
            guard isKanjiScalar(scalar) else { continue }
            let ch = Character(scalar)
            let gradeLevel = kanjiGrade[ch] ?? 99
            if gradeLevel > grade { return true }
        }
        return false
    }

    // MARK: - Helpers

    /// 文字列末尾のひらがな連続を返す
    private static func trailingHiragana(_ str: String) -> String {
        var suffix = ""
        for ch in str.reversed() {
            guard let scalar = ch.unicodeScalars.first else { break }
            // ひらがな: U+3041〜U+3096
            if scalar.value >= 0x3041 && scalar.value <= 0x3096 {
                suffix = String(ch) + suffix
            } else {
                break
            }
        }
        return suffix
    }

    private static func containsKanji(_ str: String) -> Bool {
        str.unicodeScalars.contains { isKanjiScalar($0) }
    }

    private static func isKanjiScalar(_ scalar: Unicode.Scalar) -> Bool {
        (scalar.value >= 0x4E00 && scalar.value <= 0x9FFF) ||
        (scalar.value >= 0x3400 && scalar.value <= 0x4DBF)
    }

    /// ローマ字（ヘボン式）をひらがなに変換
    private static func latinToHiragana(_ latin: String) -> String {
        let mutable = NSMutableString(string: latin.lowercased())
        CFStringTransform(mutable, nil, kCFStringTransformLatinHiragana, false)
        return mutable as String
    }

    // MARK: - 教育漢字グレード辞書（小学1〜6年）

    static let kanjiGrade: [Character: Int] = {
        // 1年生 (80字)
        let g1 = "一右雨円王音下火花貝学気九休玉金空月犬見五口校左三山子四糸字耳七車手十出女小上森人水正生青夕石赤千川先早草足村大男竹中虫町天田土二日入年白八百文木本名目立力林六"
        // 2年生 (160字)
        let g2 = "引羽雲園遠何科夏家歌画回会海絵外角楽活間丸岩顔汽記帰弓牛魚京強教近兄形計元言原戸古午後語工公広考光合国黒今才細作算止市矢姉思紙寺自時室社弱首秋週春書少場色食心新親図数西声星晴切雪船線前組走多太体台地池知茶昼長鳥朝直通弟店点電刀冬当東答頭同道読内南肉馬売買麦半番父風分聞米歩母方北毎妹万明鳴毛門夜野友曜用来理里話"
        // 3年生 (200字)
        let g3 = "悪安暗医委意育員院飲運泳駅央横屋温化荷界開階寒感漢館岸起期客急級宮球去橋業曲局係苦君庫湖向幸港号根祭皿仕死使始指歯詩次事持式実写者主守取酒受州拾終習集住重宿所暑助勝商昭消章乗植深申真神身進世整昔全送族他打対待代第題炭短談着注柱丁帳調追定庭鉄転都度投豆島湯登等動童農波配倍箱畑発反坂板悲皮美鼻筆氷表秒病品負部服福物平返勉放味命面問役薬由油有遊予羊洋葉陽様落流旅両緑礼列練路和"
        // 4年生 (202字)
        let g4 = "愛案以衣位囲胃印英栄塩億加果貨課芽改械害各覚完官管関観願希季紀喜旗器機議求泣救給挙漁共協鏡競極訓軍郡径型景芸欠結建健験固功好候航康告差菜最材昨察殺雑参散産残士氏史司試児治滋辞失借種周祝順初松笑唱焼象照賞信成省清静席積折節説浅戦選然争倉巣束側続卒孫帯隊達単置仲貯兆腸低底停的典伝徒努灯働特得毒熱念敗梅博飯費必標票不夫付府副粉兵別辺変便包望牧末満未脈民無約勇要養浴利陸料良量輪類令冷連老労録"
        // 5年生 (193字)
        let g5 = "圧移因永営衛易益液演応往恩仮価河過賀快解格確額幹慣眼基寄規技義逆久旧居許境均禁句群経潔件険現減故個護効厚耕航鉱構興講混査再妻採際在財罪雑酸賛支志枝師資飼示似識質舎謝授修述術準序招承証条状常情織職制性政勢精製税責績接設絶銭祖素総造像増則測属率損貸態団断築張提程適統銅導徳独任燃能破判版比肥非備評貧布婦富武復複仏編弁保墓報豊防貿暴務夢迷綿輸余預容略留領"
        // 6年生 (191字)
        let g6 = "異遺域宇映延沿我灰拡革閣割株干巻看簡危机揮貴疑吸供胸郷勤筋系敬警劇激穴憲権絹厳源呼己誤后孝皇紅鋼刻穀骨困砂座済裁策冊蚕至私姿視詞誌磁射捨尺若樹収宗就衆従縦縮熟純処署諸除将傷障城蒸針仁垂推寸盛聖誠宣専泉洗染善奏窓創装層操蔵存尊宅担探誕段暖値宙忠著庁頂潮賃痛展討党糖届難乳認納脳派背肺俳班晩否批秘腹奮並陛閉片補暮宝訪亡忘棒枚幕密盟模訳優幼欲翌乱卵覧裏律臨朗論"

        var dict: [Character: Int] = [:]
        for ch in g1 { dict[ch] = 1 }
        for ch in g2 { dict[ch] = 2 }
        for ch in g3 { dict[ch] = 3 }
        for ch in g4 { dict[ch] = 4 }
        for ch in g5 { dict[ch] = 5 }
        for ch in g6 { dict[ch] = 6 }
        return dict
    }()
}
