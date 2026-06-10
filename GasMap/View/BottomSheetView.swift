import SwiftUI
import MapKit

struct BottomSheetView: View {
    @EnvironmentObject var viewModel: GasMapViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var showFilterSheet = false
    @State private var selectedDetailStation: GasStation?

    @Binding var cameraPosition: MapCameraPosition

    var body: some View {
        VStack(spacing: 5) {
            headerSection
            tabSelector

            BannerAdView()
                .frame(height: 60)
                .padding(.horizontal, 16)

            if viewModel.isLoading && viewModel.activeTab != .favorites && viewModel.activeTab != .fuelLog {
                loadingView
            } else {
                switch viewModel.activeTab {
                case .map:       stationListView
                case .ranking:   rankingView
                case .favorites: favoritesView
                case .fuelLog:   FuelLogView().environmentObject(viewModel)
                }
            }
        }
        .sheet(item: $selectedDetailStation) { station in
            StationDetailView(station: station)
                .environmentObject(viewModel)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        
        VStack(spacing: 10) {
            // Fuel type tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FuelType.allCases) { fuel in
                        FuelTabButton(
                            fuel: fuel,
                            isSelected: viewModel.selectedFuelType == fuel
                        ) {
                            viewModel.changeFuelType(fuel, coordinate: locationManager.currentCoordinate)
                        }
                    }
                                        
                    Button {
                        showFilterSheet.toggle() // 시트 띄우기
                    } label: {
                        ZStack {
                            Capsule()
                                .frame(width: 70, height: 30)
                                .foregroundStyle(viewModel.selectedBrands.isEmpty ? Color(.systemGray6) : Color.orange.opacity(0.15))
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(viewModel.selectedBrands.isEmpty ? .secondary : .orange)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                        }
                    }
                }
                .padding(16)
            }
            
            
            // Stats row
            HStack(spacing: 12) {
                    StatCard(label: "주변 주유소", value: "\(viewModel.filteredStations.count)개")
                StatCard(label: "최저가", value: viewModel.cheapestPrice, valueColor: .green)
                StatCard(label: "평균가", value: viewModel.averagePrice, valueColor: .orange)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
        .sheet(isPresented: $showFilterSheet) {
            FilterSettingsView()
                .environmentObject(viewModel)
                .presentationDetents([.height(580)])
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "주변 주유소", isActive: viewModel.activeTab == .map) {
                viewModel.activeTab = .map
            }
            TabButton(title: "최저가 랭킹", isActive: viewModel.activeTab == .ranking) {
                viewModel.activeTab = .ranking
            }
            TabButton(title: "즐겨찾기", isActive: viewModel.activeTab == .favorites, badge: viewModel.favoriteStations.isEmpty ? nil : "\(viewModel.favoriteStations.count)") {
                viewModel.activeTab = .favorites
            }
            TabButton(title: "주유 기록", isActive: viewModel.activeTab == .fuelLog, badge: viewModel.fuelRecords.isEmpty ? nil : "\(viewModel.fuelRecords.count)") {
                viewModel.activeTab = .fuelLog
            }
        }
        .padding(.horizontal, 16)
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - Station List
    private var stationListView: some View {
        VStack(spacing: 0) {
            // 정렬 토글
            HStack {
                Spacer()
                Button {
                    HapticManager.selection()
                    viewModel.sortOrder = viewModel.sortOrder == .price ? .distance : .price
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 11, weight: .semibold))
                        Text(viewModel.sortOrder == .price ? "가격순" : "거리순")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 2)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.sortedStations) { station in
                        StationRowView(station: station, isSelected: viewModel.selectedStation?.id == station.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                cameraPosition = .region(MKCoordinateRegion(center: station.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
                                viewModel.selectStation(station)
                                selectedDetailStation = station
                            }
                        Divider().padding(.leading, 62)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Ranking
    private var rankingView: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Text("내 주변 \(viewModel.searchRadius)km 최저가")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                ForEach(Array(viewModel.sortedStations.prefix(10).enumerated()), id: \.element.id) { index, station in
                    RankingRowView(station: station, rank: index + 1)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            cameraPosition = .region(MKCoordinateRegion(center: station.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
                            viewModel.selectStation(station)
                            selectedDetailStation = station
                        }
                    Divider().padding(.leading, 56)
                }
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Favorites
    private var favoritesView: some View {
        Group {
            if viewModel.favoriteStations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("즐겨찾기한 주유소가 없어요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("주유소 목록에서 하트를 눌러 추가하세요")
                        .font(.caption)
                        .foregroundColor(Color(.systemGray3))
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.favoriteStations) { favorite in
                            let station = viewModel.currentData(for: favorite)
                            StationRowView(station: station, isSelected: viewModel.selectedStation?.id == station.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    cameraPosition = .region(MKCoordinateRegion(center: station.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
                                    viewModel.selectStation(station)
                                    selectedDetailStation = station
                                }
                            Divider().padding(.leading, 62)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("주변 주유소 검색 중...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Fuel Tab Button
struct FuelTabButton: View {
    let fuel: FuelType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Capsule()
                    .frame(width: 70, height: 30)
                    .foregroundStyle(isSelected ? Color.orange.opacity(0.15) : Color(.systemGray6))
                
                Text(fuel.shortName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? .black : .secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                
                
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isActive: Bool
    var badge: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                        .foregroundColor(isActive ? .orange : .secondary)
                    if let badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                Rectangle()
                    .fill(isActive ? Color.orange : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
