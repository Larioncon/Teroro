import SwiftUI
import MapKit

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
