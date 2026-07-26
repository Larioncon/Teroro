import SwiftUI
import MapKit
import Combine

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = LocationPickerVM()
    @State private var showMapPicker = false
    let onSelect: (TermLocation) -> Void

    var body: some View {
        VStack(spacing: 0) {
            SearchField(
                text: $vm.searchText,
                suggestions: vm.suggestions,
                onSelect: { suggestion in
                    vm.selectSuggestion(suggestion)
                },
                onOpenMap: {
                    showMapPicker = true
                }
            )
            .padding(.horizontal, 16)
            .padding(.top, 10)

            if vm.suggestions.isEmpty && !vm.searchText.isEmpty && vm.finalLocation == nil {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Нічого не знайдено")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else if let loc = vm.finalLocation, vm.suggestions.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    VStack(spacing: 4) {
                        Text(loc.title ?? "Локація")
                            .font(.title3.weight(.bold))
                            .multilineTextAlignment(.center)
                        if let address = loc.address {
                            Text(address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                Spacer()
            }

            PrimaryButton(
                title: "Обрати цю локацію",
                style: .primaryWhiteText,
                action: {
                    if let loc = vm.finalLocation {
                        onSelect(loc)
                        dismiss()
                    }
                }
            )
            .disabled(vm.finalLocation == nil)
            .opacity(vm.finalLocation == nil ? 0.5 : 1)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Пошук місця")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showMapPicker) {
            MapLocationPickerView { selectedLoc in
                vm.finalLocation = selectedLoc
                vm.searchText = selectedLoc.title ?? ""
                vm.suggestions = []
            }
        }
    }
}

@MainActor
final class LocationPickerVM: ObservableObject {
    @Published var searchText: String = ""
    @Published var suggestions: [MKLocalSearchCompletion] = []
    @Published var finalLocation: TermLocation?

    private var completer = MKLocalSearchCompleter()
    private var completerDelegate: CompleterDelegate?
    private var cancellables = Set<AnyCancellable>()

    init() {
        let delegate = CompleterDelegate { [weak self] results in
            self?.suggestions = results
        }
        self.completerDelegate = delegate
        completer.delegate = delegate
        
        // Включаємо пошук міст, адрес та цікавих місць
        completer.resultTypes = [.address, .pointOfInterest, .query]

        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] text in
                guard let self = self else { return }
                if text.isEmpty {
                    self.suggestions = []
                    self.finalLocation = nil
                } else if text != self.finalLocation?.title {
                    self.completer.queryFragment = text
                }
            }
            .store(in: &cancellables)
    }

    func selectSuggestion(_ suggestion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: suggestion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { [weak self] response, error in
            guard let self = self, let mapItem = response?.mapItems.first else { return }
            let coordinate = mapItem.placemark.coordinate
            
            self.searchText = suggestion.title
            self.suggestions = []
            self.finalLocation = TermLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                title: suggestion.title,
                address: suggestion.subtitle
            )
        }
    }
}

class CompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    let onUpdate: ([MKLocalSearchCompletion]) -> Void
    init(onUpdate: @escaping ([MKLocalSearchCompletion]) -> Void) { self.onUpdate = onUpdate }
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) { onUpdate(completer.results) }
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Completer error: \(error.localizedDescription)")
    }
}

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
