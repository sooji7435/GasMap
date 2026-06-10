import Foundation

struct SearchRecord: Identifiable, Codable {
    let id: UUID
    let name: String
    let subtitle: String
    let lat: Double
    let lon: Double
    let date: Date
}
