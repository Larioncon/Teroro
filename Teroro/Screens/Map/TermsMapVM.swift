import Foundation
import MapKit

@MainActor
final class TermsMapVM: ObservableObject {
    // Default center (Kyiv) - can be updated later when we add real locations.
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234),
        span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
    )

    func items(from terms: [Term], base: CLLocationCoordinate2D) -> [TermMapItem] {

        return terms.map { term in
            // We don't store coordinates yet, so we place terms around the center deterministically.
            let offsets = Self.offset(for: term.id)
            let coordinate = CLLocationCoordinate2D(
                latitude: base.latitude + offsets.lat,
                longitude: base.longitude + offsets.lon
            )
            return TermMapItem(id: term.id, title: term.title, coordinate: coordinate)
        }
    }

    private static func offset(for id: UUID) -> (lat: Double, lon: Double) {
        // Stable small offsets: +- ~0.03 degrees.
        let a = Double(id.uuidString.unicodeScalars.map { UInt32($0.value) }.reduce(0, +) % 61) - 30
        let b = Double(id.uuid.0) - 128
        return (lat: a * 0.001, lon: b * 0.0002)
    }
}

struct TermMapItem: Identifiable {
    let id: UUID
    let title: String
    let coordinate: CLLocationCoordinate2D
}
