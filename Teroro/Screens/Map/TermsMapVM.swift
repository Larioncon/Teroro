import SwiftUI
import MapKit
import CoreLocation

@MainActor
final class TermsMapVM: NSObject, ObservableObject, CLLocationManagerDelegate {
    enum MapHintStep: Int, CaseIterable {
        case hybrid = 0
        case standard = 1
        case location = 2
        case completed = 3
    }

    enum CardState: Equatable {
        case loading
        case emptyUpcomingTerms
        case emptyLocations
        case hint
    }

    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234),
        span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
    )

    private let preferredMapTypeKey = "preferredMapType"
    private let hintStepKey = "termsMapHintStep"

    @Published var region: MKCoordinateRegion = defaultRegion
    @Published private(set) var userLocation: CLLocationCoordinate2D?
    @Published var hasCenteredOnInitialPosition: Bool = false

    @Published var mapType: MKMapType {
        didSet {
            UserDefaults.standard.set(Int(mapType.rawValue), forKey: preferredMapTypeKey)
        }
    }

    @Published private(set) var currentHintStep: MapHintStep {
        didSet {
            UserDefaults.standard.set(currentHintStep.rawValue, forKey: hintStepKey)
        }
    }

    @Published private(set) var isHintRevealed: Bool = false

    private var hintRevealTask: Task<Void, Never>?
    private let locationManager = CLLocationManager()
    private var currentTerms: [Term] = []

    override init() {
        let savedMapRaw = UserDefaults.standard.integer(forKey: preferredMapTypeKey)
        self.mapType = MKMapType(rawValue: UInt(savedMapRaw)) ?? .standard

        let savedHintRaw = UserDefaults.standard.integer(forKey: hintStepKey)
        self.currentHintStep = MapHintStep(rawValue: savedHintRaw) ?? .hybrid

        super.init()
        locationManager.delegate = self
    }

    // MARK: - Lifecycle

    func onAppear(terms: [Term]) {
        requestUserLocation()
        setTerms(terms)
        scheduleHintRevealIfNeeded()
    }

    func onDisappear() {
        hintRevealTask?.cancel()
        hintRevealTask = nil
        isHintRevealed = false
    }

    func scheduleHintRevealIfNeeded() {
        guard currentHintStep != .completed else { return }
        hintRevealTask?.cancel()
        hintRevealTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                self.isHintRevealed = true
            }
        }
    }

    // MARK: - Hint Management

    func isHintVisible(for step: MapHintStep) -> Bool {
        isHintRevealed && currentHintStep == step
    }

    func advanceHint(ifCurrent step: MapHintStep? = nil) {
        guard currentHintStep != .completed else { return }
        if let step = step, currentHintStep != step { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            currentHintStep = MapHintStep(rawValue: currentHintStep.rawValue + 1) ?? .completed
        }
    }

    // MARK: - User Actions

    func selectStandardMap() {
        advanceHint(ifCurrent: .standard)
        mapType = .standard
    }

    func selectHybridMap() {
        advanceHint(ifCurrent: .hybrid)
        mapType = .hybrid
    }

    func centerOnUserOrTerms(terms: [Term]) {
        advanceHint(ifCurrent: .location)
        withAnimation(.easeInOut(duration: 0.5)) {
            centerOnUserOrNearestTerm(for: terms)
        }
    }

    // MARK: - Bottom Card State

    func cardState(for terms: [Term], isLoading: Bool) -> CardState {
        if isLoading {
            return .loading
        }
        if upcomingTerms(from: terms).isEmpty {
            return .emptyUpcomingTerms
        }
        if items(from: terms).isEmpty {
            return .emptyLocations
        }
        return .hint
    }

    // MARK: - Location & Region

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
