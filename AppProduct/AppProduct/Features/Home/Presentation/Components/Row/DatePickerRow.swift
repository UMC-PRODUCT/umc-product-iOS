//
//  DatePickerRow.swift
//  AppProduct
//
//  Created by euijjang97 on 1/23/26.
//

import SwiftUI

/// 날짜 선택을 위한 달력(Graphical) 뷰 컴포넌트
struct DatePickerRow: View, Equatable {
    /// 선택된 날짜와 연동되는 바인딩 변수
    @Binding var date: Date
    /// 선택 가능한 날짜 범위
    var range: ClosedRange<Date>?
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.date == rhs.date
        && lhs.range?.lowerBound == rhs.range?.lowerBound
        && lhs.range?.upperBound == rhs.range?.upperBound
    }
    
    var body: some View {
        if let range {
            DatePicker("", selection: $date, in: range, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(.indigo500)
        } else {
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(.indigo500)
        }
    }
}

#Preview {
    DatePickerRow(date: .constant(.now), range: nil)
}
