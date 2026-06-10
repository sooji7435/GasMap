import SwiftUI

struct FuelLogView: View {
    @EnvironmentObject var viewModel: GasMapViewModel

    private var thisMonthRecords: [FuelRecord] {
        let cal = Calendar.current
        let now = Date()
        return viewModel.fuelRecords.filter { cal.isDate($0.date, equalTo: now, toGranularity: .month) }
    }

    private var monthlyLiters: Double { thisMonthRecords.reduce(0) { $0 + $1.liters } }
    private var monthlyCost: Int     { thisMonthRecords.reduce(0) { $0 + $1.totalCost } }

    var body: some View {
        Group {
            if viewModel.fuelRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "fuelpump.slash")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("주유 기록이 없어요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("주유소 상세 화면에서 기록을 추가하세요")
                        .font(.caption)
                        .foregroundColor(Color(.systemGray3))
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // 이번 달 요약
                        HStack(spacing: 12) {
                            StatCard(label: "이번 달 횟수", value: "\(thisMonthRecords.count)회")
                            StatCard(label: "총 주유량", value: String(format: "%.1fL", monthlyLiters), valueColor: .blue)
                            StatCard(label: "총 지출", value: formatCost(monthlyCost), valueColor: .orange)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                        Divider()

                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.fuelRecords) { record in
                                FuelRecordRow(record: record)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            viewModel.deleteFuelRecord(id: record.id)
                                        } label: {
                                            Label("삭제", systemImage: "trash")
                                        }
                                    }
                                Divider().padding(.leading, 16)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private func formatCost(_ cost: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return (f.string(from: NSNumber(value: cost)) ?? "\(cost)") + "원"
    }
}

struct FuelRecordRow: View {
    let record: FuelRecord

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(record.stationName)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                Text(record.formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(record.formattedTotal)
                    .font(.system(size: 15, weight: .semibold))
                Text("\(record.pricePerLiter)원 × \(record.formattedLiters)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
