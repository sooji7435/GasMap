import GoogleMobileAds
import SwiftUI
import UIKit

struct BannerAdView: UIViewRepresentable {
    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/2934735716"
    #else
    private let adUnitID = "ca-app-pub-5540110923255806/1834357811"
    #endif

    func makeUIView(context: Context) -> BannerView {
        let adSize = largeAnchoredAdaptiveBanner(
            width: UIScreen.main.bounds.width - 32
        )
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
