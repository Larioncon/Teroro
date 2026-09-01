import WidgetKit
import SwiftUI
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
        let hasMap = term?.hasMapImage ?? (term?.coordinate != nil)
        let light = hasMap ? WidgetTermDTO.loadMapImage(isDark: false) : nil
        let dark  = hasMap ? WidgetTermDTO.loadMapImage(isDark: true) : nil
        completion(NextTermEntry(date: .now, term: term, lightMapImage: light, darkMapImage: dark))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextTermEntry>) -> Void) {
        let now = Date()
        let term = WidgetTermDTO.next(referenceDate: now)
        let hasMap = term?.hasMapImage ?? (term?.coordinate != nil)
        let light = hasMap ? WidgetTermDTO.loadMapImage(isDark: false) : nil
        let dark  = hasMap ? WidgetTermDTO.loadMapImage(isDark: true) : nil

        let policy: TimelineReloadPolicy
        if let termDate = term?.date, termDate > now {
            policy = .after(termDate)
        } else {
            let fallback = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now
            policy = .after(fallback)
        }

        let entry = NextTermEntry(date: now, term: term, lightMapImage: light, darkMapImage: dark)
        completion(Timeline(entries: [entry], policy: policy))
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
