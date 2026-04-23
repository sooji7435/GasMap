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
    
    // 결과가 하나라도 있는지
    private var hasResults: Bool {
        !viewModel.searchCompletions.isEmpty || !viewModel.stationSearchResults.isEmpty
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
                            viewModel.updateCompleter(query: newValue)        // 장소 자동완성
                            viewModel.searchStationsByName(query: newValue)   // 주유소명 검색
                        }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        viewModel.searchCompletions = []
                        viewModel.stationSearchResults = []
                        isEditing = false
                        isFocused = false
                    } label: {
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
                    bottomLeadingRadius: isEditing && hasResults ? 0 : 12,
                    bottomTrailingRadius: isEditing && hasResults ? 0 : 12,
                    topTrailingRadius: 12
                )
            )
            
            // 검색 결과 목록
            if isEditing && hasResults {
                VStack(spacing: 0) {
                    
                    // MARK: 주유소 검색 결과
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
                                viewModel.stationSearchResults = []
                                viewModel.searchCompletions = []
                                isEditing = false
                                isFocused = false
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
                    
                    // MARK: 장소 자동완성 결과
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
                                viewModel.searchCompletions = []
                                viewModel.stationSearchResults = []
                                isEditing = false
                                isFocused = false
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
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
    }
}
