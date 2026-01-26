//
//  CalendarGridView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

/// 월별 달력 그리드 뷰
///
/// 사용자가 선택한 월(Month)에 해당하는 달력을 그리드 형태로 표시합니다.
/// 날짜를 선택하거나 월을 변경할 수 있으며, 일정이 있는 날짜는 별도로 표시됩니다.
struct CalendarGridCard: View, Equatable {
    
    // MARK: - Properties
    
    /// 현재 선택된 날짜 바인딩
    @Binding var selectedDate: Date
    
    /// 현재 표시되고 있는 월(Month) 바인딩
    @Binding var month: Date
    
    /// 현재 화면의 컬러 스킴 (라이트/다크 모드)
    @Environment(\.colorScheme) var color
    
    /// 일정이 존재하는 날짜들의 집합
    let scheduledDates: Set<Date>
    
    /// 드래그 제스처 오프셋 (현재 미사용)
    @State private var dragOffset: CGFloat = 0
    
    /// 드래그 방향 (현재 미사용)
    @State private var direction: SpldeDirection = .none
    
    /// 스와이프 방향 열거형
    private enum SpldeDirection {
        case left, right, none
    }
    
    // MARK: - Constants
    
    private enum Constants {
        /// 뷰 내부 패딩
        static let padding: CGFloat = 24
        /// 표시할 월의 범위 (전후 12개월)
        static let monthRange: Int = 12
        /// 스와이프 인식 임계값
        static let swipeThreshold: CGFloat = 50
        /// 캘린더 높이
        static let calendarHeight: CGFloat = 400
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.selectedDate == rhs.selectedDate &&
        lhs.month == rhs.month &&
        lhs.scheduledDates == rhs.scheduledDates
    }
    
    /// 캘린더 계산을 위한 캘린더 인스턴스
    private let calendar = Calendar.current
    
    /// 그리드 레이아웃 정의 (7열, 간격 16)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: DefaultSpacing.spacing16), count: 7)
    
    /// 표시할 전체 월 리스트 계산
    private var months: [Date] {
        (-Constants.monthRange...Constants.monthRange).compactMap { offset in
            calendar.date(byAdding: .month, value: offset, to: Date())
        }
    }
    
    var body: some View {
        VStack(spacing: DefaultSpacing.spacing24) {
            WeekDayHeader(columns: columns)
                .equatable()
            dateGrid
        }
        .padding(Constants.padding)
        .background {
            RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                .fill(bgColor)
                .glass()
        }
    }
    
    /// 배경 색상 (다크모드/라이트모드 대응)
    private var bgColor: Color {
        if color == .dark {
            return .grey100
        } else {
            return .white
        }
    }
    
    // MARK: - Cell
    
    /// 날짜 셀 그리드 뷰
    ///
    /// 해당 월의 모든 날짜(이전 달/다음 달의 일부 날짜 포함)를 그리드로 표시합니다.
    @ViewBuilder
    private var dateGrid: some View {
        LazyVGrid(columns: columns, spacing: DefaultSpacing.spacing8) {
            ForEach(adjustedDates, id: \.self) { date in
                // 현재 월에 포함되는 날짜인지 확인
                let isCurrentMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
                
                if isCurrentMonth {
                    currentMonthDate(date: date)
                } else {
                    // 현재 월이 아닌 날짜는 투명하게 처리 (레이아웃 유지를 위해)
                    Color.clear
                }
            }
        }
    }
    
    /// 현재 월에 해당하는 날짜 셀 렌더링
    private func currentMonthDate(date: Date) -> some View {
        DateCell(
            date: date,
            isSelected: date.isSameDay(selectedDate),
            isCurrentMonth: true,
            hasSchedule: hasSchedule(date),
            isToday: calendar.isDateInToday(date)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: DefaultConstant.animationTime)) {
                selectedDate = date
            }
        }
    }
    
    /// 일주일 날짜 표시
    private var groupedDates: [[Date]] {
        let dates = adjustedDates
        return stride(from: 0, to: dates.count, by: 7).map {
            Array(dates[$0..<min($0 + 7, dates.count)])
        }
    }
    
    /// 달력 그리드에 표시될 날짜 배열을 계산합니다.
    ///
    /// 해당 월의 1일 이전의 빈 날짜(이전 달의 날짜)와
    /// 마지막 날 이후의 빈 날짜(다음 달의 날짜)를 포함하여
    /// 7일씩 떨어지는 완전한 주 단위 배열을 만듭니다.
    private var adjustedDates: [Date] {
        let datesInMonth = month.datesInMonth()
        guard let firstDate = datesInMonth.first,
              let lastDate = datesInMonth.last else { return [] }
        
        let firstWeekDay = calendar.component(.weekday, from: firstDate)
        let lastWeekDay = calendar.component(.weekday, from: lastDate)
        
        let emptyDaysBefore = (firstWeekDay - 1)
        var dates: [Date] = []
        
        for i in 0..<emptyDaysBefore {
            if let date = calendar.date(byAdding: .day, value: -(emptyDaysBefore - i), to: firstDate) {
                dates.append(date)
            }
        }
        
        dates.append(contentsOf: datesInMonth)
        
        let emptyDaysAfter = 7 - lastWeekDay
        if emptyDaysAfter > 0 {
            for i in 1...emptyDaysAfter {
                if let date = calendar.date(byAdding: .day, value: i, to: lastDate) {
                    dates.append(date)
                }
            }
        }
        
        return dates
    }
    
    /// 특정 날짜에 일정이 있는지 확인합니다.
    private func hasSchedule(_ date: Date) -> Bool {
        scheduledDates.contains(where: { $0.isSameDay(date) })
    }
}

extension CalendarGridCard {
    /// 요일 헤더 뷰 (일, 월, 화, 수, 목, 금, 토)
    fileprivate struct WeekDayHeader: View, Equatable {
        let columns: [GridItem]
        private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
        
        var body: some View {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .appFont(.footnote, color: .grey400)
                }
            }
            
        }
    }
}
