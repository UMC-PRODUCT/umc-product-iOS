//
//  CommunitySplitSelectionTests.swift
//  CommunityPresentationTests
//
//  Created by euijjang97 on 11/2/26.
//

import SwiftUI
import Testing
@testable import CommunityPresentation

@Suite("Community split selection")
struct CommunitySplitSelectionTests {
    private let room = CommunityDestination.threadRoom(threadId: "room", title: "대화")

    @Test("빈 경로와 현재 단일 채팅방만 교체할 수 있다")
    func allowsRootAndKnownRoom() {
        #expect(CommunitySplitSelection.canReplaceRoom(path: NavigationPath(), selectedRoom: nil))
        var path = NavigationPath()
        path.append(room)
        #expect(CommunitySplitSelection.canReplaceRoom(path: path, selectedRoom: room))
        #expect(!CommunitySplitSelection.canReplaceRoom(path: path, selectedRoom: nil))
    }

    @Test("새 스레드 초안과 채팅방 하위 경로를 보존한다")
    func preservesFormsAndNestedNavigation() {
        var creation = NavigationPath()
        creation.append(CommunityDestination.threadCreate)
        #expect(!CommunitySplitSelection.canReplaceRoom(path: creation, selectedRoom: room))
        var nested = NavigationPath()
        nested.append(room)
        nested.append(CommunityDestination.threadMembers(threadId: "room"))
        #expect(!CommunitySplitSelection.canReplaceRoom(path: nested, selectedRoom: room))
    }

    @Test("다른 딥링크 방을 모르는 상태에서 교체하지 않는다")
    func preservesUnknownDeepLink() {
        var path = NavigationPath()
        path.append(CommunityDestination.threadRoom(threadId: "linked", title: ""))
        #expect(!CommunitySplitSelection.canReplaceRoom(path: path, selectedRoom: room))
    }
}
