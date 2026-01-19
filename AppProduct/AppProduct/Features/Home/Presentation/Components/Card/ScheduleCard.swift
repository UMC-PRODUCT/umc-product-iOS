//
//  SCheduleCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

/// 달력 리스트 및 캘린더 전환 카드
struct ScheduleCard: View {
    @State private var selectedDate = Date()
    @State var scheduleMode: ScheduleMode = .grid
    @State private var currentMonth = Date()
    
    // !!!: - 수정 필요
    @State private var scheduledDates: Set<Date> = {
             let calendar = Calendar.current
             var dates = Set<Date>()

             if let date1 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 19)),
                let date2 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 21)),
                let date3 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 25)) {
                 dates.insert(date1)
                 dates.insert(date2)
                 dates.insert(date3)
             }
             return dates
         }()
  
    
    var body: some View {
        Section(content: {
            if scheduleMode == .horizon {
                CalendarHorizonCard(
                    selectedDate: $selectedDate,
                    month: $currentMonth,
                    scheduledDates: scheduledDates
                )
            } else {
                CalendarGridCard(
                    selectedDate: $selectedDate,
                    month: $currentMonth,
                    scheduledDates: scheduledDates
                )
                .equatable()
            }
        }, header: {
            ScheduleHeader(month: $currentMonth, selectedDate: $selectedDate, scheduleMode: $scheduleMode)
        })
        .animation(.easeInOut(duration: DefaultConstant.animationTime), value: scheduleMode)
    }
}

#Preview {
    ScheduleCard()
    .safeAreaPadding(.horizontal, 16)
}
