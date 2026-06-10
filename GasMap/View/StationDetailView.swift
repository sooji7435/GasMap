import SwiftUI
import MapKit

struct StationDetailView: View {
    @EnvironmentObject var viewModel: GasMapViewModel
    let station: GasStation
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    priceHeader
                    infoSection
                    actionButtons
                }
                .padding()
            }
            .navigationTitle(station.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.toggleFavorite(station)
                    } label: {
                        Image(systemName: viewModel.isFavorite(station) ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.isFavorite(station) ? .red : .primary)
                    }
                }
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
                Text("원/L")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var infoSection: some View {
        VStack(spacing: 0) {
            InfoRow(icon: "location", label: "거리", value: station.formattedDistance)
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

            ShareLink(item: shareText) {
                Label("공유", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .font(.system(size: 15, weight: .semibold))
            }
        }
    }

    private var shareText: String {
        "⛽ \(station.name)\n" +
        "💰 \(station.formattedPrice) / L\n" +
        "📍 \(station.formattedDistance)\n" +
        "GasMap에서 찾았어요"
    }

    private func openNavigation() {
        let placemark = MKPlacemark(coordinate: station.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = station.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
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
