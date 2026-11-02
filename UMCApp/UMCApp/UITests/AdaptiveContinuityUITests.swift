//
//  AdaptiveContinuityUITests.swift
//  UMCAppAdaptiveUITests
//
//  Created by euijjang97 on 11/2/26.
//

import XCTest

/// 실제 창 크기가 바뀌는 동안 선택 날짜와 공지 상세의 연속성을 검증한다.
@MainActor
final class AdaptiveContinuityUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
    }

    func testCalendarMonthSurvivesRotation() {
        let app = launchStub()
        let month = app.buttons["home.calendar.month"]
        for _ in 0..<4 where !month.isHittable { app.swipeUp() }
        XCTAssertTrue(month.waitForExistence(timeout: 10))
        app.buttons["다음 달"].tap()
        let selectedMonth = month.label
        capture("home-portrait")
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(month.waitForExistence(timeout: 5))
        XCTAssertEqual(month.label, selectedMonth)
        capture("home-landscape")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertEqual(month.label, selectedMonth)
    }

    func testNoticeDetailSurvivesRotationAndTabSwitch() {
        let app = launchStub()
        app.buttons["공지"].firstMatch.tap()
        let notice = app.staticTexts["12기 중앙 해커톤 일정 안내"].firstMatch
        XCTAssertTrue(notice.waitForExistence(timeout: 10))
        notice.tap()
        let detail = app.scrollViews["notice.detail.content"]
        XCTAssertTrue(detail.waitForExistence(timeout: 10))
        capture("notice-detail-portrait")
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        XCTAssertTrue(detail.isHittable)
        capture("notice-detail-landscape")
        app.buttons["홈"].firstMatch.tap()
        app.buttons["공지"].firstMatch.tap()
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        XCTAssertTrue(detail.isHittable)
    }

    func testAccessibilityTextKeepsCalendarControlsInsideWindow() {
        let app = launchStub(extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])
        let month = app.buttons["home.calendar.month"]
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<6 where !month.isHittable {
            // 큰 글자에서 하단 액세서리가 커지므로 그 위의 실제 스크롤 영역을 드래그한다.
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
                .press(forDuration: 0.05, thenDragTo:
                    scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)))
        }
        capture("home-accessibility-scroll-result")
        XCTAssertTrue(month.isHittable, app.debugDescription)
        XCTAssertGreaterThanOrEqual(month.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(month.frame.maxX, app.frame.maxX)
        let previousMonth = month.label
        app.buttons["다음 달"].tap()
        XCTAssertNotEqual(month.label, previousMonth)
        capture("home-accessibility")
        app.buttons["활동"].firstMatch.tap()
        capture("activity-accessibility")
    }

    func testCommunityDraftSurvivesRotation() {
        let app = launchStub()
        app.buttons["커뮤니티"].firstMatch.tap()
        let thread = app.staticTexts["iOS 스터디"].firstMatch
        XCTAssertTrue(thread.waitForExistence(timeout: 10))
        thread.tap()
        let composer = app.descendants(matching: .any)
            .matching(identifier: "community.message.draft").firstMatch
        XCTAssertTrue(composer.waitForExistence(timeout: 15))
        composer.tap()
        composer.typeText("Duo draft continuity")
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        XCTAssertEqual(composer.value as? String, "Duo draft continuity")
        capture("community-split-draft")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertEqual(composer.value as? String, "Duo draft continuity")
    }

    func testMyPageSettingsSurvivesRotationAndTabSwitch() {
        let app = launchStub()
        app.buttons["마이페이지"].firstMatch.tap()
        let settings = app.buttons["설정"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        settings.tap()
        let detail = app.navigationBars["설정"]
        XCTAssertTrue(detail.waitForExistence(timeout: 10))
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        app.buttons["홈"].firstMatch.tap()
        app.buttons["마이페이지"].firstMatch.tap()
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
    }

    func testAllTabsHaveReachableContent() {
        let app = launchStub()
        XCUIDevice.shared.orientation = .landscapeLeft
        for title in ["홈", "공지", "활동", "커뮤니티", "마이페이지"] {
            let tab = app.buttons[title].firstMatch
            XCTAssertTrue(tab.waitForExistence(timeout: 5))
            tab.tap()
            capture("wide-" + title)
        }
    }

    private func launchStub(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-stubSession", "--notice-force-permission",
            "-hasShownAppleIntelligenceIntro", "YES",
            "-debug.stubSession.forceRealSession", "NO"
        ] + extraArguments
        app.launchEnvironment["MOCK_AUTH_BYPASS"] = "1"
        app.launch()
        let permission = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
        if permission.waitForExistence(timeout: 3) {
            let allow = permission.buttons.matching(
                NSPredicate(format: "label == %@ OR label == %@", "허용", "Allow")
            ).firstMatch
            if allow.exists { allow.tap() }
        }
        XCTAssertTrue(app.buttons["홈"].firstMatch.waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["소속 기수"].waitForExistence(timeout: 10))
        return app
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIApplication().screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
