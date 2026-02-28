//
//  CalendarHorizonCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/16/26.
//

import SwiftUI

/// 가로 스크롤 가능한 날짜 리스트 카드 뷰
///
/// 월별 전체 달력이 아닌, 가로로 스크롤하여 날짜를 선택할 수 있는 형태의 캘린더입니다.
struct CalendarHorizonCard: View, Equatable {

    // MARK: - Porperties
    
    /// 현재 선택된 날짜 바인딩
    @Binding var selectedDate: Date
    
    /// 현재 표시 중인 월 바인딩
    @Binding var month: Date
    
    /// 일정이 존재하는 날짜들의 집합
    let scheduledDates: Set<Date>

    /// 스크롤 위치 제어를 위한 상태 프로퍼티
    @State private var scrolledDate: Date?
    
    private let calendar = Calendar.current
    private let today = Date.now
    
    /// 현재 월에 포함된 모든 날짜 배열
    private var dates: [Date] {
        month.datesInMonth()
    }

    // MARK: - Constants
    
    private enum Constants {
        /// 날짜 알약 뷰의 높이
        static let pillHeight: CGFloat = 200
    }
    
    // MARK: - Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.selectedDate == rhs.selectedDate &&
        lhs.month == rhs.month &&
        lhs.scheduledDates == rhs.scheduledDates
    }

    // MARK: - Body
    
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
        // 스크롤 위치 바인딩
        .scrollPosition(id: $scrolledDate, anchor: .center)
        // 초기 로드 시 오늘 날짜로 스크롤
        .task {
            scrollToToday()
        }
        // 월 변경 시 오늘 날짜로 스크롤
        .onChange(of: month) { _, _ in
            scrollToToday()
        }
    }
    
    /// 개별 날짜 알약 뷰 생성
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

    /// 오늘 날짜 또는 선택된 날짜로 스크롤 이동
    ///
    /// - 우선순위 1: 오늘 날짜가 현재 리스트에 있다면 해당 위치로 이동
    /// - 우선순위 2: 선택된 날짜가 리스트에 있다면 해당 위치로 이동
    /// - 우선순위 3: 둘 다 없다면 리스트의 첫 번째 날짜로 이동
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
