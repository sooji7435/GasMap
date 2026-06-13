//
//  OilMapApp.swift
//  OilMap
//
//  Created by 박윤수 on 4/17/26.
//

import SwiftUI
import AppTrackingTransparency
import GoogleMobileAds

@main
struct GasMapApp: App {
    init() {
        MobileAds.shared.start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestTrackingPermission()
                }
        }
    }

    private func requestTrackingPermission() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
