//
//  MessageBubbleLayoutTests.swift
//  CommunityPresentationTests
//
//  Created by euijjang97 on 9/16/26.
//

import SwiftUI
import Testing
@testable import CommunityPresentation

// MARK: - Constants

fileprivate enum Constants {
    static let maxWidth: CGFloat = 280
    /// 아이폰 폭. 캡보다 넉넉해야 "제안 폭까지 늘어나는" 회귀를 잡을 수 있다.
    static let proposedWidth: CGFloat = 402
    static let longText = String(repeating: "제안 크기가 부모에서 자식으로 내려간다 ", count: 10)
}

// MARK: - Tests

@Suite("BubbleWidthLayout")
@MainActor
struct MessageBubbleLayoutTests {

    @Test("짧은 본문은 캡까지 늘어나지 않는다")
    func shortTextHugsContent() throws {
        let width = try renderedWidth { Text("네") }

        #expect(width < Constants.maxWidth)
    }

    /// 줄바꿈된 `Text` 는 가장 긴 줄 폭만 보고해 캡보다 몇 pt 모자랄 수 있다. 제안받은 폭을
    /// 그대로 채우게 해 캡 자체를 잰다 — 링크 카드가 바로 이렇게 폭을 채운다.
    @Test("긴 본문은 캡에서 멈춘다")
    func longTextStopsAtCap() throws {
        let width = try renderedWidth {
            Text(Constants.longText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        #expect(width == Constants.maxWidth)
    }

    /// 인용 블록·링크 카드처럼 안에 Spacer 가 든 자식이 말풍선을 캡까지 벌리면 안 된다.
    @Test("Spacer 가 든 자식도 내용 폭만 차지한다")
    func spacerDoesNotStretchBubble() throws {
        let width = try renderedWidth {
            VStack {
                HStack {
                    Text("짧음")
                    Spacer(minLength: 0)
                }
                Text("네")
            }
        }

        #expect(width < Constants.maxWidth)
    }

    /// 스택은 형제끼리 높이를 나눠 주다가 본문보다 작은 높이를 제안하기도 한다. 그 제안을
    /// 자식에게 그대로 넘기면 긴 본문이 한 줄로 잘린다.
    @Test("높이를 좁게 제안해도 본문이 잘리지 않는다")
    func ignoresHeightProposal() throws {
        let natural = try renderedSize(height: nil) { Text(Constants.longText) }
        let squeezed = try renderedSize(height: 1) { Text(Constants.longText) }

        #expect(squeezed.height == natural.height)
    }

    // MARK: - Function

    private func renderedWidth(@ViewBuilder _ content: () -> some View) throws -> CGFloat {
        try renderedSize(height: nil, content).width
    }

    private func renderedSize(
        height: CGFloat?,
        @ViewBuilder _ content: () -> some View
    ) throws -> CGSize {
        let renderer = ImageRenderer(
            content: BubbleWidthLayout(maxWidth: Constants.maxWidth) { content() }
        )
        renderer.proposedSize = ProposedViewSize(width: Constants.proposedWidth, height: height)
        renderer.scale = 1
        return try #require(renderer.uiImage).size
    }
}
