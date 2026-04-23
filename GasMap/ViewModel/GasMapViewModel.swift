import Foundation
import SwiftUI
import CoreLocation
import Combine
import MapKit

@MainActor
class GasMapViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var stations: [GasStation] = []
    @Published var searchCompletions: [MKLocalSearchCompletion] = []
    @Published var stationSearchResults: [StationSearchResult] = []
    @Published var selectedStation: GasStation?
    @Published var selectedFuelType: FuelType = .gasoline
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var activeTab: Tab = .map
    @Published var searchRadius: Int = 5
    
    @AppStorage("priceOffset") private var priceOffset: Int = 30

    enum Tab { case map, ranking }

    private let apiService = OpinetService()
    private let completer = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
                completer.delegate = self  // ✅ 추가
                completer.resultTypes = .address
    }

    var sortedByPrice: [GasStation] {
        stations.sorted {
            if $0.price == $1.price {
                return $0.distance < $1.distance  // 가격 같으면 거리 가까운 순
            }
            return $0.price < $1.price
        }
    }

    var cheapestPrice: String {
        guard let min = stations.min(by: { $0.price < $1.price }) else { return "-" }
        return min.formattedPrice
    }

    var averagePrice: String {
        guard !stations.isEmpty else { return "-" }
        let avg = stations.map(\.price).reduce(0, +) / stations.count
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: avg)) ?? "\(avg)") + "원"
    }
    
    var averagePriceValue: Double {
        guard !stations.isEmpty else { return 0 }
        let total = stations.map(\.price).reduce(0, +)
        return Double(total) / Double(stations.count)
    }

    // MARK: - Load Stations
    func loadStations(coordinate: CLLocationCoordinate2D, radius: Int? = nil) {
        let finalRadius = radius ?? searchRadius
        
        isLoading = true
        errorMessage = nil
        
        Task {
            defer { isLoading = false }

            do {
                stations = try await apiService.fetchNearbyStations(
                    coordinate: coordinate,
                    fuelType: selectedFuelType,
                    radius: finalRadius
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func selectStation(_ station: GasStation) {
        withAnimation(.spring(response: 0.3)) {
            selectedStation = selectedStation?.id == station.id ? nil : station
        }
    }

    func changeFuelType(_ type: FuelType, coordinate: CLLocationCoordinate2D) {
        selectedFuelType = type
        loadStations(coordinate: coordinate)
    }
    
    func updateStations(in region: MKCoordinateRegion) {
        let radius = calculateRadius(from: region.span.latitudeDelta)
        
        // 계산된 반경을 사용하여 데이터 로드
        loadStations(coordinate: region.center, radius: radius)
    }
    
    func calculateScale(span: Double) -> CGFloat {
        // span이 0.02(확대)일 때 1.0, 0.2(축소)일 때 0.5가 되도록 매핑
        let minScale: CGFloat = 0.5
        let maxScale: CGFloat = 1.0
        let minSpan: Double = 0.02
        let maxSpan: Double = 0.2
        
        let scale = maxScale - (CGFloat((span - minSpan) / (maxSpan - minSpan)) * (maxScale - minScale))
        
        // 최소/최대 크기 제한
        return min(max(scale, minScale), maxScale)
    }
    
    private func calculateRadius(from span: Double) -> Int {
        // Span 0.01은 대략 1km 정도
        // 최소 2km ~ 최대 20km 사이로 반경을 조절
        let calculated = Int(span * 100)
        return min(max(calculated, 2), 50)
    }
    
    // 타이핑할 때마다 호출
    func updateCompleter(query: String) {
        if query.isEmpty {
            searchCompletions = []
        } else {
            completer.queryFragment = query
        }
    }
    
    // 자동완성 결과 → 실제 좌표 검색
    func searchLocation(completion: MKLocalSearchCompletion, handler: @escaping (MKCoordinateRegion?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            guard let item = response?.mapItems.first else {
                handler(nil)
                return
            }
            let region = MKCoordinateRegion(
                center: item.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            DispatchQueue.main.async {
                handler(region)
            }
        }
    }
    
    // delegate
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        print("📍 장소 자동완성 결과: \(completer.results.count)개") // 추가
        searchCompletions = completer.results
    }
    
    func searchStationsByName(query: String) {
        guard !query.isEmpty else {
            stationSearchResults = []
            return
        }
        Task {
            do {
                let results = try await apiService.searchStationsByName(name: query)
                print("✅ 주유소 검색 결과: \(results.count)개") // 추가
                results.forEach { print("  - \($0.name), \($0.address)") } // 추가
                stationSearchResults = results
            } catch {
                print("❌ 주유소 검색 실패: \(error)") // 추가
                stationSearchResults = []
            }
        }
    }

    func moveToStation(_ station: StationSearchResult, handler: @escaping (MKCoordinateRegion?) -> Void) {
        let wgs = convertKATECToWGS84(x: station.katecX, y: station.katecY)
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: wgs.lat, longitude: wgs.lon),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        handler(region)
    }
    
    private func convertKATECToWGS84(x: Double, y: Double) -> (lat: Double, lon: Double) {
        let d2r = Double.pi / 180.0
        let r2d = 180.0 / Double.pi
        let k0 = 0.9996
        let a = 6378137.0
        let f = 1 / 298.257223563
        let b = a * (1 - f)
        let e2 = (a*a - b*b) / (a*a)
        let x0 = 400000.0; let y0 = 600000.0
        let lon0 = 128.0 * d2r; let lat0 = 38.0 * d2r
        let e1 = (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))
        let m0 = a * ((1 - e2/4 - 3*e2*e2/64) * lat0 - (3*e2/8 + 3*e2*e2/32) * sin(2*lat0) + (15*e2*e2/256) * sin(4*lat0))
        let m = m0 + (y - y0) / k0
        let mu = m / (a * (1 - e2/4 - 3*e2*e2/64))
        let phi1 = mu + (3*e1/2 - 27*pow(e1,3)/32) * sin(2*mu) + (21*e1*e1/16) * sin(4*mu)
        let n1 = a / sqrt(1 - e2 * sin(phi1) * sin(phi1))
        let t1 = tan(phi1) * tan(phi1)
        let c1 = e2 / (1 - e2) * cos(phi1) * cos(phi1)
        let r1 = a * (1 - e2) / pow(1 - e2 * sin(phi1) * sin(phi1), 1.5)
        let d = (x - x0) / (n1 * k0)
        let lat = phi1 - (n1 * tan(phi1) / r1) * (d*d/2 - (5 + 3*t1 + 10*c1 - 4*c1*c1) * pow(d,4)/24)
        let lon = lon0 + (d - (1 + 2*t1 + c1) * pow(d,3)/6) / cos(phi1)
        return (lat * r2d, lon * r2d)
    }
    
}
