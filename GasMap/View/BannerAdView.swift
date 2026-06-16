import GoogleMobileAds
import SwiftUI
import UIKit

struct BannerAdView: UIViewRepresentable {
    // 테스트 광고 ID
        let adUnitID = "ca-app-pub-5540110923255806/9667683591"
        
        func makeUIView(context: Context) -> BannerView {
            let bannerView = BannerView()
            bannerView.adUnitID = adUnitID
            
            // Root ViewController 설정
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                bannerView.rootViewController = rootViewController
            }
            
            bannerView.adSize = AdSizeBanner
            return bannerView
        }
        
        func updateUIView(_ uiView: BannerView, context: Context) {
            let request = Request()
            uiView.load(request)
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


