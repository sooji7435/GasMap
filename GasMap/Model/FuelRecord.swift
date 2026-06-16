import Foundation

struct FuelRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let stationID: String
    let stationName: String
    let pricePerLiter: Int
    let liters: Double

    var totalCost: Int { Int(Double(pricePerLiter) * liters) }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    var formattedDate: String { Self.dateFormatter.string(from: date) }

    var formattedLiters: String { String(format: "%.1fL", liters) }

    var formattedTotal: String {
        (Self.numberFormatter.string(from: NSNumber(value: totalCost)) ?? "\(totalCost)") + "원"
    }
}
