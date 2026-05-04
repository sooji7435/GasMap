import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var viewModel: GasMapViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    // 카메라 위치 관리 (유저 위치 자동 추적)
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var currentSpan: Double = 0.02
    @State private var showSheet: Bool = true
    @State private var searchText = ""
    
    @AppStorage("priceOffset") private var priceOffset: Int = 30
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition, bounds: MapCameraBounds(maximumDistance: 50000)) {
                ForEach(viewModel.stations) { station in
                    Annotation(station.name, coordinate: station.coordinate) {
                        PriceAnnotationView(
                            station: station,
                            isSelected: viewModel.selectedStation?.id == station.id,
                            averagePrice: viewModel.averagePriceValue  // 추가
                        )
                        // 줌이 멀어질수록 크기를 더 작게 조절 (0.5배까지)
                        .scaleEffect(viewModel.calculateScale(span: currentSpan))
                        .animation(.easeOut(duration: 0.2), value: currentSpan)
                        .onTapGesture {
                            viewModel.selectStation(station)
                        }
                        
                    }
                }
                // 유저 위치 표시 (필요시 전용 마커 추가 가능, 기본은 파란 점)
                UserAnnotation()
            }
            // 유저 위치가 처음 잡혔을 때 로직 처리
            .onAppear {
                locationManager.requestLocationPermission()
                locationManager.startUpdating()
                
            }
            .onChange(of: locationManager.userLocation) { _, location in
                guard let location else { return }
                
                // 최초 1회만 실행
                if viewModel.stations.isEmpty {
                    let region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                    viewModel.updateStations(in: region)
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                // 현재 줌 레벨 업데이트 (애니메이션용)
                currentSpan = context.region.span.latitudeDelta
                
                // 넓어진 범위에 맞춰 주유소 다시 불러오기
                viewModel.updateStations(in: context.region)
            }
            .sheet(isPresented: $showSheet) {
                BottomSheetView(cameraPosition: $cameraPosition)
                    .environmentObject(viewModel)
                    .environmentObject(locationManager)
                    .presentationDetents([.height(180), .medium, .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                // 드래그 핸들 표시
                    .presentationDragIndicator(.visible)
                //sheet 제거 방지
                    .interactiveDismissDisabled(true)
            }
            VStack {
                SearchBarView(cameraPosition: $cameraPosition)
                    .environmentObject(viewModel)
                    .padding(.top)
                    .padding(.horizontal, 16)
                
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        cameraPosition = .userLocation(fallback: .automatic)
                    } label: {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 4)
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 200) // sheet 위로 올라오도록
            }
        }
        .mapControls {
            MapCompass() // 나침반만 유지
        }
    }
}



// MARK: - Price Annotation
struct PriceAnnotationView: View {
    @AppStorage("priceOffset") private var priceOffset: Int = 30
    
    let station: GasStation
    let isSelected: Bool
    let averagePrice: Double
    
    var body: some View {
        VStack(spacing: 0) {
            Text(station.formattedPrice)
                .font(.system(size: isSelected ? 13 : 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(priceColor)
                .cornerRadius(10)
                .scaleEffect(isSelected ? 1.15 : 1.0)
                .shadow(color: priceColor.opacity(0.4), radius: isSelected ? 6 : 2)
        }
        .animation(.spring(response: 0.25), value: isSelected)
    }
    
    private var currentLevel: PriceLevel {
            station.calculatePriceLevel(average: averagePrice, offset: priceOffset)
        }
    
    private var priceColor: Color {
        switch currentLevel {
        case .cheap:     return Color("PriceCheap")
        case .mid:       return Color("PriceMid")
        case .expensive: return Color("PriceExpensive")
        }
    }
}
