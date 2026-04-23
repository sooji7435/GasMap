//
//  LocationManager.swift
//  OilMap
//
//  Created by 박윤수 on 4/17/26.
//

import Foundation
import Combine
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
    @Published var userLocation: CLLocation?
    
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
    }
    
    func start() {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            default:
                break
            }
        }
    
    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
            manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let coordinate = location.coordinate
        
        DispatchQueue.main.async {
            self.currentCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            self.userLocation = location
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            default:
                break
            }
        }
    
    //에러 처리
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 오류:", error.localizedDescription)
    }
    
}
