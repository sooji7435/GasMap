import SwiftUI
import MapKit

struct BottomSheetView: View {
    @EnvironmentObject var viewModel: GasMapViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var sheetHeight: CGFloat = 280
    @State private var showFilterSheet = false
    
    @Binding var cameraPosition: MapCameraPosition
    
    @AppStorage("priceOffset") private var priceOffset: Int = 30
    
    var body: some View {
        VStack(spacing: 5) {
            // Header: 연료 탭 + 통계
            headerSection
            
            // Tab selector
            tabSelector
            
            // Content
            if viewModel.isLoading {
                loadingView
            } else {
                switch viewModel.activeTab {
                case .map:     stationListView
                case .ranking: rankingView
                }
            }
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
                                .foregroundStyle(Color(.systemGray6))
                            
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                        }
                    }
                }
                .padding(16)
            }
            
            
            // Stats row
            HStack(spacing: 12) {
                StatCard(label: "주변 주유소", value: "\(viewModel.stations.count)개")
                StatCard(label: "최저가", value: viewModel.cheapestPrice, valueColor: .green)
                StatCard(label: "평균가", value: viewModel.averagePrice, valueColor: .orange)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
        .sheet(isPresented: $showFilterSheet) {
            FilterSettingsView(offset: $priceOffset) // 설정 시트
                .presentationDetents([.height(250)])
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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.stations) { station in
                    StationRowView(
                        cameraPosition: $cameraPosition,
                        station: station,
                        isSelected: viewModel.selectedStation?.id == station.id
                    )
                    .onTapGesture {
                        viewModel.selectStation(station)
                    }
                    Divider().padding(.leading, 62)
                }
            }
            .padding(.top, 4)
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
                
                ForEach(Array(viewModel.sortedByPrice.prefix(10).enumerated()), id: \.element.id) { index, station in
                    RankingRowView(station: station, rank: index + 1)
                    Divider().padding(.leading, 56)
                }
            }
            .padding(.top, 4)
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? .orange : .secondary)
                Rectangle()
                    .fill(isActive ? Color.orange : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
