//
//  ScheduleDDayFormattingTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 3/12/26.
//

@testable import AppProduct
import Foundation
import Testing

struct ScheduleDDayFormattingTests {

    @Test("미래 일정 dDay는 D-N 형식으로 표시한다")
    func futureScheduleFormatsAsDMinus() {
        let data = ScheduleData(
            scheduleId: 1,
            title: "해커톤",
            startsAt: .now,
            endsAt: .now,
            status: "참여 예정",
            dDay: 3
        )

        #expect(data.dDayText == "D-3")
    }

    @Test("오늘 일정 dDay는 D-Day로 표시한다")
    func todayScheduleFormatsAsDDay() {
        let data = ScheduleDetailData(
            scheduleId: 1,
            name: "정기 세션",
            description: "",
            tags: [],
            startsAt: .now,
            endsAt: .now,
            isAllDay: false,
            locationName: "",
            latitude: 0,
            longitude: 0,
            status: "진행 예정",
            dDay: 0,
            requiresAttendanceApproval: false
        )

        #expect(data.dDayText == "D-Day")
    }

    @Test("지난 일정 dDay는 D+N 형식으로 표시한다")
    func pastScheduleFormatsAsDPlus() {
        let data = ScheduleData(
            scheduleId: 1,
            title: "데모데이",
            startsAt: .now,
            endsAt: .now,
            status: "종료됨",
            dDay: -5
        )

        #expect(data.dDayText == "D+5")
    }
}
