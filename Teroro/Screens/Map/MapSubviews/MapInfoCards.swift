import SwiftUI

struct HintCard: View {
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(languageManager.localizedString(forKey: "map_terms_map_card_title"))
                    .font(.headline)
                Text(languageManager.localizedString(forKey: "map_terms_map_card_subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct EmptyStateCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassBackground(cornerRadius: 18, withGradient: false)
    }
}
