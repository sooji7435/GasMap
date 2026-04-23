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
    
    let address: String? // 데이터에 없어도 에러 나지 않음
    let tel: String?     // 데이터에 없어도 에러 나지 않음
    
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
        return convertKATECToWGS84(x: katecX, y: katecY)
    }

    private func convertKATECToWGS84(x: Double, y: Double) -> CLLocationCoordinate2D {
        let d2r = Double.pi / 180.0
        let r2d = 180.0 / Double.pi
        
        let k0 = 0.9996
        let a = 6378137.0
        let f = 1 / 298.257223563
        let b = a * (1 - f)
        let e2 = (a*a - b*b) / (a*a)
        let e1 = (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))
        
        let lon0 = 128.0 * d2r
        let lat0 = 38.0 * d2r
        let x0 = 400000.0
        let y0 = 600000.0
        
        let x_val = x - x0
        let y_val = y - y0
        
        let m = y_val / k0
        let m0 = a * ((1 - e2/4 - 3*e2*e2/64 - 5*e2*e2*e2/256) * lat0 - (3*e2/8 + 3*e2*e2/32 + 45*e2*e2*e2/1024) * sin(2*lat0) + (15*e2*e2/256 + 45*e2*e2*e2/1024) * sin(4*lat0) - (35*e2*e2*e2/3072) * sin(6*lat0))
        let mu = (m0 + m) / (a * (1 - e2/4 - 3*e2*e2/64 - 5*e2*e2*e2/256))
        
        let phi1 = mu + (3*e1/2 - 27*e1*e1*e1/32) * sin(2*mu) + (21*e1*e1/16 - 55*e1*e1*e1*e1/32) * sin(4*mu) + (151*e1*e1*e1/96) * sin(6*mu)
        
        let n1 = a / sqrt(1 - e2 * sin(phi1) * sin(phi1))
        let t1 = tan(phi1) * tan(phi1)
        let c1 = e2 / (1 - e2) * cos(phi1) * cos(phi1)
        let r1 = a * (1 - e2) / pow(1 - e2 * sin(phi1) * sin(phi1), 1.5)
        let d = x_val / (n1 * k0)
        
        let lat = phi1 - (n1 * tan(phi1) / r1) * (d*d/2 - (5 + 3*t1 + 10*c1 - 4*c1*c1 - 9*e2) * d*d*d*d/24 + (61 + 90*t1 + 298*c1 + 45*t1*t1 - 252*e2 - 3*c1*c1) * d*d*d*d*d*d/720)
        let lon = lon0 + (d - (1 + 2*t1 + c1) * d*d*d/6 + (5 - 2*c1 + 28*t1 - 3*c1*c1 + 8*e2 + 24*t1*t1) * d*d*d*d*d/120) / cos(phi1)

        return CLLocationCoordinate2D(latitude: lat * r2d, longitude: lon * r2d)
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
