import GoogleMobileAds
import SwiftUI
import UIKit

struct BannerAdView: UIViewRepresentable {
    private let adUnitID = "ca-app-pub-5540110923255806/6791380457"
    @EnvironmentObject var adManager: AdManager

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView()
        bannerView.adUnitID = adUnitID
        bannerView.adSize = AdSizeBanner
        bannerView.delegate = context.coordinator
        bannerView.rootViewController = rootViewController()

        if adManager.isReady {
            context.coordinator.hasLoaded = true
            bannerView.load(Request())
        }
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        guard adManager.isReady, !context.coordinator.hasLoaded else { return }
        context.coordinator.hasLoaded = true
        uiView.rootViewController = rootViewController()
        uiView.load(Request())
    }

    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    class Coordinator: NSObject, BannerViewDelegate {
        var hasLoaded = false

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("[AdMob] 광고 로드 성공")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("[AdMob] 광고 로드 실패: \(error.localizedDescription)")
        }
    }
}

struct BannerAd: View {
    var body: some View {
        BannerAdView()
            .frame(width: 320, height: 50)
            .background(Color.clear)
    }
}

#Preview {
    BannerAdView()
}
