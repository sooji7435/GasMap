import SwiftUI
import MapKit

struct StationDetailView: View {
    let station: GasStation
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Price header
                    priceHeader

                    // Info cards
                    infoSection

                    // Action buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle(station.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private var priceHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(Brand.color(station.brand)))
                    .frame(width: 56, height: 56)
                Text(Brand.shortName(station.brand))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(Brand.displayName(station.brand))
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(station.formattedPrice)
                    .font(.system(size: 40, weight: .bold))
                    //.foregroundColor(priceColor)
                Text("원/L")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            /*
            Text(station.priceLevel.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(priceColor)
                .cornerRadius(10)
             */
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var infoSection: some View {
        VStack(spacing: 0) {
            //InfoRow(icon: "mappin", label: "주소", value: station.address)
            Divider().padding(.leading, 40)
            InfoRow(icon: "location", label: "거리", value: station.formattedDistance)
            Divider().padding(.leading, 40)
            /*
            if !station.tel!.isEmpty {
                InfoRow(icon: "phone", label: "전화", value: station.tel)
            }
             */
        }
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                openNavigation()
            } label: {
                Label("길찾기", systemImage: "map.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.system(size: 15, weight: .semibold))
            }

            /*
            if !station.tel.isEmpty {
                Button {
                    callStation()
                } label: {
                    Label("전화", systemImage: "phone.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
             */
        }
    }
    /*
    private var priceColor: Color {
        switch station. {
        case .cheap:     return Color("PriceCheap")
        case .mid:       return Color("PriceMid")
        case .expensive: return Color("PriceExpensive")
        }
    }
     */

    private func openNavigation() {
        let placemark = MKPlacemark(coordinate: station.coordinate)
        
        let item = MKMapItem(placemark: placemark)
        item.name = station.name
        
        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        
        item.openInMaps(launchOptions: launchOptions)
    }
    /*
    private func callStation() {
        let cleaned = station.tel.replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
     */
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
