import WidgetKit
import SwiftUI
import MapKit
import UIKit

// MARK: - Timeline Entry

struct NextTermEntry: TimelineEntry {
    let date: Date
    let term: WidgetTermDTO?
    let lightMapImage: UIImage?
    let darkMapImage: UIImage?
}

// MARK: - Timeline Provider

struct NextTermProvider: TimelineProvider {

    func placeholder(in context: Context) -> NextTermEntry {
        NextTermEntry(date: .now, term: .preview, lightMapImage: nil, darkMapImage: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextTermEntry) -> Void) {
        let term: WidgetTermDTO? = context.isPreview ? .preview : WidgetTermDTO.next()
        let light = WidgetTermDTO.loadMapImage(isDark: false)
        let dark  = WidgetTermDTO.loadMapImage(isDark: true)
        completion(NextTermEntry(date: .now, term: term, lightMapImage: light, darkMapImage: dark))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextTermEntry>) -> Void) {
        let now = Date()
        let term = WidgetTermDTO.next(referenceDate: now)
        var light = WidgetTermDTO.loadMapImage(isDark: false)
        var dark  = WidgetTermDTO.loadMapImage(isDark: true)

        let policy: TimelineReloadPolicy
        if let termDate = term?.date, termDate > now {
            policy = .after(termDate)
        } else {
            let fallback = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now
            policy = .after(fallback)
        }

        // If pre-rendered map images exist from main app, finish immediately (0ms, 0MB RAM)
        if light != nil || dark != nil || term?.coordinate == nil {
            let entry = NextTermEntry(date: now, term: term, lightMapImage: light, darkMapImage: dark)
            completion(Timeline(entries: [entry], policy: policy))
            return
        }

        // Fallback: generate low-res snapshots if main app hasn't synced yet
        Task {
            if let coord = term?.coordinate {
                light = await makeLightweightMapSnapshot(for: coord, isDark: false)
                dark  = await makeLightweightMapSnapshot(for: coord, isDark: true)
            }
            let entry = NextTermEntry(date: now, term: term, lightMapImage: light, darkMapImage: dark)
            completion(Timeline(entries: [entry], policy: policy))
        }
    }

    private func makeLightweightMapSnapshot(for coordinate: CLLocationCoordinate2D, isDark: Bool) async -> UIImage? {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )
        options.size = CGSize(width: 300, height: 100)
        options.scale = 1.0
        options.traitCollection = UITraitCollection(userInterfaceStyle: isDark ? .dark : .light)

        return await withCheckedContinuation { continuation in
            MKMapSnapshotter(options: options).start { snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    continuation.resume(returning: nil)
                    return
                }

                let rendered = UIGraphicsImageRenderer(size: options.size).image { _ in
                    snapshot.image.draw(at: .zero)
                    let pt = snapshot.point(for: coordinate)
                    let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
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
                continuation.resume(returning: rendered)
            }
        }
    }
}

// MARK: - Widget Configuration

struct TimexoWidget: Widget {
    let kind: String = "NextTermWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextTermProvider()) { entry in
            NextTermWidgetView(entry: entry)
                .applyWidgetBackground()
        }
        .configurationDisplayName("Наступний термін")
        .description("Показує найближчий запланований термін.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TimexoHorizontalWidget: Widget {
    let kind: String = "NextTermHorizontalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextTermProvider()) { entry in
            NextTermHorizontalWidgetView(entry: entry)
                .applyWidgetBackground()
        }
        .configurationDisplayName("Наступний термін")
        .description("Показує найближчий термін та мапу поруч у дві колонки.")
        .supportedFamilies([.systemMedium])
    }
}

private extension View {
    @ViewBuilder
    func applyWidgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.background(Color(uiColor: .systemBackground))
        }
    }
}

// MARK: - Previews
#if os(iOS)
@available(iOS 17.0, *)
#Preview("Medium", as: .systemMedium) {
    TimexoWidget()
} timeline: {
    NextTermEntry(date: .now, term: .preview, lightMapImage: nil, darkMapImage: nil)
    NextTermEntry(date: .now, term: .previewNoLocation, lightMapImage: nil, darkMapImage: nil)
    NextTermEntry(date: .now, term: nil, lightMapImage: nil, darkMapImage: nil)
}

@available(iOS 17.0, *)
#Preview("Small", as: .systemSmall) {
    TimexoWidget()
} timeline: {
    NextTermEntry(date: .now, term: .preview, lightMapImage: nil, darkMapImage: nil)
    NextTermEntry(date: .now, term: .previewNoLocation, lightMapImage: nil, darkMapImage: nil)
    NextTermEntry(date: .now, term: nil, lightMapImage: nil, darkMapImage: nil)
}
#endif
