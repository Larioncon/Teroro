import SwiftUI
import WidgetKit
import UIKit

// MARK: - Root View

struct NextTermWidgetView: View {
    let entry: NextTermEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let term = entry.term {
                switch family {
                case .systemSmall:
                    SmallTermView(term: term)
                default:
                    MediumTermView(term: term, lightMapImage: entry.lightMapImage, darkMapImage: entry.darkMapImage)
                }
            } else {
                NoTermView(family: family)
            }
        }
        .widgetURL(deepLink)
    }

    private var deepLink: URL {
        if let id = entry.term?.id {
            return URL(string: "teroro://term/\(id)") ?? URL(string: "teroro://")!
        }
        return URL(string: "teroro://")!
    }
}

// MARK: - Small (systemSmall)

private struct SmallTermView: View {
    let term: WidgetTermDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TermHeader(compact: true)

            Spacer(minLength: 8)

            Text(term.title)
                .font(.headline.bold())
                .foregroundStyle(.primary)
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 4)

            if let sub = term.subtitle {
                Text(sub)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(formattedDate(term.date))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Medium (systemMedium)

private struct MediumTermView: View {
    let term: WidgetTermDTO
    let lightMapImage: UIImage?
    let darkMapImage: UIImage?

    @Environment(\.colorScheme) private var colorScheme

    private var activeMapImage: UIImage? {
        if colorScheme == .dark {
            return darkMapImage ?? lightMapImage
        } else {
            return lightMapImage ?? darkMapImage
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TermHeader(compact: false)

            // Info block
            VStack(alignment: .leading, spacing: 2) {
                Text(term.title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                if let sub = term.subtitle {
                    Text(sub)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(formattedDate(term.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Map image
            if let mapImage = activeMapImage {
                MapImageView(uiImage: mapImage)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - No upcoming terms

private struct NoTermView: View {
    let family: WidgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TermHeader(compact: family == .systemSmall)
            Spacer()
            Text("Немає запланованих термінів")
                .font(family == .systemSmall ? .caption : .subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Shared header

private struct TermHeader: View {
    let compact: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(.red)
            Text(compact ? "Наступний" : "Наступний термін")
                .font(compact
                      ? .caption2.weight(.semibold)
                      : .caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Date formatting

private func formattedDate(_ date: Date) -> String {
    let cal = Calendar.current
    let timeFmt = DateFormatter()
    timeFmt.locale     = .current
    timeFmt.dateFormat = "HH:mm"
    let time = timeFmt.string(from: date)

    if cal.isDateInToday(date)    { return "Сьогодні, \(time)" }
    if cal.isDateInTomorrow(date) { return "Завтра, \(time)" }

    let dateFmt = DateFormatter()
    dateFmt.locale     = .current
    dateFmt.dateFormat = "d MMM"
    return "\(dateFmt.string(from: date)), \(time)"
}

// MARK: - Map Image View (iOS Tinted & Dark mode handling)

private struct MapImageView: View {
    let uiImage: UIImage

    var body: some View {
        if #available(iOS 18.0, *) {
            Image(uiImage: uiImage)
                .resizable()
                .widgetAccentedRenderingMode(.accentedDesaturated)
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            Image(uiImage: uiImage)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
