import Foundation
import CoreLocation

class OpinetService {

    // TODO: 오피넷 API 키를 여기에 입력하세요
    // 발급: https://www.opinet.co.kr/user/main/mainView.do → 로그인 → 오피넷API → 개인API키발급
    private let apiKey: String = {
        guard let key = Bundle.main.infoDictionary?["OpinetAPIKey"] as? String,
              !key.isEmpty else {
            fatalError("⚠️ OpinetAPIKey가 Info.plist에 없습니다. Secrets.xcconfig를 확인하세요.")
        }
        return key
    }()

    private let baseURL = "https://www.opinet.co.kr/api"

    // MARK: - 좌표 변환
    // OpinetService.swift 내부
    func convertWGS84ToKATEC(lat: Double, lon: Double) -> (x: Double, y: Double) {
        let d2r = Double.pi / 180.0
        let lat_rad = lat * d2r
        let lon_rad = lon * d2r
        
        let k0 = 0.9996
        let a = 6378137.0
        let f = 1 / 298.257223563
        let b = a * (1 - f)
        let e2 = (a*a - b*b) / (a*a)
        
        let lon0 = 128.0 * d2r
        let lat0 = 38.0 * d2r
        let x0 = 400000.0
        let y0 = 600000.0
        
        let n = a / sqrt(1 - e2 * sin(lat_rad) * sin(lat_rad))
        let t = tan(lat_rad) * tan(lat_rad)
        let c = e2 / (1 - e2) * cos(lat_rad) * cos(lat_rad)
        let m = a * ((1 - e2/4 - 3*e2*e2/64) * lat_rad - (3*e2/8 + 3*e2*e2/32) * sin(2*lat_rad) + (15*e2*e2/256) * sin(4*lat_rad))
        let m0 = a * ((1 - e2/4 - 3*e2*e2/64) * lat0 - (3*e2/8 + 3*e2*e2/32) * sin(2*lat0) + (15*e2*e2/256) * sin(4*lat0))
        
        let a_val = (lon_rad - lon0) * cos(lat_rad)
        let x = x0 + k0 * n * (a_val + (1-t+c) * a_val*a_val*a_val/6 + (5-18*t+t*t+72*c) * a_val*a_val*a_val*a_val*a_val/120)
        let y = y0 + k0 * (m - m0 + n * tan(lat_rad) * (a_val*a_val/2 + (5-t+9*c+4*c*c) * a_val*a_val*a_val*a_val/24 + (61-58*t+t*t+600*c) * a_val*a_val*a_val*a_val*a_val*a_val/720))
        
        return (x, y)
    }
    // MARK: - 주변 주유소 조회 (위도/경도 기반)
    func fetchNearbyStations(
        coordinate: CLLocationCoordinate2D,
        fuelType: FuelType,
        radius: Int = 5,
        count: Int = 20
    ) async throws -> [GasStation] {
        
        let katec = convertWGS84ToKATEC(lat: coordinate.latitude, lon: coordinate.longitude)
        // 오피넷은 x=경도, y=위도 (katec 좌표계 사용)
        let urlString = "\(baseURL)/aroundAll.do" +
                "?code=\(apiKey)" +
                "&x=\(String(format: "%.1f", katec.x))" + // 변환된 X
                "&y=\(String(format: "%.1f", katec.y))" + // 변환된 Y
                "&radius=\(radius * 1000)" +
                "&prodcd=\(fuelType.rawValue)" +
                "&sort=1" +
                "&cnt=\(count)" +
                "&out=json"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        let decoded = try JSONDecoder().decode(OpinetResponse.self, from: data)
        
        return decoded.result.stations
    }

    // MARK: - 시도별 최저가 주유소 조회
    func fetchCheapestStations(
        sido: String = "01",
        fuelType: FuelType,
        count: Int = 10
    ) async throws -> [GasStation] {
        let urlString = "\(baseURL)/lowTop.do" +
            "?code=\(apiKey)" +
            "&sido=\(sido)" +
            "&prodcd=\(fuelType.rawValue)" +
            "&cnt=\(count)" +
            "&out=json"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        let decoded = try JSONDecoder().decode(OpinetResponse.self, from: data)
        return decoded.result.stations
    }
}

// MARK: - Mock Data (API 키 없을 때 테스트용)

extension OpinetService {
    func mockStations(coordinate: CLLocationCoordinate2D, fuelType: FuelType) -> [GasStation] {
        let offsets: [(Double, Double, String, String, Int, String)] = [
            (0.003, 0.002,  "GSC", "GS칼텍스 역삼점",      1632, "02-555-1234"),
            (-0.002, 0.004, "SKE", "SK에너지 강남점",      1698, "02-555-2345"),
            (0.005, -0.003, "SOL", "S-OIL 논현점",         1619, "02-555-3456"),
            (-0.004, -0.002,"HDO", "현대오일뱅크 대치점",   1741, "02-555-4567"),
            (0.001, 0.006,  "RTO", "알뜰주유소 선릉",      1671, "02-555-5678"),
            (-0.006, 0.001, "GSC", "GS칼텍스 삼성점",      1655, "02-555-6789"),
            (0.007, 0.003,  "SKE", "SK에너지 도곡점",      1688, "02-555-7890"),
            (-0.003, -0.005,"SOL", "S-OIL 개포점",        1645, "02-555-8901"),
        ]

        return offsets.enumerated().map { index, offset in
            let lat = coordinate.latitude + offset.0
            let lon = coordinate.longitude + offset.1
            
            // CLLocation의 distance는 미터(m) 단위로 나옵니다.
            // 모델의 distance 타입(Double)에 맞춰 그대로 사용합니다.
            let dist = CLLocation(latitude: lat, longitude: lon)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))

            return GasStation(
                id: "ST\(index + 1)",
                name: offset.3,
                brand: offset.2,
                price: offset.4,
                distance: dist,
                address: "서울시 강남구 테헤란로 \((index + 1) * 10)",
                tel: offset.5,
                // 모델에 정의된 KATEC 좌표 필드에 임시 값 할당
                katecX: 310000.0 + Double(index * 100),
                katecY: 540000.0 + Double(index * 100)
            )
        }.sorted { $0.distance < $1.distance }
    }
}

// MARK: - Errors
enum APIError: LocalizedError {
    case invalidURL
    case serverError
    case decodingError
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidURL:     return "잘못된 URL입니다."
        case .serverError:    return "서버 오류가 발생했습니다."
        case .decodingError:  return "데이터 파싱 오류입니다."
        case .noAPIKey:       return "API 키를 입력해주세요."
        }
    }
}
