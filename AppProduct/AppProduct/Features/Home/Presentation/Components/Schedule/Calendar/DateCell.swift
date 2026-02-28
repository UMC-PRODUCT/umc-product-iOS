//
//  DateCell.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

/// 캘린더 그리드 뷰에서 개별 날짜를 표시하는 셀 뷰
///
/// 날짜, 선택 상태, 일정 유무, 오늘 날짜 여부 등을 시각적으로 표현합니다.
struct DateCell: View {
    // MARK: - Properties
    
    /// 표시할 날짜
    let date: Date
    /// 선택 여부
    let isSelected: Bool
    /// 현재 표시 중인 월에 포함되는지 여부 (이전/다음 달 날짜 구분)
    let isCurrentMonth: Bool
    /// 해당 날짜에 일정이 있는지 여부
    let hasSchedule: Bool
    /// 오늘 날짜인지 여부
    let isToday: Bool

    // MARK: - Constants
    
    enum Constants {
        /// 셀 크기 (정사각형)
        static let cellSize: CGFloat = 40
        /// 일정 표시 점 크기
        static let circleSize: CGFloat = 6
        /// 오늘 날짜 테두리 두께
        static let todayBorderWidth: CGFloat = 2
    }
    
    /// 날짜 문자열 반환 (예: "1", "15")
    private var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: DefaultSpacing.spacing4, content: {
            // 날짜 텍스트
            Text(day)
                .appFont(.callout, color: textColor)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.cellSize)
                .padding(Constants.todayBorderWidth)
                .background {
                    // 선택 시 배경 원 표시
                    if isSelected {
                        Color.indigo500.glassEffect(.regular.interactive(), in: .circle)
                    } else {
                        Color.clear
                    }
                }
                .clipShape(Circle())
                .overlay {
                    // 오늘 날짜이고 선택되지 않았을 때 테두리 표시
                    if isToday && !isSelected {
                        Circle()
                            .strokeBorder(Color.indigo500, lineWidth: Constants.todayBorderWidth)
                    }
                }

            // 일정 유무 표시 점
            Circle()
                .fill(hasSchedule ? pointColor : .clear)
                .frame(width: Constants.circleSize, height: Constants.circleSize)
        })
        // 현재 월이 아닐 경우 흐리게 표시
        .opacity(isCurrentMonth ? 1.0 : 0.3)
    }
    
    /// 날짜 텍스트 색상
    private var textColor: Color {
        isSelected ? .white : .grey900
    }
    
    /// 배경 색상 (현재 미사용, body 내에서 직접 지정 중)
    private var backgroundColor: Color {
        isSelected ? .indigo500 : .clear
    }
    
    /// 일정 표시 점 색상
    private var pointColor: Color {
        isSelected ? .white : .red500
    }
}

#Preview {
    HStack {
        DateCell(date: .now, isSelected: true, isCurrentMonth: true, hasSchedule: false, isToday: true)
        DateCell(date: .now, isSelected: false, isCurrentMonth: true, hasSchedule: false, isToday: true)
        DateCell(date: .now, isSelected: false, isCurrentMonth: true, hasSchedule: true, isToday: false)
    }
}
