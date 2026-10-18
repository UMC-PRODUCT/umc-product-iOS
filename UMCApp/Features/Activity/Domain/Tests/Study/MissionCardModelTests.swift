//
//  MissionCardModelTests.swift
//  ActivityDomainTests
//
//  Created by jaewon Lee on 5/11/26.
//

import Foundation
import Testing
@testable import ActivityDomain

// MARK: - Helpers

private func makeCard(
    week: String = "1",
    isExtra: Bool = false
) -> MissionCardModel {
    MissionCardModel(
        week: week,
        platform: "iOS",
        title: "Week \(week)",
        missionTitle: "학습 내용",
        isExtra: isExtra
    )
}

// MARK: - Suite

@Suite("MissionCardModel — 속성 도메인 규칙")
struct MissionCardModelTests {

    // MARK: - isExtra default

    @Test("isExtra 의 기본값은 false 이다")
    func isExtraDefaultsToFalse() {
        // Given
        let card = makeCard()

        // When
        let isExtra = card.isExtra

        // Then
        #expect(isExtra == false)
    }

    @Test("isExtra=true 로 지정하면 그 값이 그대로 노출된다")
    func isExtraReflectsInput() {
        // Given
        let card = makeCard(isExtra: true)

        // When
        let isExtra = card.isExtra

        // Then
        #expect(isExtra == true)
    }
}
