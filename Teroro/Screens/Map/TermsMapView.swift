import SwiftUI
import MapKit

struct TermsMapView: View {
    @ObservedObject var viewModel: TermsMapVM
    @ObservedObject private var languageManager = LanguageManager.shared
    let terms: [Term]
    let isLoading: Bool

    init(viewModel: TermsMapVM, terms: [Term], isLoading: Bool = false) {
        self.viewModel = viewModel
        self.terms = terms
        self.isLoading = isLoading
    }

    var body: some View {
        let items = viewModel.items(from: terms)

        ZStack(alignment: .topTrailing) {
            TermsMapViewRepresentable(
                region: $viewModel.region,
                items: items,
                mapType: viewModel.mapType
            )
            .ignoresSafeArea()

            // Map Hint Bubbles (floating to the left of control buttons)
            VStack(alignment: .trailing, spacing: 8) {
                ZStack(alignment: .trailing) {
                    if viewModel.isHintVisible(for: .location) {
                        SpeechBubbleView(
                            languageManager.localizedString(forKey: "map_hint_location"),
                            icon: "location.fill",
                            direction: .right,
                            backgroundColor: .blue,
                            foregroundColor: .white,
                            font: .system(size: 13, weight: .regular),
                            shadowColor: .black.opacity(0.12),
                            shadowRadius: 10,
                            shadowY: 5,
                            closeButtonPosition: .topLeading,
                            onClose: {
                                viewModel.advanceHint()
                            }
                        )
                        .frame(maxWidth: 240)
                        .fixedSize()
                        .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .trailing)))
                    }
                }
                .frame(height: 44)

                ZStack(alignment: .trailing) {
                    if viewModel.isHintVisible(for: .standard) {
                        SpeechBubbleView(
                            languageManager.localizedString(forKey: "map_hint_standard"),
                            icon: "map.fill",
                            direction: .right,
                            backgroundColor: .purple,
                            foregroundColor: .white,
                            font: .system(size: 13, weight: .regular),
                            shadowColor: .black.opacity(0.12),
                            shadowRadius: 10,
                            shadowY: 5,
                            closeButtonPosition: .topLeading,
                            onClose: {
                                viewModel.advanceHint()
                            }
                        )
                        .frame(maxWidth: 240)
                        .fixedSize()
                        .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .trailing)))
                    }
                }
                .frame(height: 44)

                ZStack(alignment: .trailing) {
                    if viewModel.isHintVisible(for: .hybrid) {
                        SpeechBubbleView(
                            languageManager.localizedString(forKey: "map_hint_hybrid"),
                            icon: "globe.americas.fill",
                            direction: .right,
                            backgroundColor: .orange,
                            foregroundColor: .white,
                            font: .system(size: 13, weight: .regular),
                            shadowColor: .black.opacity(0.12),
                            shadowRadius: 10,
                            shadowY: 5,
                            closeButtonPosition: .topLeading,
                            onClose: {
                                viewModel.advanceHint()
                            }
                        )
                        .frame(maxWidth: 240)
                        .fixedSize()
                        .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .trailing)))
                    }
                }
                .frame(height: 44)
            }
            .padding(.trailing, 68)
            .padding(.top, 60)

            // Map Control Buttons (Location / Center)
            VStack(spacing: 8) {
                Button {
                    viewModel.centerOnUserOrTerms(terms: terms)
                } label: {
                    Image(systemName: viewModel.userLocation != nil ? "location.fill" : "location")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(viewModel.userLocation != nil ? Color.accentColor : .primary)
                        .frame(width: 44, height: 44)
                        .glassBackground(Circle(), fill: .regularMaterial, withGradient: false)
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .contentShape(Circle())

                MapTypeButton(icon: "map.fill", isSelected: viewModel.mapType == .standard) {
                    viewModel.selectStandardMap()
                }

                MapTypeButton(icon: "globe.americas.fill", isSelected: viewModel.mapType == .hybrid) {
                    viewModel.selectHybridMap()
                }
            }
            .padding(.trailing, 16)
            .padding(.top, 60)

            // Bottom Info Card
            VStack {
                Spacer()
                Group {
                    switch viewModel.cardState(for: terms, isLoading: isLoading) {
                    case .loading:
                        EmptyStateCard(
                            title: languageManager.localizedString(forKey: "map_loading_terms_title"),
                            subtitle: languageManager.localizedString(forKey: "map_loading_terms_subtitle")
                        )
                        .redacted(reason: .placeholder)
                    case .emptyUpcomingTerms:
                        EmptyStateCard(
                            title: languageManager.localizedString(forKey: "map_empty_terms_title"),
                            subtitle: languageManager.localizedString(forKey: "map_empty_terms_subtitle")
                        )
                    case .emptyLocations:
                        EmptyStateCard(
                            title: languageManager.localizedString(forKey: "map_empty_locations_title"),
                            subtitle: languageManager.localizedString(forKey: "map_empty_locations_subtitle")
                        )
                    case .hint:
                        HintCard()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
        .onAppear {
            viewModel.onAppear(terms: terms)
        }
        .onDisappear {
            viewModel.onDisappear()
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
