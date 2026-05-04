import Foundation
import CoreLocation

// MARK: - Fuel Type
enum FuelType: String, CaseIterable, Identifiable {
    case gasoline = "B027"
    case diesel   = "D047"
    case lpg      = "K015"
    case premium  = "B034"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .gasoline: return "휘발유"
        case .diesel:   return "경유"
        case .lpg:      return "LPG"
        case .premium:  return "고급휘발유"
        }
    }
    
    var shortName: String {
        switch self {
        case .gasoline: return "휘발유"
        case .diesel:   return "경유"
        case .lpg:      return "LPG"
        case .premium:  return "고급"
        }
    }
}

// MARK: - GasStation
struct GasStation: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String
    let price: Int
    let distance: Double
    
    let address: String?
    let tel: String?
    
    let katecX: Double
    let katecY: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "UNI_ID"
        case name = "OS_NM"
        case brand = "POLL_DIV_CD"
        case price = "PRICE"
        case distance = "DISTANCE"
        case katecX = "GIS_X_COOR"
        case katecY = "GIS_Y_COOR"
        case address = "VAN_ADR"
        case tel = "TEL"
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CoordinateConverter.katecToWGS84(x: katecX, y: katecY)
    }
    
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: price)) ?? "\(price)") + "원"
    }
    
    var formattedDistance: String {
        if distance < 1.0 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    func calculatePriceLevel(average: Double, offset: Int) -> PriceLevel {
        let priceDouble = Double(self.price)
        let cheapLimit = average - Double(offset)
        let expensiveLimit = average + Double(offset)
        
        if priceDouble <= cheapLimit {
            return .cheap
        } else if priceDouble >= expensiveLimit {
            return .expensive
        } else {
            return .mid
        }
    }
    
}

enum PriceLevel {
    case cheap, mid, expensive
    
    var color: String {
        switch self {
        case .cheap:     return "PriceCheap"
        case .mid:       return "PriceMid"
        case .expensive: return "PriceExpensive"
        }
    }
    
    var label: String {
        switch self {
        case .cheap:     return "저렴"
        case .mid:       return "보통"
        case .expensive: return "비쌈"
        }
    }
}

// MARK: - Opinet API Response
struct OpinetResponse: Codable {
    let result: OpinetResult
    
    enum CodingKeys: String, CodingKey {
        case result = "RESULT"
    }
}

struct OpinetResult: Codable {
    let stations: [GasStation]
    
    enum CodingKeys: String, CodingKey {
        case stations = "OIL"
    }
}

// MARK: - Brand
struct Brand {
    static func displayName(_ code: String) -> String {
        switch code {
        case "SKE": return "SK에너지"
        case "GSC": return "GS칼텍스"
        case "HDO": return "현대오일뱅크"
        case "SOL": return "S-OIL"
        case "RTO": return "자영"
        case "RTX": return "자영"
        case "NHO": return "NH주유소"
        case "EXS": return "익스프레스"
        case "E1G": return "E1"
        case "SKG": return "SK가스"
        default:    return code
        }
    }
    
    static func shortName(_ code: String) -> String {
        switch code {
        case "SKE": return "SK"
        case "GSC": return "GS"
        case "HDO": return "HD"
        case "SOL": return "SO"
        case "NHO": return "NH"
        default:    return String(code.prefix(2))
        }
    }
    
    static func color(_ code: String) -> String {
        switch code {
        case "SKE": return "BrandSK"
        case "GSC": return "BrandGS"
        case "HDO": return "BrandHD"
        case "SOL": return "BrandSOIL"
        default:    return "BrandDefault"
        }
    }
}

