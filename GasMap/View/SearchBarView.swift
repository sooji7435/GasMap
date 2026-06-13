//
//  SearchBarView.swift
//  GasMap
//
//  Created by 박윤수 on 4/23/26.
//

import SwiftUI
import MapKit

struct SearchBarView: View {
    @EnvironmentObject var viewModel: GasMapViewModel
    @Binding var cameraPosition: MapCameraPosition

    @State private var searchText = ""
    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    private var hasResults: Bool {
        !viewModel.searchCompletions.isEmpty || !viewModel.stationSearchResults.isEmpty
    }

    private var showHistory: Bool {
        isFocused && searchText.isEmpty && !viewModel.searchHistory.isEmpty
    }

    private var showDropdown: Bool {
        (isEditing && hasResults) || showHistory
    }

    var body: some View {
        VStack(spacing: 0) {
            // 검색창
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .frame(width: 16)

                TextField("장소 또는 주유소 검색", text: $searchText)
                    .focused($isFocused)
                    .onChange(of: searchText) { _, newValue in
                        if newValue.isEmpty {
                            viewModel.searchCompletions = []
                            viewModel.stationSearchResults = []
                            isEditing = false
                        } else {
                            isEditing = true
                            viewModel.updateCompleter(query: newValue)
                            viewModel.searchStationsByName(query: newValue)
                        }
                    }

                if !searchText.isEmpty {
                    Button { clearSearch() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: showDropdown ? 0 : 12,
                    bottomTrailingRadius: showDropdown ? 0 : 12,
                    topTrailingRadius: 12
                )
            )

            // 검색 결과 / 검색 기록
            if showHistory {
                historySection
            } else if isEditing && hasResults {
                searchResultsSection
            }
        }
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
    }

    private func clearSearch(keepText: Bool = false) {
        if !keepText { searchText = "" }
        viewModel.searchCompletions = []
        viewModel.stationSearchResults = []
        isEditing = false
        isFocused = false
    }

    // MARK: - 검색 기록

    private var historySection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("최근 검색")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button("전체 삭제") { viewModel.clearSearchHistory() }
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 2)

            ForEach(viewModel.searchHistory.prefix(5)) { record in
                Button {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: .init(latitude: record.lat, longitude: record.lon),
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                    searchText = record.name
                    clearSearch(keepText: true)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            if !record.subtitle.isEmpty {
                                Text(record.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Button {
                            viewModel.removeSearchHistory(id: record.id)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11))
                                .foregroundColor(Color(.systemGray3))
                                .frame(width: 28, height: 28)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }

                if record.id != viewModel.searchHistory.prefix(5).last?.id {
                    Divider().padding(.leading, 38)
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 12,
                topTrailingRadius: 0
            )
        )
    }

    // MARK: - 검색 결과

    private var searchResultsSection: some View {
        VStack(spacing: 0) {
            // 주유소 검색 결과
            if !viewModel.stationSearchResults.isEmpty {
                HStack {
                    Text("주유소")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 2)

                ForEach(Array(viewModel.stationSearchResults.prefix(3).enumerated()), id: \.offset) { index, station in
                    Button {
                        viewModel.moveToStation(station) { region in
                            if let region { cameraPosition = .region(region) }
                        }
                        searchText = station.name
                        clearSearch(keepText: true)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "fuelpump.fill")
                                .foregroundColor(.orange)
                                .frame(width: 16)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(station.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text(station.address)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }

                    if index < min(viewModel.stationSearchResults.count, 3) - 1 {
                        Divider().padding(.leading, 38)
                    }
                }
            }

            // 장소 자동완성 결과
            if !viewModel.searchCompletions.isEmpty {
                if !viewModel.stationSearchResults.isEmpty {
                    Divider().padding(.leading, 12)
                }

                HStack {
                    Text("장소")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 2)

                ForEach(Array(viewModel.searchCompletions.prefix(3).enumerated()), id: \.offset) { index, completion in
                    Button {
                        viewModel.searchLocation(completion: completion) { region in
                            if let region { cameraPosition = .region(region) }
                        }
                        searchText = completion.title
                        clearSearch(keepText: true)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.blue)
                                .frame(width: 16)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(completion.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                if !completion.subtitle.isEmpty {
                                    Text(completion.subtitle)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }

                    if index < min(viewModel.searchCompletions.count, 3) - 1 {
                        Divider().padding(.leading, 38)
                    }
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 12,
                topTrailingRadius: 0
            )
        )
    }
}
