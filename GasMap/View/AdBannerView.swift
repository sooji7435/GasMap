import GoogleMobileAds
import SwiftUI

struct AdBannerView: UIViewRepresentable {
    let adUnitID = "ca-app-pub-5540110923255806/6791380457"

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView()
        bannerView.adUnitID = adUnitID

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.keyWindow?.rootViewController {
            bannerView.rootViewController = rootViewController
        }

        bannerView.adSize = AdSizeBanner

        if AppDelegate.isMobileAdsReady {
            bannerView.load(Request())
        } else {
            NotificationCenter.default.addObserver(forName: .mobileAdsReady, object: nil, queue: .main) { [weak bannerView] _ in
                bannerView?.load(Request())
            }
        }

        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

struct BannerAd: View {
    var body: some View {
        AdBannerView()
            .frame(width: 320, height: 50)
    }
}

#Preview {
    AdBannerView()
}
