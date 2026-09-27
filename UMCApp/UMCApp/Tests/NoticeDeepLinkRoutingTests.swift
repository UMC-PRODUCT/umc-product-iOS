//
//  NoticeDeepLinkRoutingTests.swift
//  UMCAppTests
//
//  Created by euijjang97 on 9/27/26.
//

import CoreRouting
import Foundation
import NoticeDomain
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
