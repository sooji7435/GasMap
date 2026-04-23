import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var viewModel: GasMapViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    // 카메라 위치 관리 (유저 위치 자동 추적)
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var currentSpan: Double = 0.02
    @State private var showSheet: Bool = true
    
    @AppStorage("priceOffset") private var priceOffset: Int = 30
    
    var body: some View {
        Map(position: $cameraPosition, bounds: MapCameraBounds(maximumDistance: 50000)) {
                ForEach(viewModel.stations) { station in
                        Annotation(station.name, coordinate: station.coordinate) {
                            PriceAnnotationView(
                                viewModel: viewModel,
                                station: station,
                                isSelected: viewModel.selectedStation?.id == station.id
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
            //.frame(width: .infinity, height: 600)
            // 4. 지도 컨트롤 버튼 추가 (내 위치 버튼 등)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            // 5. 유저 위치가 처음 잡혔을 때 로직 처리 (선택 사항)
            .onAppear {
                locationManager.requestLocationPermission()
                locationManager.startUpdating()
            }
            .onMapCameraChange(frequency: .continuous) { context in
                // 현재 줌 레벨 업데이트 (애니메이션용)
                currentSpan = context.region.span.latitudeDelta
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                // 2. 넓어진 범위에 맞춰 주유소 다시 불러오기
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
        }
    }


// MARK: - Price Annotation
struct PriceAnnotationView: View {
    @ObservedObject var viewModel: GasMapViewModel
    @AppStorage("priceOffset") private var priceOffset: Int = 30
    
    let station: GasStation
    let isSelected: Bool

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
            station.calculatePriceLevel(average: viewModel.averagePriceValue, offset: priceOffset)
        }

    private var priceColor: Color {
        switch currentLevel {
        case .cheap:     return Color("PriceCheap")
        case .mid:       return Color("PriceMid")
        case .expensive: return Color("PriceExpensive")
        }
    }
}
