import WidgetKit
import SwiftUI

// 메인 앱과 공유하는 데이터 모델
struct WidgetStation: Codable, Identifiable {
    var id: String { name + "\(price)" }
    let name: String
    let price: Int
    let brand: String
    let distance: String

    var formattedPrice: String { "\(price)원" }

    var brandColor: Color {
        switch brand {
        case "SKE": return Color(red: 0.83, green: 0.14, blue: 0.14)
        case "GSC": return Color(red: 0.0, green: 0.47, blue: 0.22)
        case "HDO": return Color(red: 0.0, green: 0.32, blue: 0.65)
        case "SOL": return Color(red: 0.86, green: 0.13, blue: 0.13)
        default:    return .orange
        }
    }
}

// MARK: - Timeline Entry

struct GasMapEntry: TimelineEntry {
    let date: Date
    let stations: [WidgetStation]
    let updatedAt: Date?

    var updatedText: String {
        guard let updated = updatedAt else { return "앱을 열어 업데이트" }
        let mins = Int(-updated.timeIntervalSinceNow / 60)
        if mins < 1  { return "방금 업데이트" }
        if mins < 60 { return "\(mins)분 전 업데이트" }
        return "\(mins / 60)시간 전 업데이트"
    }
}

// MARK: - Provider

struct GasMapProvider: TimelineProvider {
    private let suiteName = "group.me.younsu.park.GasMap"

    func placeholder(in context: Context) -> GasMapEntry {
        GasMapEntry(date: Date(), stations: sample, updatedAt: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (GasMapEntry) -> Void) {
        completion(GasMapEntry(date: Date(), stations: loadStations(), updatedAt: loadUpdatedAt()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GasMapEntry>) -> Void) {
        let entry = GasMapEntry(date: Date(), stations: loadStations(), updatedAt: loadUpdatedAt())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadStations() -> [WidgetStation] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: "widgetStations"),
              let decoded = try? JSONDecoder().decode([WidgetStation].self, from: data) else { return [] }
        return decoded
    }

    private func loadUpdatedAt() -> Date? {
        UserDefaults(suiteName: suiteName)?.object(forKey: "widgetUpdatedAt") as? Date
    }

    private var sample: [WidgetStation] {[
        WidgetStation(name: "GS칼텍스 강남점", price: 1650, brand: "GSC", distance: "0.5km"),
        WidgetStation(name: "SK에너지",       price: 1680, brand: "SKE", distance: "0.8km"),
        WidgetStation(name: "현대오일뱅크",    price: 1710, brand: "HDO", distance: "1.2km"),
    ]}
}

// MARK: - Small Widget View

private struct SmallView: View {
    let entry: GasMapEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("주변 최저가", systemImage: "fuelpump.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.orange)

            Spacer()

            if let s = entry.stations.first {
                Text(s.formattedPrice)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.primary)
                Text(s.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(s.distance)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.top, 1)
            } else {
                Text("앱을 열어\n검색하세요")
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

// MARK: - Medium Widget View

private struct MediumView: View {
    let entry: GasMapEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("주변 최저가 주유소", systemImage: "fuelpump.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.orange)
                Spacer()
                Text(entry.updatedText)
                    .font(.system(size: 10))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(.bottom, 8)

            if entry.stations.isEmpty {
                Text("앱을 열어 주유소를 검색하세요")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(Array(entry.stations.prefix(3).enumerated()), id: \.offset) { i, s in
                    HStack(spacing: 8) {
                        Text("\(i + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(i == 0 ? .green : .secondary)
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
                            .foregroundColor(i == 0 ? .green : .primary)
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

// MARK: - Entry View

struct GasMapWidgetEntryView: View {
    let entry: GasMapEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallView(entry: entry)
        default:            MediumView(entry: entry)
        }
    }
}

// MARK: - Widget

@main
struct GasMapWidget: Widget {
    let kind = "GasMapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GasMapProvider()) { entry in
            GasMapWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("GasMap 주유소")
        .description("주변 최저가 주유소를 홈화면에서 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
