import SwiftUI

struct TagBadgeView: View {
    let tag: Tag

    private var color: Color {
        switch tag.category {
        case "skill":     return .blue
        case "thinking":  return .purple
        case "structure": return .orange
        case "vocab":     return .green
        default:          return .gray
        }
    }

    var body: some View {
        Text(tag.name)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}
