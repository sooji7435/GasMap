import SwiftUI

struct AddFuelRecordView: View {
    @EnvironmentObject var viewModel: GasMapViewModel
    @Environment(\.dismiss) var dismiss

    let station: GasStation
    @State private var litersText = ""

    private var liters: Double? {
        guard let v = Double(litersText), v > 0 else { return nil }
        return v
    }

    private var estimatedCost: Int? {
        guard let l = liters else { return nil }
        return Int(Double(station.price) * l)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 주유소 정보
                VStack(spacing: 4) {
                    Text(station.name)
                        .font(.headline)
                    Text("\(station.price)원/L")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                // 주유량 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("주유량")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        TextField("0.0", text: $litersText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 36, weight: .semibold))
                            .multilineTextAlignment(.trailing)
                        Text("L")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // 예상 금액
                HStack {
                    Text("결제 금액")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(estimatedCost.map { "\(NumberFormatter.localizedString(from: NSNumber(value: $0), number: .decimal))원" } ?? "-")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Spacer()

                Button {
                    if let l = liters {
                        viewModel.addFuelRecord(station: station, liters: l)
                        dismiss()
                    }
                } label: {
                    Text("기록 저장")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(liters != nil ? Color.blue : Color(.systemGray4))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(liters == nil)
            }
            .padding(.horizontal)
            .navigationTitle("주유 기록 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
            }
        }
    }
}
