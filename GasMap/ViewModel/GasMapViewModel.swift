import Foundation
import SwiftUI
import CoreLocation
import Combine
import MapKit

@MainActor
class GasMapViewModel: ObservableObject, Observable {
    @Published var stations: [GasStation] = []
    @Published var selectedStation: GasStation?
    @Published var selectedFuelType: FuelType = .gasoline
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var activeTab: Tab = .map
    @Published var searchRadius: Int = 5
    
    @AppStorage("priceOffset") private var priceOffset: Int = 30

    enum Tab { case map, ranking }

    private let apiService = OpinetService()
    private var cancellables = Set<AnyCancellable>()

    var sortedByPrice: [GasStation] {
        stations.sorted { $0.price < $1.price }
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
    
}
