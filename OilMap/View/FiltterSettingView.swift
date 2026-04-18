//
//  FiltterSettingView.swift
//  OilMap
//
//  Created by 박윤수 on 4/17/26.
//
import Foundation
import SwiftUI

struct FilterSettingsView: View {
    @Binding var offset: Int
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                Text("나의 가격 기준 설정")
                    .font(.headline)
                
                VStack {
                    Text("평균보다 \(offset)원 이상 싸면 초록색")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Slider(value: Binding(
                        get: { Double(offset) },
                        set: { offset = Int($0) }
                    ), in: 0...100, step: 5)
                    .tint(.green)
                }
                .padding(.horizontal)
                
                Button("완료") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

