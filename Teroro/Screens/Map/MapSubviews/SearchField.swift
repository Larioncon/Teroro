import SwiftUI
import MapKit

struct SearchField: View {
    @Binding var text: String
    let suggestions: [MKLocalSearchCompletion]
    let onSelect: (MKLocalSearchCompletion) -> Void
    let onOpenMap: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    TextField("Місто або адреса", text: $text)
                        .focused($isFocused)
                        .padding(.leading, 40)
                        .padding(.trailing, 14)
                        .padding(.vertical, 14)
                    
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 14)
                }
                .frame(height: 54)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(isFocused ? 0.9 : 0.2), lineWidth: 1)
                )

                Button {
                    isFocused = false
                    onOpenMap()
                } label: {
                    Image("applemapicon")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Divider().padding(.horizontal, 10)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button {
                                    onSelect(suggestion)
                                    isFocused = false
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text(suggestion.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
                                Divider().padding(.horizontal, 16)
                            }
                        }
                    }
                    .frame(maxHeight: 400)
                }
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
        }
    }
}
