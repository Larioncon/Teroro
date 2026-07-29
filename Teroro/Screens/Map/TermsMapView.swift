import SwiftUI
import MapKit

struct TermsMapView: View {
    @ObservedObject var viewModel: TermsMapVM
    let terms: [Term]
    let isLoading: Bool
    @AppStorage("preferredMapType") private var preferredMapTypeRaw: Int = Int(MKMapType.standard.rawValue)

    private var mapType: Binding<MKMapType> {
        Binding(
            get: { MKMapType(rawValue: UInt(preferredMapTypeRaw)) ?? .standard },
            set: { preferredMapTypeRaw = Int($0.rawValue) }
        )
    }

    init(viewModel: TermsMapVM, terms: [Term], isLoading: Bool = false) {
        self.viewModel = viewModel
        self.terms = terms
        self.isLoading = isLoading
    }

    var body: some View {
        let upcomingTerms = viewModel.upcomingTerms(from: terms)
        let items = viewModel.items(from: terms)

        ZStack(alignment: .topTrailing) {
            TermsMapViewRepresentable(
                region: $viewModel.region,
                items: items,
                mapType: mapType.wrappedValue
            )
            .ignoresSafeArea()

            // Map Control Buttons (Location / Center)
            VStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        viewModel.centerOnUserOrNearestTerm(for: terms)
                    }
                } label: {
                    Image(systemName: viewModel.userLocation != nil ? "location.fill" : "location")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(viewModel.userLocation != nil ? Color.accentColor : .primary)
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                
                MapTypeButton(icon: "map.fill", isSelected: mapType.wrappedValue == .standard) {
                    mapType.wrappedValue = .standard
                }
                MapTypeButton(icon: "globe.americas.fill", isSelected: mapType.wrappedValue == .hybrid) {
                    mapType.wrappedValue = .hybrid
                }
            }
            .padding(.trailing, 16)
            .padding(.top, 60)

            // Bottom Info Card
            VStack {
                Spacer()
                Group {
                    if isLoading {
                        EmptyStateCard(
                            title: "Завантаження термінів",
                            subtitle: "Мапа оновиться після синхронізації."
                        )
                        .redacted(reason: .placeholder)
                    } else if upcomingTerms.isEmpty {
                        EmptyStateCard(
                            title: "Немає майбутніх термінів",
                            subtitle: "Заплануйте новий термін, щоб побачити його на мапі."
                        )
                    } else if items.isEmpty {
                        EmptyStateCard(
                            title: "Немає локацій",
                            subtitle: "Майбутні терміни без місця не відображаються на мапі."
                        )
                    } else {
                        HintCard()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
        .onAppear {
            viewModel.requestUserLocation()
            viewModel.setTerms(terms)
        }
        .onChange(of: terms) { newTerms in
            viewModel.setTerms(newTerms)
        }
    }
}

#Preview {
    NavigationStack {
        TermsMapView(viewModel: TermsMapVM(), terms: [], isLoading: true)
    }
}
