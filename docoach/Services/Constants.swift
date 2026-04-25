import Foundation

enum AppConstants {
    enum Analysis {
        /// 難易度別の基準秒数（易=30秒, 普=60秒, 難=90秒）
        static let baselineSec: [Int: Double] = [1: 30, 2: 60, 3: 90]
        /// 苦手スコアにおける誤答率の重み
        static let weakScoreWeight: Double = 0.7
        /// 苦手スコアにおける時間超過率の重み
        static let slowScoreWeight: Double = 0.3
    }

    enum QuestionSelector {
        /// セッションの問題数
        static let sessionSize: Int = 5
        /// 苦手タグ問題の比率
        static let weakTagRatio: Double = 0.6
    }
}
