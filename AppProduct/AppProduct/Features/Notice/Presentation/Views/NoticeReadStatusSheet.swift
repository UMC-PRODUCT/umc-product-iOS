//
//  NoticeReadStatusSheet.swift
//  AppProduct
//
//  Created by 이예지 on 2/3/26.
//

import SwiftUI

struct NoticeReadStatusSheet: View {
    
    // MARK: - Property
    @Bindable var viewModel: NoticeDetailViewModel
    private let model: NoticeReadStatus
    
    // MARK: - Constant
    
    // MARK: - Body
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
    
    // 상단 세그먼트(미확인/확인)
    private var segmentedSection: some View {
        Picker("", selection: $viewModel.selectedReadTab) {
            Text("미확인 \(model.unconfirmedCount)")
                .tag(ReadStatusTab.unconfirmed)
            
            Text("확인 \(model.confirmedCount)")
                .tag(ReadStatusTab.confirmed)
        }
        .pickerStyle(.segmented)
    }
    
    // 하단 버튼(알림 보내기)
    private var buttonSection: some View {
        Button(action: {
            
        }, label: {
            Label("재알림 보내기", systemImage: "arrow.trianglehead.clockwise")
                //.symbolEffect(.rotate, value: <#T##Equatable#>)
        })
    }
}

// MARK: - Preview
//#Preview {
//    NoticeReadStatusSheet()
//}
