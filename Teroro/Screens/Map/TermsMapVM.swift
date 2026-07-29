import Foundation
import MapKit
import CoreLocation

@MainActor
final class TermsMapVM: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234),
        span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
    )

    @Published var region: MKCoordinateRegion = defaultRegion
    @Published private(set) var userLocation: CLLocationCoordinate2D?
    @Published var hasCenteredOnInitialPosition: Bool = false

    private let locationManager = CLLocationManager()
    private var currentTerms: [Term] = []

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestUserLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.userLocation = location.coordinate
            self.updateRegionIfNeeded()
        }
    }

    func setTerms(_ terms: [Term]) {
        self.currentTerms = terms
        updateRegionIfNeeded()
    }

    /// Returns only active, upcoming terms (date >= referenceDate)
    func upcomingTerms(from terms: [Term]? = nil, referenceDate: Date = Date()) -> [Term] {
        let termsToFilter = terms ?? currentTerms
        return termsToFilter.filter { $0.status == .active && $0.date >= referenceDate }
    }

    /// Returns map items ONLY for upcoming active terms with location
    func items(from terms: [Term]? = nil, referenceDate: Date = Date()) -> [TermMapItem] {
        let upcoming = upcomingTerms(from: terms, referenceDate: referenceDate)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.dateFormat = "d MMM, HH:mm"

        return upcoming.compactMap { term in
            guard let location = term.location else { return nil }
            let coordinate = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
            let dateStr = dateFormatter.string(from: term.date)
            return TermMapItem(
                id: term.id,
                title: term.title,
                subtitle: dateStr,
                coordinate: coordinate,
                term: term
            )
        }
    }

    /// Calculates initial region prioritizing:
    /// 1. User location (if available)
    /// 2. Nearest upcoming term's location
    /// 3. Default region (Kyiv fallback)
    func calculateBestRegion(for terms: [Term]? = nil, referenceDate: Date = Date()) -> MKCoordinateRegion {
        if let userLocation = userLocation {
            return MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }

        let itemsWithLoc = items(from: terms, referenceDate: referenceDate)
        if let nearestItem = itemsWithLoc.min(by: { abs($0.term.date.timeIntervalSince(referenceDate)) < abs($1.term.date.timeIntervalSince(referenceDate)) }) {
            return MKCoordinateRegion(
                center: nearestItem.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }

        return Self.defaultRegion
    }

    func updateRegionIfNeeded(for terms: [Term]? = nil, referenceDate: Date = Date()) {
        if let terms = terms {
            self.currentTerms = terms
        }
        guard !hasCenteredOnInitialPosition else { return }
        
        let itemsWithLoc = items(from: currentTerms, referenceDate: referenceDate)
        if userLocation != nil || !itemsWithLoc.isEmpty {
            self.region = calculateBestRegion(for: currentTerms, referenceDate: referenceDate)
            self.hasCenteredOnInitialPosition = true
        }
    }

    func centerOnUserOrNearestTerm(for terms: [Term]? = nil, referenceDate: Date = Date()) {
        let termsToUse = terms ?? currentTerms
        self.region = calculateBestRegion(for: termsToUse, referenceDate: referenceDate)
    }
}

struct TermMapItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let term: Term

    static func == (lhs: TermMapItem, rhs: TermMapItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.title == rhs.title
    }
}


