//
//  DateTimeRow.swift
//  AppProduct
//
//  Created by euijjang97 on 1/23/26.
//

import SwiftUI

/// 날짜와 시간을 선택할 수 있는 행 컴포넌트
struct DateTimeRow: View, Equatable {
    // MARK: - Properties
    /// 행의 제목 (예: 시작, 종료)
    let title: String
    /// 표시할 날짜 및 시간 데이터
    let date: Date
    /// 하루 종일 여부 (시간 표시 여부 결정)
    let isAllDay: Bool
    /// 날짜 선택기가 활성화되어 있는지 여부 (텍스트 색상 변경)
    let isDatePickerActive: Bool
    /// 시간 선택기가 활성화되어 있는지 여부 (텍스트 색상 변경)
    let isTimePickerActive: Bool
    /// 날짜 버튼 탭 액션
    let dateTap: () -> Void
    /// 시간 버튼 탭 액션
    let timeTap: () -> Void
    
    // MARK: - Constant
    /// 상수 모음
    private enum Constant {
        /// 버튼 내부 패딩
        static let padding: EdgeInsets = .init(top: 6, leading: 12, bottom: 6, trailing: 12)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.title == rhs.title &&
        lhs.date == rhs.date &&
        lhs.isAllDay == rhs.isAllDay &&
        lhs.isDatePickerActive == rhs.isDatePickerActive &&
        lhs.isTimePickerActive == rhs.isTimePickerActive
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            button(text: date.toYearMonthDay(), check: isDatePickerActive, action: dateTap)
                
            if !isAllDay {
                button(text: date.timeFormatter(), check: isTimePickerActive, action: timeTap)
            }
        }
    }
    
    /// 날짜/시간 선택 버튼 생성 메서드
    /// - Parameters:
    ///   - text: 버튼에 표시할 텍스트
    ///   - check: 활성화 상태 여부 (활성화 시 빨간색 텍스트)
    ///   - action: 버튼 탭 시 실행할 클로저
    /// - Returns: 스타일이 적용된 버튼 뷰
    private func button(text: String, check: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            Text(text)
                .appFont(.body, color: check ? .red : .black)
                .padding(Constant.padding)
                .glassEffect(.clear.interactive(), in: .capsule)
        })
        .buttonStyle(.plain)
    }
}

#Preview {
    DateTimeRow(title: "시작", date: .now, isAllDay: false, isDatePickerActive: false, isTimePickerActive: false, dateTap: { print("hello")}, timeTap: { print("hello") })
}
