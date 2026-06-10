import Foundation

struct FuelRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let stationID: String
    let stationName: String
    let pricePerLiter: Int
    let liters: Double

    var totalCost: Int { Int(Double(pricePerLiter) * liters) }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f.string(from: date)
    }

    var formattedLiters: String { String(format: "%.1fL", liters) }

    var formattedTotal: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return (f.string(from: NSNumber(value: totalCost)) ?? "\(totalCost)") + "원"
    }
}
