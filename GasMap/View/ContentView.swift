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
                if let coord = coord{
                    viewModel.loadStations(coordinate: CLLocationCoordinate2D(latitude: coord.coordinate.latitude, longitude: coord.coordinate.longitude))
                }
            }
        }
    
    
}

#Preview {
    ContentView()
        .environmentObject(GasMapViewModel())
        .environmentObject(LocationManager())
}
