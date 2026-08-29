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
        return URL(string: "teroro://add")!
    }
}

// MARK: - Root View (Horizontal Medium)

struct NextTermHorizontalWidgetView: View {
    let entry: NextTermEntry

    var body: some View {
        Group {
            if let term = entry.term {
                MediumHorizontalTermView(
                    term: term,
                    lightMapImage: entry.lightMapImage,
                    darkMapImage: entry.darkMapImage
                )
            } else {
                NoTermView(family: .systemMedium)
            }
        }
        .widgetURL(deepLink)
    }

    private var deepLink: URL {
        if let id = entry.term?.id {
            return URL(string: "teroro://term/\(id)") ?? URL(string: "teroro://")!
        }
        return URL(string: "teroro://add")!
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
        .padding(11)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Первый вариант (Одноколоночный вертикальный макет)

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
         GeometryReader { geometry in
             VStack(alignment: .leading, spacing: 4) {

                 TermHeader(compact: false)

                 VStack(alignment: .leading, spacing: 1) {
                     Text(term.title)
                         .font(.headline.bold())
                         .foregroundStyle(.primary)
                         .lineLimit(1)
                         .minimumScaleFactor(0.85)

                     if let sub = term.subtitle {
                         Text(sub)
                             .font(.caption)
                             .foregroundStyle(.secondary)
                             .lineLimit(1)
                     }

                     Text(formattedDate(term.date))
                         .font(.caption)
                         .foregroundStyle(.secondary)
                 }

                 if let mapImage = activeMapImage {
                     MapImageView(uiImage: mapImage)
                         .frame(
                             height: mapHeight(
                                 for: geometry.size.height
                             )
                         )
                         .clipShape(
                             RoundedRectangle(cornerRadius: 10)
                         )
                 } else {
                     Spacer(minLength: 0)
                 }
             }
             .frame(
                 width: geometry.size.width,
                 height: geometry.size.height,
                 alignment: .topLeading
             )
         }
         .padding(.horizontal, 11)

     }

     private func mapHeight(for availableHeight: CGFloat) -> CGFloat {
         let calculatedHeight = availableHeight * 0.47

         return min(
             max(calculatedHeight, 45),
             70
         )
     }
 }
    
    
    

// MARK: - Второй вариант 

private struct MediumHorizontalTermView: View {
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
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                TermHeader(compact: false)

                Spacer(minLength: 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(term.title)
                        .font(.headline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

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
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if let mapImage = activeMapImage {
                MapImageView(uiImage: mapImage)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - No upcoming terms

private struct NoTermView: View {
    let family: WidgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TermHeader(compact: family == .systemSmall)
//            Spacer()
            Text("Немає запланованих термінів")
                .font(family == .systemSmall ? .caption : .subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(11)
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
        } else {
            Image(uiImage: uiImage)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
}
