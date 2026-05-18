import Foundation
import MapKit

@MainActor
final class TermsMapVM: ObservableObject {
    // Default center (Kyiv) - can be updated later when we add real locations.
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234),
        span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
    )

    func items(from terms: [Term], base _: CLLocationCoordinate2D) -> [TermMapItem] {
        terms.compactMap { term in
            guard let location = term.location else { return nil }
            let coordinate = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
            return TermMapItem(id: term.id, title: term.title, coordinate: coordinate)
        }
    }
}

struct TermMapItem: Identifiable {
    let id: UUID
    let title: String
    let coordinate: CLLocationCoordinate2D
}
