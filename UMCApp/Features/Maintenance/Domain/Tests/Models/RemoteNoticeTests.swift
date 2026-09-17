//
//  RemoteNoticeTests.swift
//  MaintenanceDomainTests
//
//  Created by euijjang97 on 9/17/26.
//

import Foundation
import Testing
@testable import MaintenanceDomain

// MARK: - Helpers

private let seoulCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
    return calendar
}()

/// 서울 기준 `2026-09-17 23:30`.
private let today = seoulCalendar.date(
    from: DateComponents(year: 2026, month: 9, day: 17, hour: 23, minute: 30)
)!

private func makeNotice(
    screen: String = "home",
    isEnabled: Bool = true,
    template: RemoteNoticeTemplate = .info,
    until: String? = nil
) -> RemoteNotice {
    RemoteNotice(
        screen: screen,
        isEnabled: isEnabled,
        template: template,
        title: "안내",
        body: "본문",
        until: until
    )
}

// MARK: - Tests

@Suite("RemoteNotice — 노출 여부·대상 화면 판정")
struct RemoteNoticeTests {

    @Test("꺼져 있으면 띄우지 않는다")
    func hiddenWhenDisabled() {
        #expect(!makeNotice(isEnabled: false).isShowable(today: today, calendar: seoulCalendar))
    }

    @Test("앱이 모르는 모양이면 띄우지 않는다")
    func hiddenWhenUnknownTemplate() {
        #expect(!makeNotice(template: .unknown).isShowable(today: today, calendar: seoulCalendar))
    }

    @Test("종료일이 없으면 띄운다", arguments: [nil, ""])
    func shownWithoutUntil(until: String?) {
        #expect(makeNotice(until: until).isShowable(today: today, calendar: seoulCalendar))
    }

    @Test("종료일 당일 밤까지 띄운다")
    func shownThroughLastDay() {
        #expect(makeNotice(until: "2026-09-17").isShowable(today: today, calendar: seoulCalendar))
        #expect(makeNotice(until: "2026-09-18").isShowable(today: today, calendar: seoulCalendar))
    }

    @Test("종료일이 지났으면 띄우지 않는다")
    func hiddenAfterLastDay() {
        #expect(!makeNotice(until: "2026-09-16").isShowable(today: today, calendar: seoulCalendar))
    }

    @Test(
        "종료일 형식이 깨졌으면 띄우지 않는다",
        arguments: ["2026/09/17", "2026-9-17", "2026-02-30", "내일", "2026-09-17T00:00:00Z"]
    )
    func hiddenWhenUntilMalformed(until: String) {
        #expect(!makeNotice(until: until).isShowable(today: today, calendar: seoulCalendar))
    }

    @Test("ALL은 모든 화면, 그 외에는 같은 화면만 대상이다")
    func targetsScreen() {
        #expect(makeNotice(screen: RemoteNotice.allScreens).targets(screen: .login))
        #expect(makeNotice(screen: "home").targets(screen: .home))
        #expect(!makeNotice(screen: "home").targets(screen: .mypage))
        #expect(!makeNotice(screen: "Home").targets(screen: .home))
    }
}
