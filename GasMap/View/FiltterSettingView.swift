//
//  FiltterSettingView.swift
//  OilMap
//
//  Created by 박윤수 on 4/17/26.
//
import SwiftUI

struct FilterSettingsView: View {
    @EnvironmentObject var viewModel: GasMapViewModel
    @AppStorage("priceOffset") private var priceOffset: Int = 30
    @Environment(\.dismiss) var dismiss

    private let brands: [(code: String, name: String)] = [
        ("SKE", "SK에너지"),
        ("GSC", "GS칼텍스"),
        ("HDO", "현대오일뱅크"),
        ("SOL", "S-OIL"),
        ("OTHER", "기타")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 가격 기준
                VStack(alignment: .leading, spacing: 10) {
                    Text("가격 기준")
                        .font(.headline)
                    Text("평균보다 \(priceOffset)원 이상 싸면 초록색")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Slider(value: Binding(
                        get: { Double(priceOffset) },
                        set: { priceOffset = Int($0) }
                    ), in: 0...500, step: 10)
                    .tint(.green)
                }
                .padding()

                Divider()

                // 브랜드 필터
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("브랜드 필터")
                            .font(.headline)
                        Spacer()
                        if !viewModel.selectedBrands.isEmpty {
                            Button("전체 해제") { viewModel.clearBrandFilter() }
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    Text(viewModel.selectedBrands.isEmpty ? "전체 브랜드 표시 중" : "선택한 브랜드만 표시")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(brands, id: \.code) { brand in
                        HStack {
                            Text(brand.name)
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: viewModel.selectedBrands.contains(brand.code) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(viewModel.selectedBrands.contains(brand.code) ? .orange : Color(.systemGray3))
                                .font(.system(size: 22))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.toggleBrand(brand.code) }
                    }
                }
                .padding()

                Divider()

                // 검색 반경
                VStack(alignment: .leading, spacing: 12) {
                    Text("검색 반경")
                        .font(.headline)
                    Text(viewModel.manualRadius == nil ? "지도 줌 레벨에 따라 자동 조정" : "\(viewModel.manualRadius!)km 고정")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach([nil, 2, 5, 10, 20], id: \.self) { km in
                            Button {
                                viewModel.setManualRadius(km)
                            } label: {
                                Text(km == nil ? "자동" : "\(km!)km")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(viewModel.manualRadius == km ? .white : .orange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(viewModel.manualRadius == km ? Color.orange : Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()

                Spacer()

                Button("완료") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .padding(.bottom)
            }
            .navigationTitle("필터 설정")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
