import Foundation
import CoreLocation

class OpinetService {

    // TODO: 오피넷 API 키를 여기에 입력하세요
    // 발급: https://www.opinet.co.kr/user/main/mainView.do → 로그인 → 오피넷API → 개인API키발급
    private let apiKey: String = {
        guard let key = Bundle.main.infoDictionary?["APIKey"] as? String,
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
    
    // MARK: - 주유소명 검색
    func searchStationsByName(name: String) async throws -> [StationSearchResult] {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let urlString = "\(baseURL)/searchByName.do" +
            "?code=\(apiKey)" +
            "&out=json" +
            "&osnm=\(encodedName)"
        
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else { throw APIError.serverError }
        
        let decoded = try JSONDecoder().decode(StationSearchResponse.self, from: data)
        return decoded.result.stations
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
