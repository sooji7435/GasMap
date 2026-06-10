import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = GasMapViewModel()
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack {
            MapView()
                .environmentObject(viewModel)
                .environmentObject(locationManager)
        }
        .onAppear {
            locationManager.requestLocationPermission()
            viewModel.loadStations(coordinate: locationManager.currentCoordinate)
        }
        .onChange(of: locationManager.userLocation) { _, coord in
            if let coord = coord {
                viewModel.loadStations(coordinate: CLLocationCoordinate2D(latitude: coord.coordinate.latitude, longitude: coord.coordinate.longitude))
            }
        }
        .alert("위치 권한이 필요합니다", isPresented: $locationManager.isLocationDenied) {
            Button("확인") { exit(0) }
        } message: {
            Text("GasMap은 주변 주유소를 찾기 위해 위치 접근 권한이 필요합니다.\n설정 > 개인 정보 보호 > 위치 서비스에서 권한을 허용해 주세요.")
        }
        .alert("오류가 발생했습니다", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GasMapViewModel())
        .environmentObject(LocationManager())
}
