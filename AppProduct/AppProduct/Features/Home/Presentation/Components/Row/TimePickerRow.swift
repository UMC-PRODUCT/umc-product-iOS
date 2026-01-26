//
//  TimePickerRow.swift
//  AppProduct
//
//  Created by euijjang97 on 1/23/26.
//

import SwiftUI

/// 시간 선택을 위한 휠(Wheel) 스타일 피커 컴포넌트
struct TimePickerRow: View, Equatable {
    /// 선택된 시간과 연동되는 바인딩 변수
    @Binding var date: Date
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.date == rhs.date
    }
    
    var body: some View {
        DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .tint(.indigo500)
    }
}

#Preview {
    TimePickerRow(date: .constant(.now))
}
