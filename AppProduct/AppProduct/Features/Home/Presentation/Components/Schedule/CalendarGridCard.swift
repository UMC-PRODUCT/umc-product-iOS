//
//  CalendarGridView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

/// 캘린더 그리드 카드
struct CalendarGridCard: View, Equatable {
    // MARK: - Property
    @Binding var selectedDate: Date
    @Binding var month: Date
    let scheduledDates: Set<Date>
    
    @State private var dragOffset: CGFloat = 0
    @State private var direction: SpldeDirection = .none
    
    private enum SpldeDirection {
        case left, right, none
    }
    
    // MARK: Constant
    private enum Constants {
        static let padding: CGFloat = 24
        static let monthRange: Int = 12
        static let swipeThreshold: CGFloat = 50
        static let calendarHeight: CGFloat = 400
    }
    
    // MARK: - Equtable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.selectedDate == rhs.selectedDate &&
        lhs.month == rhs.month &&
        lhs.scheduledDates == rhs.scheduledDates
    }
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: DefaultSpacing.spacing16), count: 7)
    
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
        .glassEffect(.regular, in: .rect(cornerRadius: DefaultConstant.defaultCornerRadius))
        .contentShape(Rectangle())
        .id(month)
        .transition(slideTransition)
        .gesture(swipeGesture)
    }
    
    private var slideTransition: AnyTransition {
        switch direction {
        case .left:
            return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .right:
            return .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        case .none:
            return .identity
        }
    }
    
    // MARK: - Gesture
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let horizontalAmount = value.translation.width
                
                if horizontalAmount > Constants.swipeThreshold {
                    direction = .right
                    changeMonth(by: -1)
                } else if horizontalAmount < -Constants.swipeThreshold {
                    direction = .left
                    changeMonth(by: 1)
                }
                dragOffset = 0
            }
    }
    
    private func changeMonth(by value: Int) {
        withAnimation(.easeInOut(duration: DefaultConstant.animationTime)) {
            if let newMonth = calendar.date(byAdding: .month, value: value, to: month) {
                month = newMonth
            }
        }
    }
    
    // MARK: - Cell
    /// 달력 날짜 셀 그리드
    @ViewBuilder
    private var dateGrid: some View {
        LazyVGrid(columns: columns, spacing: DefaultSpacing.spacing16) {
            ForEach(adjustedDates, id: \.self) { date in
                let isCurrentMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
                
                if isCurrentMonth {
                    currentMonthDate(date: date)
                } else {
                    Color.clear
                }
            }
        }
    }
    
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
    
    /// 일주일 날짜에 해당하는 일 표시
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
    
    /// 스케줄을 가지고 있는지 판단
    private func hasSchedule(_ date: Date) -> Bool {
        scheduledDates.contains(where: { $0.isSameDay(date) })
    }
}

extension CalendarGridCard {
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
