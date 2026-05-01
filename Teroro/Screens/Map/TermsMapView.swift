import SwiftUI
import MapKit

struct TermsMapView: View {
    @ObservedObject var viewModel: TermsMapVM
    let terms: [Term]
    @State private var region: MKCoordinateRegion

    init(viewModel: TermsMapVM, terms: [Term]) {
        self.viewModel = viewModel
        self.terms = terms
        _region = State(initialValue: TermsMapVM.defaultRegion)
    }

    var body: some View {
        let items = viewModel.items(from: terms, base: region.center)

        Map(
            coordinateRegion: $region,
            annotationItems: items
        ) { item in
            MapAnnotation(coordinate: item.coordinate) {
                VStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                        .shadow(radius: 2)

                    Text(item.title)
                        .font(.caption2)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Group {
                if terms.isEmpty {
                    EmptyStateCard(
                        title: "Немає термінів",
                        subtitle: "Створіть перший термін, щоб побачити його на мапі."
                    )
                } else {
                    HintCard()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }
}

private struct HintCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Мапа термінів")
                    .font(.headline)
                Text("Поки що локації не налаштовуються — відображення демонстраційне.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct EmptyStateCard: View {
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        TermsMapView(viewModel: TermsMapVM(), terms: [])
    }
}
