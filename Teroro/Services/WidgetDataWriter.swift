import Foundation
import WidgetKit
import MapKit
import UIKit

/// Encodes upcoming terms into the shared App Group UserDefaults
/// and pre-renders static map images (both light and dark modes) directly in the main app
/// so the TimexoWidget extension displays crisp dark maps in Dark & Tinted mode without white box artifacting.
enum WidgetDataWriter {

    // MARK: - Constants

    private static let suite           = "group.com.OleksaChmil.Timora"
    private static let key             = "widgetTerms"
    private static let widgetKind      = "NextTermWidget"
    private static let mapLightFileName = "next_term_map_light.jpg"
    private static let mapDarkFileName  = "next_term_map_dark.jpg"

    // MARK: - Internal DTO

    private struct DTO: Codable {
        let id: String
        let title: String
        let details: String
        let date: Date
        let address: String?
        let latitude: Double?
        let longitude: Double?
        let hasMapImage: Bool
    }

    // MARK: - Public API

    /// Filters `terms` to upcoming active ones, pre-renders map snapshots (both light & dark modes),
    /// encodes the DTO list into App Group UserDefaults, and reloads the WidgetKit timeline.
    static func sync(_ terms: [Term]) {
        let now = Date()
        let upcomingTerms = terms
            .filter { $0.status == .active && $0.date >= now }
            .sorted { $0.date < $1.date }

        let nearestWithLocation = upcomingTerms.first(where: { $0.location != nil })

        Task {
            var hasMap = false
            if let loc = nearestWithLocation?.location {
                let lightSuccess = await generateAndSaveMapSnapshot(latitude: loc.latitude, longitude: loc.longitude, isDark: false)
                let darkSuccess  = await generateAndSaveMapSnapshot(latitude: loc.latitude, longitude: loc.longitude, isDark: true)
                hasMap = lightSuccess || darkSuccess
            } else {
                removeMapSnapshots()
            }

            let dtos: [DTO] = upcomingTerms.map { t in
                let isNearestLoc = (t.id == nearestWithLocation?.id)
                return DTO(
                    id: t.id.uuidString,
                    title: t.title,
                    details: t.details,
                    date: t.date,
                    address: t.location?.address ?? t.location?.title,
                    latitude: t.location?.latitude,
                    longitude: t.location?.longitude,
                    hasMapImage: isNearestLoc && hasMap
                )
            }

            guard let defaults = UserDefaults(suiteName: suite) else { return }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            if let data = try? encoder.encode(dtos) {
                defaults.set(data, forKey: key)
            }

            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    static func clear() {
        if let defaults = UserDefaults(suiteName: suite) {
            defaults.removeObject(forKey: key)
        }
        removeMapSnapshots()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Private Helpers
    
    private static var appGroupContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suite)
    }

    private static func generateAndSaveMapSnapshot(latitude: Double, longitude: Double, isDark: Bool) async -> Bool {
        guard let containerURL = appGroupContainerURL else { return false }
        let fileName = isDark ? mapDarkFileName : mapLightFileName
        let fileURL = containerURL.appendingPathComponent(fileName)

        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )
        options.size = CGSize(width: 360, height: 130)
        options.scale = UIScreen.main.scale
        options.traitCollection = UITraitCollection(userInterfaceStyle: isDark ? .dark : .light)

        return await withCheckedContinuation { continuation in
            MKMapSnapshotter(options: options).start { snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    continuation.resume(returning: false)
                    return
                }

                let rendered = UIGraphicsImageRenderer(size: options.size).image { _ in
                    snapshot.image.draw(at: .zero)
                    let pt = snapshot.point(for: coord)
                    let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
                    if let pin = UIImage(systemName: "circle.dashed")?
                        .withConfiguration(config)
                        .withTintColor(.systemRed, renderingMode: .alwaysOriginal) {
                        let rect = CGRect(
                            x: pt.x - pin.size.width / 2,
                            y: pt.y - pin.size.height,
                            width: pin.size.width,
                            height: pin.size.height
                        )
                        pin.draw(in: rect)
                    }
                }

                if let jpegData = rendered.jpegData(compressionQuality: 0.8) {
                    do {
                        try jpegData.write(to: fileURL, options: .atomic)
                        continuation.resume(returning: true)
                    } catch {
                        continuation.resume(returning: false)
                    }
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private static func removeMapSnapshots() {
        guard let containerURL = appGroupContainerURL else { return }
        let lightURL = containerURL.appendingPathComponent(mapLightFileName)
        let darkURL  = containerURL.appendingPathComponent(mapDarkFileName)
        try? FileManager.default.removeItem(at: lightURL)
        try? FileManager.default.removeItem(at: darkURL)
    }
}
