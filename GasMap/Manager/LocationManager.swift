//
//  LocationManager.swift
//  OilMap
//
//  Created by 박윤수 on 4/17/26.
//

import Foundation
import Combine
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate, Observable {
    @Published var currentCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
    @Published var userLocation: CLLocation?
    
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
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
                print("위치 권한 승인됨")
                // 권한이 승인되면 실시간 위치 업데이트 시작
                manager.startUpdatingLocation()
            case .denied, .restricted:
                print("위치 권한 거부됨 (error 1 발생 원인)")
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            @unknown default:
                break
            }
        }
    
    //에러 처리
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 오류:", error.localizedDescription)
    }
    
}
