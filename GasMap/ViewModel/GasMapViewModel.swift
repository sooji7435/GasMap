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
    @Published var selectedFuelType: FuelType
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var activeTab: Tab = .map
    @Published var searchRadius: Int = 5
    
    @AppStorage("priceOffset") private var priceOffset: Int = 30

    enum Tab { case map, ranking }
    
    private enum RadiusConfig {
        static let multiplier: Double = 100
        static let minimum: Int = 2
        static let maximum: Int = 50
    }

    private let apiService = OpinetService()
    private let completer = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()
    private var fetchTask: Task<Void, Never>?
    private var lastFetchCenter: CLLocationCoordinate2D?
    private var lastFetchRadius: Int = 0
    
    override init() {
        let savedRaw = UserDefaults.standard.string(forKey: "selectedFuelType") ?? FuelType.gasoline.rawValue
        self.selectedFuelType = FuelType(rawValue: savedRaw) ?? .gasoline
        super.init()
        completer.delegate = self
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
        let total = stations.map(\.price).reduce(0, +)
        let avg = Double(total) / Double(stations.count)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        formatter.maximumFractionDigits = 0
        
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

        fetchTask?.cancel()
        isLoading = true
        errorMessage = nil

        fetchTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isLoading = false }

            do {
                let result = try await self.apiService.fetchNearbyStations(
                    coordinate: coordinate,
                    fuelType: self.selectedFuelType,
                    radius: finalRadius
                )
                guard !Task.isCancelled else { return }
                self.stations = result
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = error.localizedDescription
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
        UserDefaults.standard.set(type.rawValue, forKey: "selectedFuelType")
        loadStations(coordinate: coordinate)
    }
    
    func updateStations(in region: MKCoordinateRegion) {
        let radius = calculateRadius(from: region.span.latitudeDelta)

        // 이전 fetch 위치에서 반경의 30% 미만 이동 + 반경 동일 → API 호출 스킵
        if let last = lastFetchCenter {
            let latDiff = abs(region.center.latitude - last.latitude)
            let lonDiff = abs(region.center.longitude - last.longitude)
            let threshold = Double(radius) * 0.3 / 111.0  // 반경(km)의 30%를 위도 단위로 변환
            if latDiff < threshold && lonDiff < threshold && radius == lastFetchRadius {
                return
            }
        }

        lastFetchCenter = region.center
        lastFetchRadius = radius
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
        let calculated = Int(span * RadiusConfig.multiplier)
        return min(max(calculated, RadiusConfig.minimum), RadiusConfig.maximum)
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
        searchCompletions = completer.results
    }

    func searchStationsByName(query: String) {
        guard !query.isEmpty else {
            stationSearchResults = []
            return
        }
        Task {
            do {
                stationSearchResults = try await apiService.searchStationsByName(name: query)
            } catch {
                stationSearchResults = []
            }
        }
    }

    func moveToStation(_ station: StationSearchResult, handler: @escaping (MKCoordinateRegion?) -> Void) {
        let coordinate = CoordinateConverter.katecToWGS84(x: station.katecX, y: station.katecY)
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        handler(region)
    }
}
