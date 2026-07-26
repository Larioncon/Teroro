import SwiftUI
import MapKit
import CoreLocation

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

private struct MapTypeButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// UIViewRepresentable for MKMapView to detect region change start/end accurately
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var isMoving: Bool
    @Binding var hasCenteredOnUser: Bool
    var mapType: MKMapType

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.mapType = mapType
        mapView.showsCompass = false
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if uiView.mapType != mapType {
            uiView.mapType = mapType
        }
        if !hasCenteredOnUser && (region.center.latitude != 50.4501 || region.center.longitude != 30.5234) {
            uiView.setRegion(region, animated: true)
            DispatchQueue.main.async {
                self.hasCenteredOnUser = true
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        private var debounceTimer: Timer?
        private var isInitialCenterDone = false

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard let location = userLocation.location, !isInitialCenterDone else { return }
            isInitialCenterDone = true
            let newRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
            mapView.setRegion(newRegion, animated: true)
            DispatchQueue.main.async {
                self.parent.region = newRegion
                self.parent.hasCenteredOnUser = true
            }
        }

        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.isMoving = true
            }
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.parent.isMoving = true
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.parent.isMoving = false
                    self.parent.region = mapView.region
                }
            }
        }
    }
}

@MainActor
final class MapPickerVM: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234), // Kyiv fallback
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var isMoving: Bool = false {
        didSet {
            if !isMoving {
                reverseGeocode()
            }
        }
    }
    @Published var title: String = ""
    @Published var address: String?
    @Published var isGeocoding: Bool = false
    @Published var hasCenteredOnUser: Bool = false

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestUserLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            if !hasCenteredOnUser {
                hasCenteredOnUser = true
                region = MKCoordinateRegion(
                    center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                )
                reverseGeocode()
            }
        }
    }

    private func reverseGeocode() {
        let centerLocation = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        isGeocoding = true

        geocoder.reverseGeocodeLocation(centerLocation) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.isGeocoding = false
                if let placemark = placemarks?.first {
                    self.title = placemark.name ?? placemark.thoroughfare ?? "Локація"
                    var addressComponents: [String] = []
                    if let thoroughfare = placemark.thoroughfare {
                        var street = thoroughfare
                        if let subThoroughfare = placemark.subThoroughfare {
                            street += ", \(subThoroughfare)"
                        }
                        addressComponents.append(street)
                    }
                    if let locality = placemark.locality {
                        addressComponents.append(locality)
                    }
                    self.address = addressComponents.joined(separator: ", ")
                } else {
                    self.title = "Обране місце"
                    self.address = String(format: "%.4f, %.4f", self.region.center.latitude, self.region.center.longitude)
                }
            }
        }
    }
}
