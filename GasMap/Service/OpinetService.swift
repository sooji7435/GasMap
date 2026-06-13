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
        let url = try buildURL(path: "aroundAll.do", queryItems: [
            URLQueryItem(name: "code",   value: apiKey),
            URLQueryItem(name: "x",      value: String(format: "%.1f", katec.x)),
            URLQueryItem(name: "y",      value: String(format: "%.1f", katec.y)),
            URLQueryItem(name: "radius", value: "\(radius * 1000)"),
            URLQueryItem(name: "prodcd", value: fuelType.rawValue),
            URLQueryItem(name: "sort",   value: "1"),
            URLQueryItem(name: "cnt",    value: "\(count)"),
            URLQueryItem(name: "out",    value: "json"),
        ])
        let decoded = try await fetch(OpinetResponse.self, from: url)
        return decoded.result.stations
    }

    // MARK: - 주유소명 검색
    func searchStationsByName(name: String) async throws -> [StationSearchResult] {
        let url = try buildURL(path: "searchByName.do", queryItems: [
            URLQueryItem(name: "code", value: apiKey),
            URLQueryItem(name: "out",  value: "json"),
            URLQueryItem(name: "osnm", value: name),
        ])
        let decoded = try await fetch(StationSearchResponse.self, from: url)
        return decoded.result.stations
    }

    // MARK: - Helpers
    private func buildURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        var components = URLComponents(string: "\(baseURL)/\(path)")!
        components.queryItems = queryItems
        guard let url = components.url else { throw APIError.invalidURL }
        return url
    }

    private func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        return try JSONDecoder().decode(T.self, from: data)
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
