//
//  SCheduleCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

/// 달력 리스트 및 캘린더 전환 카드
///
/// 캘린더 그리드 뷰와 가로 스크롤 뷰를 포함하며,
/// 사용자가 선택한 모드(Grid/Horizon)에 따라 적절한 캘린더를 표시합니다.
struct ScheduleCard: View, Equatable {
    // MARK: - Bindings
    
    /// 현재 선택된 날짜 바인딩
    @Binding var selectedDate: Date
    
    /// 현재 표시 중인 월 바인딩
    @Binding var currentMonth: Date

    // MARK: - State
    
    /// 일정 표시 모드 (기본값: Grid)
    @State var scheduleMode: ScheduleMode = .grid

    // MARK: - Properties
    
    /// 일정이 존재하는 날짜들의 집합
    let scheduledDates: Set<Date>

    // MARK: - Equatable
    static func == (lhs: ScheduleCard, rhs: ScheduleCard) -> Bool {
        lhs.selectedDate == rhs.selectedDate &&
        lhs.currentMonth == rhs.currentMonth &&
        lhs.scheduleMode == rhs.scheduleMode &&
        lhs.scheduledDates == rhs.scheduledDates
    }

    // MARK: - Initializer
    
    /// ScheduleCard 생성자
    /// - Parameters:
    ///   - selectedDate: 선택된 날짜 바인딩
    ///   - currentMonth: 현재 표시할 월 바인딩
    ///   - scheduleMode: 초기 스케줄 표시 모드 (기본값: .grid)
    ///   - scheduledDates: 일정이 있는 날짜 집합 (기본값: 빈 집합)
    init(
        selectedDate: Binding<Date> = .constant(Date()),
        currentMonth: Binding<Date> = .constant(Date()),
        scheduleMode: ScheduleMode = .grid,
        scheduledDates: Set<Date> = []
    ) {
        self._selectedDate = selectedDate
        self._currentMonth = currentMonth
        self._scheduleMode = State(initialValue: scheduleMode)
        self.scheduledDates = scheduledDates
    }

    var body: some View {
        VStack(spacing: DefaultSpacing.spacing8) {
            ScheduleHeader(month: $currentMonth, selectedDate: $selectedDate, scheduleMode: $scheduleMode)
            
            if scheduleMode == .horizon {
                CalendarHorizonCard(
                    selectedDate: $selectedDate,
                    month: $currentMonth,
                    scheduledDates: scheduledDates
                )
                .equatable()
            } else {
                CalendarGridCard(
                    selectedDate: $selectedDate,
                    month: $currentMonth,
                    scheduledDates: scheduledDates
                )
                .equatable()
            }
        }
        .animation(.easeInOut(duration: DefaultConstant.animationTime), value: scheduleMode)
    }
}
