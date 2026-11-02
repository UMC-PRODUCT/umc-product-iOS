//
//  NoticeItemLayoutTests.swift
//  NoticePresentationTests
//
//  Created by euijjang97 on 11/2/26.
//

import NoticeDomain
import SwiftUI
import Testing
import UIKit
@testable import NoticePresentation

@Suite("Notice sidebar layout")
@MainActor
struct NoticeItemLayoutTests {
    @Test("긴 제목과 미리보기도 320pt 사이드바의 두 줄 행 안에 머문다")
    func compactRowFitsNarrowSidebar() {
        let model = NoticeItemModel(
            generation: "12", scope: .central, category: .general,
            mustRead: false, isAlert: false, date: .now,
            title: String(repeating: "긴 공지 제목 ", count: 20),
            content: String(repeating: "긴 본문 미리보기 ", count: 20),
            writer: String(repeating: "긴 작성자 이름 ", count: 20),
            links: [], images: [], vote: nil, viewCount: "123"
        )
        let host = UIHostingController(rootView:
            NoticeItem(model: model, isSidebar: true, action: {})
                .environment(\.dynamicTypeSize, .large)
        )
        let size = host.sizeThatFits(in: CGSize(width: 320, height: 1000))
        #expect(size.width <= 320)
        #expect(size.height > 44)
        #expect(size.height <= 88)
    }
}
