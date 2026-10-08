import SwiftUI
import MapKit

struct TermsMapView: View {
    @ObservedObject var viewModel: TermsMapVM
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
                            "Де я зараз? В один дотик знайдіть себе поруч зі своїми справами.",
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
                            "Стандартний вигляд: проста схема без візуального шуму — лише вулиці й адреси.",
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
                            "Супутниковий шар: реальний вигляд будівель та орієнтирів.",
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
                            title: "Завантаження термінів",
                            subtitle: "Мапа оновиться після синхронізації."
                        )
                        .redacted(reason: .placeholder)
                    case .emptyUpcomingTerms:
                        EmptyStateCard(
                            title: "Немає майбутніх термінів",
                            subtitle: "Заплануйте новий термін, щоб побачити його на мапі."
                        )
                    case .emptyLocations:
                        EmptyStateCard(
                            title: "Немає локацій",
                            subtitle: "Майбутні терміни без місця не відображаються на мапі."
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
