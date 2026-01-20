//
//  SCheduleCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

/// 달력 리스트 및 캘린더 전환 카드
struct ScheduleCard: View, Equatable {
    // MARK: - Bindings
    @Binding var selectedDate: Date
    @Binding var currentMonth: Date

    // MARK: - State
    @State var scheduleMode: ScheduleMode = .grid

    // MARK: - Properties
    let scheduledDates: Set<Date>

    // MARK: - Equatable
    static func == (lhs: ScheduleCard, rhs: ScheduleCard) -> Bool {
        lhs.selectedDate == rhs.selectedDate &&
        lhs.currentMonth == rhs.currentMonth &&
        lhs.scheduleMode == rhs.scheduleMode &&
        lhs.scheduledDates == rhs.scheduledDates
    }

    // MARK: - Initializer
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
