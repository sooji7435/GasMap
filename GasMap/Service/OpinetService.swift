import Foundation
import CoreLocation

class OpinetService {
    private let apiKey: String = {
        guard let key = Bundle.main.infoDictionary?["APIKey"] as? String,
              !key.isEmpty else {
            fatalError("OpinetAPIKey가 Info.plist에 없습니다. Secrets.xcconfig를 확인하세요.")
        }
        return key
    }()

    private let baseURL = "https://www.opinet.co.kr/api"


    // MARK: - 주변 주유소 조회 (위도/경도 기반)
    func fetchNearbyStations(
        coordinate: CLLocationCoordinate2D,
        fuelType: FuelType,
        radius: Int = 5,
        count: Int = 20
    ) async throws -> [GasStation] {
        
        let katec = CoordinateConverter.convertWGS84ToKATEC(lat: coordinate.latitude, lon: coordinate.longitude)
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
