import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var viewModel: GasMapViewModel
    @EnvironmentObject var locationManager: LocationManager

    @State private var cameraPosition: MapCameraPosition = {
        let lat = UserDefaults.standard.double(forKey: "lastLat")
        let lon = UserDefaults.standard.double(forKey: "lastLon")
        guard lat != 0, lon != 0 else { return .userLocation(fallback: .automatic) }
        let span = MKCoordinateSpan(
            latitudeDelta:  UserDefaults.standard.double(forKey: "lastSpanLat"),
            longitudeDelta: UserDefaults.standard.double(forKey: "lastSpanLon")
        )
        return .region(MKCoordinateRegion(center: .init(latitude: lat, longitude: lon), span: span))
    }()
    @State private var currentSpan: Double = 0.02
    @State private var selectedDetailStation: GasStation?

    // 커스텀 바텀시트 상태
    @State private var sheetHeight: CGFloat = 180
    @State private var baseSheetHeight: CGFloat = 180

    private var snapHeights: [CGFloat] {
        let h = UIScreen.main.bounds.height
        return [180, h * 0.5, h * 0.85]
    }

    @AppStorage("priceOffset") private var priceOffset: Int = 30

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: 지도
            Map(position: $cameraPosition, bounds: MapCameraBounds(maximumDistance: 50000)) {
                ForEach(viewModel.filteredStations) { station in
                    Annotation(station.name, coordinate: station.coordinate) {
                        PriceAnnotationView(
                            station: station,
                            isSelected: viewModel.selectedStation?.id == station.id,
                            averagePrice: viewModel.averagePriceValue
                        )
                        .scaleEffect(viewModel.calculateScale(span: currentSpan))
                        .animation(.easeOut(duration: 0.2), value: currentSpan)
                        .onTapGesture {
                            viewModel.selectStation(station)
                            selectedDetailStation = station
                        }
                    }
                }
                UserAnnotation()
            }
            .ignoresSafeArea()
            .onChange(of: locationManager.currentCoordinate.latitude) { _, _ in
                guard let location = locationManager.userLocation else { return }
                if viewModel.stations.isEmpty {
                    let region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                    viewModel.updateStations(in: region)
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                currentSpan = context.region.span.latitudeDelta
                viewModel.updateStations(in: context.region)
            }
            .mapControls { MapCompass() }

            // MARK: 검색바
            VStack {
                SearchBarView(cameraPosition: $cameraPosition)
                    .environmentObject(viewModel)
                    .padding(.top)
                    .padding(.horizontal, 16)
                Spacer()
            }

            // MARK: 위치 버튼
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
                .padding(.bottom, sheetHeight + 80)
            }

            // MARK: 바텀시트
            BottomSheetView(cameraPosition: $cameraPosition)
                .environmentObject(viewModel)
                .environmentObject(locationManager)
                .frame(maxWidth: .infinity)
                .frame(height: sheetHeight)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 16,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 16
                    )
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
                )
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            let proposed = baseSheetHeight - value.translation.height
                            sheetHeight = max(120, min(UIScreen.main.bounds.height * 0.85, proposed))
                        }
                        .onEnded { _ in
                            let snap = snapHeights.min(by: { abs($0 - sheetHeight) < abs($1 - sheetHeight) })!
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                sheetHeight = snap
                            }
                            baseSheetHeight = snap
                        }
                )
        }
        // 배너 — ZStack과 완전히 독립, 항상 하단에 고정
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BannerAdView()
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
        }
        .sheet(item: $selectedDetailStation) { station in
            StationDetailView(station: station)
                .environmentObject(viewModel)
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
