//
//  ScheduleHeader.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

struct ScheduleHeader: View {
    
    // MARK: - Property
    let month: String
    @Binding var scheduleMode: ScheduleMode
    
    // MARK: - Constant
    enum Constants {
        static let segmentSize: CGFloat = 80
    }
    
    // MARK: - Body
    var body: some View {
        headerSwitch
    }
    
    /// 캘린더 표시 타이틀
    private var headerTitle: some View {
        Text("\(month)월 일정")
            .appFont(.title1Emphasis, color: .grey900)
    }
    
    /// 리스트 <-> 캘린더 전환 스위치
    private var headerSwitch: some View {
        Picker(selection: $scheduleMode, content: {
            Image(systemName: "calendar")
                .tag(ScheduleMode.grid)
            Image(systemName: "list.bullet")
                .tag(ScheduleMode.horizon)
        }, label: {
            Text("View Mode")
        })
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: Constants.segmentSize)
    }
}

#Preview {
    ScheduleHeader(month: "1", scheduleMode: .constant(.grid))
}
