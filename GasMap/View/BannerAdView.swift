import GoogleMobileAds
import SwiftUI
import UIKit

struct BannerAdView: UIViewRepresentable {
    private let adUnitID = "ca-app-pub-5540110923255806/1834357811"

    func makeUIView(context: Context) -> BannerView {
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first
        let screenWidth = windowScene?.windows.first?.bounds.width ?? 390
        let banner = BannerView(adSize: largeAnchoredAdaptiveBanner(width: screenWidth - 32))
        banner.adUnitID = adUnitID
        banner.rootViewController = windowScene?.windows.first?.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
