//
//  OilMapApp.swift
//  OilMap
//
//  Created by 박윤수 on 4/17/26.
//

import SwiftUI
import Combine
import AppTrackingTransparency
import GoogleMobileAds

class AdManager: ObservableObject {
    static let shared = AdManager()
    @Published var isReady = false

    private init() {}

    func initialize() {
        MobileAds.shared.start { [weak self] _ in
            DispatchQueue.main.async {
                self?.isReady = true
            }
        }
    }
}

@main
struct GasMapApp: App {
    @StateObject private var adManager = AdManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(adManager)
                .onAppear {
                    requestTrackingPermission()
                }
        }
    }

    private func requestTrackingPermission() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    AdManager.shared.initialize()
                }
            }
        }
    }
}
