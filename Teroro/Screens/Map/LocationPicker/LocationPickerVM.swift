import SwiftUI
import MapKit
import CoreLocation
import Combine

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
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self else { return }
                if text.isEmpty {
                    if !self.suggestions.isEmpty {
                        self.suggestions = []
                    }
                    if self.finalLocation != nil {
                        self.finalLocation = nil
                    }
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
