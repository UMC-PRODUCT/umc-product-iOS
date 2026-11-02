//
//  MyPageSplitSelectionTests.swift
//  MyPagePresentationTests
//
//  Created by euijjang97 on 11/2/26.
//

import SwiftUI
import Testing
@testable import MyPagePresentation

@Suite("MyPage split selection")
struct MyPageSplitSelectionTests {
    @Test("개요와 알고 있는 읽기 전용 상세만 교체한다")
    func allowsOverviewAndKnownReadOnlyDetail() {
        #expect(MyPageSplitSelection.canReplace(path: NavigationPath(), knownReadOnlyPath: nil))
        var certificates = NavigationPath()
        certificates.append(MyPageDestination.certificates)
        #expect(MyPageSplitSelection.canReplace(
            path: certificates, knownReadOnlyPath: certificates
        ))
        #expect(!MyPageSplitSelection.canReplace(path: certificates, knownReadOnlyPath: nil))
    }

    @Test("설정과 계정 편집은 읽기 전용으로 간주하지 않는다")
    func protectsAccountForms() {
        #expect(!MyPageSplitSelection.isReadOnly(.settings))
        #expect(!MyPageSplitSelection.isReadOnly(.changeEmail))
        #expect(!MyPageSplitSelection.isReadOnly(.changePassword))
        #expect(!MyPageSplitSelection.isReadOnly(.registerPassword))
        #expect(MyPageSplitSelection.isReadOnly(.certificates))
    }

    @Test("읽기 전용 화면 위에 쌓인 새 경로는 보존한다")
    func protectsNestedRoute() {
        var original = NavigationPath()
        original.append(MyPageDestination.certificates)
        var nested = original
        nested.append(MyPageDestination.changeEmail)
        #expect(!MyPageSplitSelection.canReplace(path: nested, knownReadOnlyPath: original))
    }
}
