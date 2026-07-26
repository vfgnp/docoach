import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Query private var allLogs: [AnswerLog]

    private var gradeLogs: [AnswerLog] {
        allLogs.filter { $0.grade <= appState.selectedGrade }
    }

    private var tagScores: [TagScore] {
        AnalysisService.computeTagScores(logs: allLogs, grade: appState.selectedGrade)
    }

    private var summary: AnalysisService.Summary {
        AnalysisService.summary(logs: allLogs, grade: appState.selectedGrade, tagScores: tagScores)
    }

    var body: some View {
        ZStack {
            Kids.screenBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    title
                    summaryGrid
                    streakCard
                    tagWeaknessCard

                    // デザインには無いが既存の機能なので残す
                    StudyHistoryView(logs: gradeLogs)
                    ProgressTimelineView(logs: gradeLogs)
                }
                .padding(.horizontal, 26)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var title: some View {
        HStack(spacing: 12) {
            MascotView(height: 60, bobbing: false)
            Text("きみのきろく")
                .font(Kids.font(30, .black))
                .foregroundStyle(Kids.textDark)
        }
    }

    // MARK: - サマリー4枚

    private var summaryGrid: some View {
        let s = summary
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            StatTile(title: "せいかい数", value: "\(s.correctCount)", unit: "問",
                     fg: Kids.blue, unitFg: Color(hex: 0x9DB4CC),
                     labelFg: Color(hex: 0x7C93AD), bg: Kids.tagBlueBg, shadow: Color(hex: 0xD3E6FA))
            StatTile(title: "せいとう率", value: gradeLogs.isEmpty ? "—" : "\(Int(s.accuracy * 100))",
                     unit: gradeLogs.isEmpty ? "" : "%",
                     fg: Kids.green, unitFg: Color(hex: 0x8FC9B3),
                     labelFg: Color(hex: 0x5FA98A), bg: Color(hex: 0xE9FAF2), shadow: Color(hex: 0xC7EEDD))
            StatTile(title: "にがてタグ", value: "\(s.weakTagCount)", unit: "個",
                     fg: Kids.tagOrangeText, unitFg: Color(hex: 0xD9B589),
                     labelFg: Color(hex: 0xC68A45), bg: Kids.tagOrangeBg, shadow: Color(hex: 0xF6DFBE))
            StatTile(title: "まちがい", value: "\(s.mistakeCount)", unit: "問",
                     fg: Color(hex: 0xEE5B5B), unitFg: Color(hex: 0xE1A3A3),
                     labelFg: Color(hex: 0xC97A7A), bg: Color(hex: 0xFFEDED), shadow: Color(hex: 0xF6CFCF))
        }
    }

    // MARK: - れんぞくログイン

    private var streakCard: some View {
        let week = AnalysisService.weekProgress(in: allLogs)
        // Calendar.shortWeekdaySymbols はアプリのローカライズ（en）に従って英語になるため、
        // 日本語アプリとして固定表記にする。
        let symbols = ["日", "月", "火", "水", "木", "金", "土"]
        let cal = Calendar.current

        return VStack(alignment: .leading, spacing: 14) {
            Text("🔥 れんぞくログイン")
                .font(Kids.font(18, .black))
                .foregroundStyle(Kids.textDark)

            HStack {
                ForEach(week, id: \.date) { day in
                    let label = symbols[cal.component(.weekday, from: day.date) - 1]
                    VStack(spacing: 4) {
                        ZStack {
                            Circle().fill(day.done ? Color(hex: 0xFFE0B8) : Kids.track)
                            Text(day.done ? "🔥" : "🐾")
                                .font(.system(size: day.done ? 20 : 18))
                                .opacity(day.done ? 1 : 0.5)
                        }
                        .frame(width: 38, height: 38)
                        Text(label)
                            .font(Kids.font(12, .bold))
                            .foregroundStyle(day.done ? Kids.textMuted : Color(hex: 0xC9BCAB))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kidsCard(radius: 22, depth: 5)
    }

    // MARK: - タグべつ にがて度

    private var tagWeaknessCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("タグべつ にがて度")
                .font(Kids.font(18, .black))
                .foregroundStyle(Kids.textDark)

            if tagScores.isEmpty {
                Text("まだデータがないよ。")
                    .font(Kids.font(15, .bold))
                    .foregroundStyle(Kids.textMuted)
            } else {
                VStack(spacing: 12) {
                    ForEach(tagScores.prefix(8)) { score in
                        HStack(spacing: 12) {
                            Text(score.tag.name)
                                .font(Kids.font(14, .bold))
                                .foregroundStyle(Color(hex: 0x6B5E52))
                                .frame(width: 84, alignment: .leading)
                            KidsMeterBar(value: score.weakScore, height: 16)
                            Text("\(Int(score.weakScore * 100))%")
                                .font(Kids.font(14, .black))
                                .foregroundStyle(KidsMeterBar.color(for: score.weakScore))
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kidsCard(radius: 22, depth: 5)
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let unit: String
    let fg: Color
    let unitFg: Color
    let labelFg: Color
    let bg: Color
    let shadow: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Kids.font(14, .bold))
                .foregroundStyle(labelFg)
            Text(value)
                .font(Kids.font(34, .black))
                .foregroundStyle(fg)
            + Text(unit)
                .font(Kids.font(15, .bold))
                .foregroundStyle(unitFg)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .kidsCard(radius: 22, depth: 5, fill: bg, shadow: shadow)
    }
}
