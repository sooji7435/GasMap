import SwiftUI
import MapKit

// MARK: - Station Row
struct StationRowView: View {
    @Binding var cameraPosition: MapCameraPosition
    
    let station: GasStation
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(station.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(station.formattedDistance)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Price
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(station.price)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.black)
                Text("원/L")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? Color.orange.opacity(0.06) : Color.clear)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .onTapGesture {
            cameraPosition = .region(MKCoordinateRegion(center: station.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
        }
    }
    /*
    private var priceColor: Color {
        switch station.priceLevel {
        case .cheap:     return Color("PriceCheap")
        case .mid:       return Color("PriceMid")
        case .expensive: return Color("PriceExpensive")
        }
    }
     */
}

// MARK: - Ranking Row
struct RankingRowView: View {
    let station: GasStation
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 28, height: 28)
                Text("\(rank)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(rank <= 3 ? .white : .secondary)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(station.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(station.formattedDistance)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(station.formattedPrice)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(rank == 1 ? .green : (rank <= 3 ? .orange : .primary))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .green
        case 2: return .orange
        case 3: return Color(.systemYellow)
        default: return Color(.systemGray5)
        }
    }
}
