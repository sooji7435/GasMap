import WidgetKit
import SwiftUI

// MARK: - Provider

struct FavoritesProvider: TimelineProvider {
    private let suiteName = "group.me.younsu.park.GasMap"

    func placeholder(in context: Context) -> GasMapEntry {
        GasMapEntry(date: Date(), stations: sample, updatedAt: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (GasMapEntry) -> Void) {
        completion(GasMapEntry(date: Date(), stations: loadFavorites(), updatedAt: loadUpdatedAt()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GasMapEntry>) -> Void) {
        let entry = GasMapEntry(date: Date(), stations: loadFavorites(), updatedAt: loadUpdatedAt())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadFavorites() -> [WidgetStation] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: "widgetFavorites"),
              let decoded = try? JSONDecoder().decode([WidgetStation].self, from: data) else { return [] }
        return decoded
    }

    private func loadUpdatedAt() -> Date? {
        UserDefaults(suiteName: suiteName)?.object(forKey: "widgetFavoritesUpdatedAt") as? Date
    }

    private var sample: [WidgetStation] {[
        WidgetStation(name: "GS칼텍스 강남점", price: 1650, brand: "GSC", distance: "0.5km"),
        WidgetStation(name: "SK에너지",       price: 1680, brand: "SKE", distance: "0.8km"),
    ]}
}

// MARK: - Views

private struct FavoritesSmallView: View {
    let entry: GasMapEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("즐겨찾기", systemImage: "heart.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.red)

            Spacer()

            if let s = entry.stations.first {
                Text(s.formattedPrice)
                    .font(.system(size: 30, weight: .bold))
                Text(s.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text(s.distance)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.top, 1)
            } else {
                Text("즐겨찾기한\n주유소가 없어요")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(entry.updatedText)
                .font(.system(size: 9))
                .foregroundColor(Color(.systemGray3))
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.background, for: .widget)
    }
}

private struct FavoritesMediumView: View {
    let entry: GasMapEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("즐겨찾기 주유소", systemImage: "heart.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red)
                Spacer()
                Text(entry.updatedText)
                    .font(.system(size: 10))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(.bottom, 8)

            if entry.stations.isEmpty {
                Text("앱에서 주유소를 즐겨찾기에 추가하세요")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(Array(entry.stations.prefix(3).enumerated()), id: \.offset) { i, s in
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red.opacity(0.7))
                            .frame(width: 14)
                        Text(s.name)
                            .font(.system(size: 13))
                            .lineLimit(1)
                        Spacer()
                        Text(s.distance)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(s.formattedPrice)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 58, alignment: .trailing)
                    }
                    .padding(.vertical, 5)
                    if i < min(entry.stations.count, 3) - 1 { Divider() }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.background, for: .widget)
    }
}

struct FavoritesWidgetEntryView: View {
    let entry: GasMapEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall: FavoritesSmallView(entry: entry)
        default:           FavoritesMediumView(entry: entry)
        }
    }
}

// MARK: - Widget

struct GasMapFavoritesWidget: Widget {
    let kind = "GasMapFavoritesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FavoritesProvider()) { entry in
            FavoritesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("즐겨찾기 주유소")
        .description("즐겨찾기한 주유소의 최근 가격을 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
