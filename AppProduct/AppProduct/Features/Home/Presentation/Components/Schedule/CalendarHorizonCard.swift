//
//  CalendarHorizonCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/16/26.
//

import SwiftUI

struct CalendarHorizonCard: View, Equatable {

    // MARK: - Porperty
    @Binding var selectedDate: Date
    @Binding var month: Date
    let scheduledDates: Set<Date>

    @State private var scrolledDate: Date?
    private let calendar = Calendar.current
    private let today = Date.now
    
    private var dates: [Date] {
        month.datesInMonth()
    }

    // MARK: - Constant
    private enum Constants {
        static let pillHeight: CGFloat = 170
    }
    
    // MARK: - Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.selectedDate == rhs.selectedDate &&
        lhs.month == rhs.month &&
        lhs.scheduledDates == rhs.scheduledDates
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: DefaultSpacing.spacing12) {
                ForEach(dates, id: \.self) { date in
                    datePill(date)
                }
            }
            .scrollTargetLayout()
            .frame(height: Constants.pillHeight)
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrolledDate, anchor: .center)
        .task {
            scrollToToday()
        }
        .onChange(of: month) { _, _ in
            scrollToToday()
        }
    }
    
    private func datePill(_ date: Date) -> some View {
        DatePill(
            date: date,
            isSelected: date.isSameDay(selectedDate),
            hasSchedule: scheduledDates.contains(where: { $0.isSameDay(date) }),
            isToday: calendar.isDateInToday(date), action: {
                withAnimation(.easeInOut(duration: DefaultConstant.animationTime)) {
                    selectedDate = date
                    if !calendar.isDate(date, equalTo: month, toGranularity: .month) {
                        month = date
                    }
                }
            }
        )
        .id(date)
    }

    private func scrollToToday() {
        if let todayInDates = dates.first(where: { $0.isSameDay(today) }) {
            scrolledDate = todayInDates
        } else if let selectedInDates = dates.first(where: { $0.isSameDay(selectedDate) }) {
            scrolledDate = selectedInDates
        } else {
            scrolledDate = dates.first
        }
    }
}

#Preview {
    @Previewable @State var selectedDate: Date = Date.now
    @Previewable @State var currentMonth: Date = Date.now

    let calendar = Calendar.current

    let scheduledDates: Set<Date> = [
        Date.now,
        calendar.date(byAdding: .day, value: 3, to: .now)!,
        calendar.date(byAdding: .day, value: 7, to: .now)!
    ]

    CalendarHorizonCard(
        selectedDate: $selectedDate,
        month: $currentMonth,
        scheduledDates: scheduledDates
    )
}
