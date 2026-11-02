//
//  NoticeDeepLinkRoutingTests.swift
//  UMCAppTests
//
//  Created by euijjang97 on 9/27/26.
//

import CoreRouting
import Foundation
import NoticeDomain
import SwiftUI
import Testing
@testable import UMCApp

@MainActor
struct NoticeDeepLinkRoutingTests {
    @Test
    func pendingNoticeRoutesOnceAfterLogin() async throws {
        let links = DeepLinkStore()
        links.receive(URL(string: "umc://notice/34")!)
        #expect(links.pending == .message(.notice(id: "34")))
        let paths = PathStore()
        paths.push("previous", on: .notice)
        guard case .message(.notice(let id)) = links.take() else {
            Issue.record("Pending notice missing")
            return
        }
        try await RootTabView.openNoticeLink(pathStore: paths) { detail(id: id) }
        #expect(paths.selectedTab == .notice)
        #expect(paths.depth(of: .notice) == 1)
        #expect(links.take() == nil)
    }

    @Test
    func cancelledLookupDoesNotOverrideNewerLink() async {
        let paths = PathStore()
        var continuation: CheckedContinuation<NoticeDetail, Never>?
        let task = Task {
            try await RootTabView.openNoticeLink(pathStore: paths) {
                await withCheckedContinuation { continuation = $0 }
            }
        }
        while continuation == nil { await Task.yield() }
        task.cancel()
        paths.selectedTab = .community
        continuation?.resume(returning: detail(id: "34"))
        _ = await task.result
        #expect(paths.selectedTab == .community)
        #expect(paths.isAtRoot(.notice))
    }

    @Test
    func selectingNoticeReplacesDetailAndPreservesOtherTabs() {
        let paths = PathStore()
        paths.selectedTab = .notice
        let previous = detail(id: "34")
        paths.push(NavigationDestination.notice(.detail(detailItem: previous)), on: .notice)
        paths.push("home-detail", on: .home)
        let notice = detail(id: "45")

        let selected = RootTabView.selectNotice(notice, pathStore: paths, replacing: previous)
        #expect(selected)

        var expected = NavigationPath()
        expected.append(NavigationDestination.notice(.detail(detailItem: notice)))
        #expect(paths[.notice] == expected)
        #expect(paths.depth(of: .home) == 1)
        #expect(paths.selectedTab == .notice)
    }

    @Test
    func sidebarSelectionPreservesRootCreateDraft() {
        let paths = PathStore()
        paths.push(
            NavigationDestination.notice(.editor(mode: .create, selectedGisuId: "1")),
            on: .notice
        )
        let editorPath = paths[.notice]

        #expect(!RootTabView.selectNotice(detail(id: "45"), pathStore: paths))
        #expect(paths[.notice] == editorPath)
    }

    @Test
    func sidebarSelectionPreservesNestedEditorDraft() {
        let paths = PathStore()
        let previous = detail(id: "34")
        paths.push(NavigationDestination.notice(.detail(detailItem: previous)), on: .notice)
        paths.push(
            NavigationDestination.notice(.editor(mode: .create, selectedGisuId: "1")),
            on: .notice
        )
        let editorPath = paths[.notice]

        #expect(!RootTabView.selectNotice(
            detail(id: "45"), pathStore: paths, replacing: previous
        ))
        #expect(paths[.notice] == editorPath)
        paths[.notice].removeLast()
        #expect(RootTabView.canSelectNotice(pathStore: paths, replacing: previous))
    }

    private func detail(id: String) -> NoticeDetail {
        NoticeDetail(
            id: id, generation: "0", scope: .central, category: .general,
            isMustRead: false, title: "공지", content: "본문", authorID: "1",
            authorName: "작성자", authorImageURL: nil, createdAt: Date(), updatedAt: nil,
            targetAudience: TargetAudience(
                generation: "0", scope: .central, parts: [], branches: [], schools: []
            ), hasPermission: false, images: [], links: [], vote: nil
        )
    }
}
