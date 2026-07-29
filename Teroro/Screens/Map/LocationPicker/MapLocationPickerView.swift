import SwiftUI
import MapKit

struct MapLocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = MapPickerVM()
    @State private var mapType: MKMapType = .standard
    let onSelect: (TermLocation) -> Void

    var body: some View {
        ZStack {
            // Map
            MapViewRepresentable(
                region: $vm.region,
                isMoving: $vm.isMoving,
                hasCenteredOnUser: $vm.hasCenteredOnUser,
                mapType: mapType
            )
            .ignoresSafeArea()

            // Center Pin Indicator
            VStack(spacing: 0) {
                Image(systemName: "mappin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(Color.accentColor)
                    .shadow(color: .black.opacity(0.3), radius: vm.isMoving ? 8 : 3, x: 0, y: vm.isMoving ? 10 : 3)
                    .offset(y: vm.isMoving ? -20 : 0)
                    .scaleEffect(vm.isMoving ? 1.25 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.isMoving)
                
                Circle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 8, height: 4)
                    .scaleEffect(vm.isMoving ? 0.5 : 1.0)
                    .opacity(vm.isMoving ? 0.4 : 0.8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.isMoving)
            }

            // Top Navigation Bar & Map Style Overlay
            VStack {
                HStack(alignment: .top) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(.regularMaterial, in: Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Map Type Buttons
                    VStack(spacing: 8) {
                        MapTypeButton(icon: "map.fill", isSelected: mapType == .standard) {
                            mapType = .standard
                        }
                        MapTypeButton(icon: "globe.americas.fill", isSelected: mapType == .hybrid) {
                            mapType = .hybrid
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                Spacer()

                // Footer with Address and Select Button
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        if vm.isGeocoding {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Визначаємо адресу...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text(vm.title.isEmpty ? "Локація на карті" : vm.title)
                                .font(.headline)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)

                            if let address = vm.address, !address.isEmpty {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52, alignment: .center)
                    .padding(.horizontal, 12)

                    PrimaryButton(
                        title: "Підтвердити",
                        style: .primaryWhiteText,
                        action: {
                            let selectedLoc = TermLocation(
                                latitude: vm.region.center.latitude,
                                longitude: vm.region.center.longitude,
                                title: vm.title.isEmpty ? "Позначка на карті" : vm.title,
                                address: vm.address
                            )
                            onSelect(selectedLoc)
                            dismiss()
                        }
                    )
                    .disabled(vm.isGeocoding)
                    .opacity(vm.isGeocoding ? 0.6 : 1.0)
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            vm.requestUserLocation()
        }
    }
}
