import Foundation
import CoreLocation
import UIKit
import SwiftUI

// MARK: - WidgetTermDTO

/// Lightweight, Codable representation of a Term shared via App Group UserDefaults.
/// Main app writes this data and pre-renders static map snapshots (both light & dark modes) to the App Group container.
struct WidgetTermDTO: Codable {
    let id: String
    let title: String
    let details: String
    let date: Date
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let hasMapImage: Bool?
}

// MARK: - Computed helpers

extension WidgetTermDTO {
    /// CLLocationCoordinate2D if the term has a location.
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Returns address when available; falls back to the first non-empty line of details.
    var subtitle: String? {
        if let address, !address.trimmingCharacters(in: .whitespaces).isEmpty {
            return address
        }
        return details
            .components(separatedBy: .newlines)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}

// MARK: - App Group persistence (read)

extension WidgetTermDTO {
    static let appGroupSuite = "group.com.OleksaChmil.Timora"
    static let storageKey    = "widgetTerms"

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()

    /// All stored upcoming terms, sorted by date ascending (nearest first).
    static func loadUpcoming(referenceDate: Date = .now) -> [WidgetTermDTO] {
        guard
            let defaults = UserDefaults(suiteName: appGroupSuite),
            let data = defaults.data(forKey: storageKey),
            let all = try? decoder.decode([WidgetTermDTO].self, from: data)
        else { return [] }
        return all.filter { $0.date >= referenceDate }.sorted { $0.date < $1.date }
    }

    /// The single nearest upcoming term, or nil when none exist.
    static func next(referenceDate: Date = .now) -> WidgetTermDTO? {
        loadUpcoming(referenceDate: referenceDate).first
    }

    /// Loads the pre-rendered map snapshot image for the requested color mode.
    static func loadMapImage(isDark: Bool) -> UIImage? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupSuite) else { return nil }
        let fileName = isDark ? "next_term_map_dark.jpg" : "next_term_map_light.jpg"
        let fileURL = containerURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else {
            // Fallback to legacy file or opposite style if present
            let fallbackName = isDark ? "next_term_map_light.jpg" : "next_term_map_dark.jpg"
            let fallbackURL = containerURL.appendingPathComponent(fallbackName)
            guard let fallbackData = try? Data(contentsOf: fallbackURL) else {
                let legacyURL = containerURL.appendingPathComponent("next_term_map.jpg")
                guard let legacyData = try? Data(contentsOf: legacyURL) else { return nil }
                return UIImage(data: legacyData)
            }
            return UIImage(data: fallbackData)
        }
        return UIImage(data: data)
    }
}

// MARK: - Preview / Placeholder data

extension WidgetTermDTO {
    static let preview = WidgetTermDTO(
        id: "preview",
        title: "Паспорт",
        details: "Отримати документ",
        date: Calendar.current.date(byAdding: .hour, value: 3, to: .now) ?? .now,
        address: "Plänterwald, Berlin, Germany",
        latitude: 52.4833,
        longitude: 13.4667,
        hasMapImage: true
    )

    static let previewNoLocation = WidgetTermDTO(
        id: "preview-noloc",
        title: "Візит до лікаря",
        details: "Підготувати документи та страховий поліс",
        date: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now,
        address: nil,
        latitude: nil,
        longitude: nil,
        hasMapImage: false
    )
}
