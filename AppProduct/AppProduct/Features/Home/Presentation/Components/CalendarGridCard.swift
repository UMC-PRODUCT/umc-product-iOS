//
//  CalendarGridView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

/// 캘린더 그리드 카드
struct CalendarGridCard: View, Equatable {
    @Binding var selectedDate: Date
    let month: Date
    let scheduledDates: Set<Date>
    
    private enum Constants {
        static let padding: CGFloat = 24
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.selectedDate == rhs.selectedDate &&
        lhs.month == rhs.month &&
        lhs.scheduledDates == rhs.scheduledDates
    }

    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: DefaultSpacing.spacing24, content: {
            WeekDayHeader()
                .equatable()
            dateGrid
        })
        .padding(Constants.padding)
        .background(.grey000)
        .glassEffect(.regular, in: .rect(cornerRadius: DefaultConstant.defaultCornerRadius))
    }
    
    // MARK: - Cell
    /// 달력 날짜 셀 그리드
    private var dateGrid: some View {
        LazyVStack(spacing: DefaultSpacing.spacing16, content: {
            ForEach(groupedDates, id: \.self) { week in
                HStack(spacing: DefaultSpacing.spacing16, content: {
                    ForEach(week, id: \.self) { date in
                        let isCurrentMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)

                        if isCurrentMonth {
                            currentMonthDate(date: date)
                        } else {
                            beforeMonthDate
                        }
                    }
                })
            }
        })
    }
    
    private func currentMonthDate(date: Date) -> some View {
        DateCell(
            date: date,
            isSelected: date.isSameDay(selectedDate),
            isCurrentMonth: true,
            hasSchedule: hasSchedule(date),
            isToday: calendar.isDateInToday(date)
        )
        .containerRelativeFrame(.horizontal, count: 7, span: 1, spacing: DefaultSpacing.spacing16, alignment: .center)
        .onTapGesture {
            withAnimation(.easeInOut(duration: DefaultConstant.animationTime)) {
                selectedDate = date
            }
        }
    }

    private var beforeMonthDate: some View {
        Color.clear
            .containerRelativeFrame(.horizontal, count: 7, span: 1, spacing: DefaultSpacing.spacing16, alignment: .center)
    }
    
    /// 일주일 날짜 표시
    private var groupedDates: [[Date]] {
        let dates = adjustedDates
        return stride(from: 0, to: dates.count, by: 7).map {
            Array(dates[$0..<min($0 + 7, dates.count)])
        }
    }
    
    /// 일주일 날짜에 해당하는 일 표시
    private var adjustedDates: [Date] {
        let datesInMonth = month.datesInMonth()
        guard let firstDate = datesInMonth.first else { return [] }

        let firstWeekDay = calendar.component(.weekday, from: firstDate)

        let emptyDays = (firstWeekDay - 1)
        var dates: [Date] = []
        
        for i in 0..<emptyDays {
            if let date = calendar.date(byAdding: .day, value: -(emptyDays - i), to: firstDate) {
                dates.append(date)
            }
        }
        
        dates.append(contentsOf: datesInMonth)
        return dates
    }
    
    
    /// 스케줄을 가지고 있는지 판단
    private func hasSchedule(_ date: Date) -> Bool {
        scheduledDates.contains(where: { $0.isSameDay(date) })
    }
}

extension CalendarGridCard {
    /// 캘린더 헤더
    fileprivate struct WeekDayHeader: View, Equatable {
        var body: some View {
            HStack(spacing: DefaultSpacing.spacing16, content: {
                ForEach(Date().weekDaySymbols(style: .none), id: \.self) { weekday in
                    Text(weekday)
                        .appFont(.footnote, color: .grey400)
                        .containerRelativeFrame(.horizontal, count: 7, span: 1, spacing: DefaultSpacing.spacing16, alignment: .center)
                }
            })
        }
    }
}

#Preview {
    @Previewable @State var selectedDate: Date = Date.now

    let calendar = Calendar.current
    let today = Date.now

    let scheduledDates: Set<Date> = [
        today,
        calendar.date(byAdding: .day, value: 3, to: today)!,
        calendar.date(byAdding: .day, value: 7, to: today)!,
        calendar.date(byAdding: .day, value: 15, to: today)!
    ]

    CalendarGridCard(
        selectedDate: $selectedDate,
        month: today,
        scheduledDates: scheduledDates
    )
}
