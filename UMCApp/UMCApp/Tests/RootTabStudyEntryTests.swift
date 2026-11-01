//
//  RootTabStudyEntryTests.swift
//  UMCAppTests
//
//  Created by euijjang97 on 8/29/26.
//

import ActivityPresentation
import CoreRouting
import SwiftUI
import Testing
@testable import UMCApp

@Suite("RootTab — 마이페이지 「나의 스터디」 진입 전이")
struct RootTabStudyEntryTests {

    @Test("커리큘럼을 MyPage에 쌓고 Activity의 기존 경로를 보존한다")
    func pushesStudyOnMyPage() {
        let pathStore = PathStore()
        pathStore.push("attendanceDetail", on: .activity)
        pathStore.push("studyScheduleRegistration", on: .activity)
        pathStore.selectedTab = .mypage

        RootTabView.enterMyStudy(pathStore: pathStore)

        var expectedPath = NavigationPath()
        expectedPath.append(StudyDestination.curriculum)
        #expect(pathStore[.mypage] == expectedPath)
        #expect(pathStore.selectedTab == .mypage)
        #expect(pathStore.depth(of: .activity) == 2)

        pathStore[.mypage].removeLast()
        #expect(pathStore.isAtRoot(.mypage))
        #expect(pathStore.selectedTab == .mypage)
    }
}
