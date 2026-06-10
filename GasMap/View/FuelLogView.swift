import SwiftUI

struct FuelLogView: View {
    @EnvironmentObject var viewModel: GasMapViewModel
    @State private var selectedMonth: Date = Calendar.current.startOfMonth(for: Date())

    private var cal: Calendar { Calendar.current }

    private var monthRecords: [FuelRecord] {
        viewModel.fuelRecords.filter { cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }

    private var totalRecords: [FuelRecord] { viewModel.fuelRecords }

    private var monthLiters: Double  { monthRecords.reduce(0) { $0 + $1.liters } }
    private var monthCost: Int       { monthRecords.reduce(0) { $0 + $1.totalCost } }
    private var monthAvgPrice: Int   { monthLiters > 0 ? Int(Double(monthCost) / monthLiters) : 0 }

    private var totalLiters: Double  { totalRecords.reduce(0) { $0 + $1.liters } }
    private var totalCost: Int       { totalRecords.reduce(0) { $0 + $1.totalCost } }

    private var canGoNext: Bool {
        cal.compare(selectedMonth, to: cal.startOfMonth(for: Date()), toGranularity: .month) == .orderedAscending
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy년 M월"
        return f.string(from: selectedMonth)
    }

    var body: some View {
        Group {
            if viewModel.fuelRecords.isEmpty {
                emptyView
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        monthNavigator
                        Divider()
                        monthStats
                        Divider()
                        if monthRecords.isEmpty {
                            Text("이 달의 주유 기록이 없어요")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(32)
                        } else {
                            recordList
                        }
                        totalSummary
                    }
                }
            }
        }
    }

    // MARK: - Empty
    private var emptyView: some View {
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
    }

    // MARK: - Month Navigator
    private var monthNavigator: some View {
        HStack {
            Button {
                selectedMonth = cal.date(byAdding: .month, value: -1, to: selectedMonth)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
                    .frame(width: 32, height: 32)
            }

            Spacer()
            Text(monthTitle)
                .font(.system(size: 15, weight: .semibold))
            Spacer()

            Button {
                if canGoNext {
                    selectedMonth = cal.date(byAdding: .month, value: 1, to: selectedMonth)!
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(canGoNext ? .orange : Color(.systemGray4))
                    .frame(width: 32, height: 32)
            }
            .disabled(!canGoNext)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Month Stats
    private var monthStats: some View {
        HStack(spacing: 8) {
            StatCard(label: "횟수",    value: "\(monthRecords.count)회")
            StatCard(label: "주유량",  value: String(format: "%.1fL", monthLiters), valueColor: .blue)
            StatCard(label: "지출",    value: formatCost(monthCost), valueColor: .orange)
            StatCard(label: "평균단가", value: monthAvgPrice > 0 ? "\(monthAvgPrice)원" : "-", valueColor: .green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Record List
    private var recordList: some View {
        LazyVStack(spacing: 0) {
            ForEach(monthRecords) { record in
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
    }

    // MARK: - Total Summary
    private var totalSummary: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text("전체 누적")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(totalRecords.count)회 · \(String(format: "%.1fL", totalLiters)) · \(formatCost(totalCost))")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func formatCost(_ cost: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return (f.string(from: NSNumber(value: cost)) ?? "\(cost)") + "원"
    }
}

// MARK: - Fuel Record Row
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

// MARK: - Calendar Extension
private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let c = dateComponents([.year, .month], from: date)
        return self.date(from: c) ?? date
    }
}
