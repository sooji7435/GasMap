import Foundation
import SwiftUI
import Combine
import CoreLocation
import MapKit
import WidgetKit

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
    @Published var favoriteStations: [GasStation] = []
    @Published var selectedBrands: Set<String> = []
    @Published var sortOrder: SortOrder = .price
    @Published var manualRadius: Int? = nil
    @Published var fuelRecords: [FuelRecord] = []
    @Published var searchHistory: [SearchRecord] = []

    enum SortOrder { case price, distance }

    @AppStorage("priceOffset") private var priceOffset: Int = 30

    enum Tab { case map, ranking, favorites, fuelLog }
    
    private enum RadiusConfig {
        static let multiplier: Double = 100
        static let minimum: Int = 2
        static let maximum: Int = 50
    }

    private enum StorageKey {
        static let selectedFuelType = "selectedFuelType"
        static let selectedBrands = "selectedBrands"
        static let favoriteStations = "favoriteStations"
        static let fuelRecords = "fuelRecords"
        static let searchHistory = "searchHistory"
        static let lastLat = "lastLat"
        static let lastLon = "lastLon"
        static let lastSpanLat = "lastSpanLat"
        static let lastSpanLon = "lastSpanLon"
    }

    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private let apiService = OpinetService()
    private let completer = MKLocalSearchCompleter()
    private var fetchTask: Task<Void, Never>?
    private var lastFetchCenter: CLLocationCoordinate2D?
    private var lastFetchRadius: Int = 0
    
    override init() {
        let savedRaw = UserDefaults.standard.string(forKey: StorageKey.selectedFuelType) ?? FuelType.gasoline.rawValue
        self.selectedFuelType = FuelType(rawValue: savedRaw) ?? .gasoline
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        loadFavorites()
        loadSelectedBrands()
        loadFuelRecords()
        loadSearchHistory()
    }

    var filteredStations: [GasStation] {
        guard !selectedBrands.isEmpty else { return stations }
        let mainBrands: Set<String> = ["SKE", "GSC", "HDO", "SOL"]
        return stations.filter { station in
            if selectedBrands.contains(station.brand) { return true }
            if selectedBrands.contains("OTHER") && !mainBrands.contains(station.brand) { return true }
            return false
        }
    }

    var sortedStations: [GasStation] {
        switch sortOrder {
        case .price:
            return filteredStations.sorted {
                if $0.price == $1.price { return $0.distance < $1.distance }
                return $0.price < $1.price
            }
        case .distance:
            return filteredStations.sorted { $0.distance < $1.distance }
        }
    }

    var cheapestPrice: String {
        guard let min = filteredStations.min(by: { $0.price < $1.price }) else { return "-" }
        return min.formattedPrice
    }

    var averagePriceValue: Double {
        guard !filteredStations.isEmpty else { return 0 }
        let total = filteredStations.map(\.price).reduce(0, +)
        return Double(total) / Double(filteredStations.count)
    }

    var averagePrice: String {
        guard averagePriceValue > 0 else { return "-" }
        return (Self.priceFormatter.string(from: NSNumber(value: averagePriceValue)) ?? "\(Int(averagePriceValue))") + "원"
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
                self.saveWidgetData()
                self.saveFavoritesWidgetData()
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func selectStation(_ station: GasStation) {
        HapticManager.impact(.light)
        withAnimation(.spring(response: 0.3)) {
            selectedStation = selectedStation?.id == station.id ? nil : station
        }
    }

    func changeFuelType(_ type: FuelType, coordinate: CLLocationCoordinate2D) {
        HapticManager.selection()
        selectedFuelType = type
        UserDefaults.standard.set(type.rawValue, forKey: StorageKey.selectedFuelType)
        loadStations(coordinate: coordinate)
    }
    
    func setManualRadius(_ km: Int?) {
        manualRadius = km
        if let center = lastFetchCenter {
            lastFetchCenter = nil  // 강제 재로드
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            updateStations(in: region)
        }
    }

    func updateStations(in region: MKCoordinateRegion) {
        let radius = manualRadius ?? calculateRadius(from: region.span.latitudeDelta)

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
        searchRadius = radius
        saveLastRegion(region)
        loadStations(coordinate: region.center, radius: radius)
    }

    func saveLastRegion(_ region: MKCoordinateRegion) {
        UserDefaults.standard.set(region.center.latitude,  forKey: StorageKey.lastLat)
        UserDefaults.standard.set(region.center.longitude, forKey: StorageKey.lastLon)
        UserDefaults.standard.set(region.span.latitudeDelta,  forKey: StorageKey.lastSpanLat)
        UserDefaults.standard.set(region.span.longitudeDelta, forKey: StorageKey.lastSpanLon)
    }

    func loadLastRegion() -> MKCoordinateRegion? {
        let lat = UserDefaults.standard.double(forKey: StorageKey.lastLat)
        let lon = UserDefaults.standard.double(forKey: StorageKey.lastLon)
        guard lat != 0, lon != 0 else { return nil }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(
                latitudeDelta:  UserDefaults.standard.double(forKey: StorageKey.lastSpanLat),
                longitudeDelta: UserDefaults.standard.double(forKey: StorageKey.lastSpanLon)
            )
        )
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
            let coord = item.placemark.coordinate
            let region = MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            DispatchQueue.main.async {
                self.addSearchHistory(name: completion.title, subtitle: completion.subtitle,
                                      lat: coord.latitude, lon: coord.longitude)
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

    // MARK: - Search History
    func addSearchHistory(name: String, subtitle: String, lat: Double, lon: Double) {
        searchHistory.removeAll { $0.name == name }
        searchHistory.insert(SearchRecord(id: UUID(), name: name, subtitle: subtitle, lat: lat, lon: lon, date: Date()), at: 0)
        if searchHistory.count > 10 { searchHistory = Array(searchHistory.prefix(10)) }
        saveSearchHistory()
    }

    func removeSearchHistory(id: UUID) {
        searchHistory.removeAll { $0.id == id }
        saveSearchHistory()
    }

    func clearSearchHistory() {
        searchHistory = []
        UserDefaults.standard.removeObject(forKey: StorageKey.searchHistory)
    }

    private func loadSearchHistory() {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.searchHistory),
              let decoded = try? JSONDecoder().decode([SearchRecord].self, from: data) else { return }
        searchHistory = decoded
    }

    private func saveSearchHistory() {
        if let encoded = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(encoded, forKey: StorageKey.searchHistory)
        }
    }

    // MARK: - Widget Data
    private struct WidgetStationData: Codable {
        let name: String
        let price: Int
        let brand: String
        let distance: String
    }

    private func saveWidgetData() {
        let top3 = sortedStations.prefix(3).map {
            WidgetStationData(name: $0.name, price: $0.price, brand: $0.brand, distance: $0.formattedDistance)
        }
        if let defaults = UserDefaults(suiteName: "group.me.younsu.park.GasMap"),
           let encoded = try? JSONEncoder().encode(top3) {
            defaults.set(encoded, forKey: "widgetStations")
            defaults.set(Date(), forKey: "widgetUpdatedAt")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Brand Filter
    func toggleBrand(_ code: String) {
        if selectedBrands.contains(code) {
            selectedBrands.remove(code)
        } else {
            selectedBrands.insert(code)
        }
        UserDefaults.standard.set(Array(selectedBrands), forKey: StorageKey.selectedBrands)
    }

    func clearBrandFilter() {
        selectedBrands = []
        UserDefaults.standard.removeObject(forKey: StorageKey.selectedBrands)
    }

    private func loadSelectedBrands() {
        let saved = UserDefaults.standard.stringArray(forKey: StorageKey.selectedBrands) ?? []
        selectedBrands = Set(saved)
    }

    // MARK: - Favorites
    func toggleFavorite(_ station: GasStation) {
        if let index = favoriteStations.firstIndex(where: { $0.id == station.id }) {
            favoriteStations.remove(at: index)
            HapticManager.impact(.light)
        } else {
            favoriteStations.append(station)
            HapticManager.success()
        }
        saveFavorites()
    }

    func isFavorite(_ station: GasStation) -> Bool {
        favoriteStations.contains(where: { $0.id == station.id })
    }

    func currentData(for favorite: GasStation) -> GasStation {
        stations.first(where: { $0.id == favorite.id }) ?? favorite
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.favoriteStations),
              let decoded = try? JSONDecoder().decode([GasStation].self, from: data) else { return }
        favoriteStations = decoded
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteStations) {
            UserDefaults.standard.set(encoded, forKey: StorageKey.favoriteStations)
        }
        saveFavoritesWidgetData()
    }

    private func saveFavoritesWidgetData() {
        let data = favoriteStations.map {
            let s = currentData(for: $0)
            return WidgetStationData(name: s.name, price: s.price, brand: s.brand, distance: s.formattedDistance)
        }
        if let defaults = UserDefaults(suiteName: "group.me.younsu.park.GasMap"),
           let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: "widgetFavorites")
            defaults.set(Date(), forKey: "widgetFavoritesUpdatedAt")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "GasMapFavoritesWidget")
    }

    // MARK: - Fuel Records
    func addFuelRecord(station: GasStation, liters: Double) {
        let record = FuelRecord(
            id: UUID(),
            date: Date(),
            stationID: station.id,
            stationName: station.name,
            pricePerLiter: station.price,
            liters: liters
        )
        fuelRecords.insert(record, at: 0)
        saveFuelRecords()
        HapticManager.success()
    }

    func deleteFuelRecord(id: UUID) {
        fuelRecords.removeAll { $0.id == id }
        saveFuelRecords()
    }

    private func loadFuelRecords() {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.fuelRecords),
              let decoded = try? JSONDecoder().decode([FuelRecord].self, from: data) else { return }
        fuelRecords = decoded
    }

    private func saveFuelRecords() {
        if let encoded = try? JSONEncoder().encode(fuelRecords) {
            UserDefaults.standard.set(encoded, forKey: StorageKey.fuelRecords)
        }
    }

    func moveToStation(_ station: StationSearchResult, handler: @escaping (MKCoordinateRegion?) -> Void) {
        let coordinate = CoordinateConverter.katecToWGS84(x: station.katecX, y: station.katecY)
        addSearchHistory(name: station.name, subtitle: station.address,
                         lat: coordinate.latitude, lon: coordinate.longitude)
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        handler(region)
    }
}
