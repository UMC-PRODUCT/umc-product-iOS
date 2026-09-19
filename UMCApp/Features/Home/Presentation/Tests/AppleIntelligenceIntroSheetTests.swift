//
//  AppleIntelligenceIntroSheetTests.swift
//  HomePresentationTests
//
//  Created by euijjang97 on 9/19/26.
//

import FoundationModels
import Testing
@testable import HomePresentation

@Suite("AppleIntelligenceIntroSheet — 홈 진입 안내 노출 판정")
struct AppleIntelligenceIntroSheetTests {

    @Test("Apple Intelligence 가 꺼져 있고 아직 안 보여 줬으면 노출")
    func presentsWhenNotEnabled() {
        #expect(AppleIntelligenceIntroSheet.shouldPresent(
            availability: .unavailable(.appleIntelligenceNotEnabled),
            hasBeenShown: false
        ))
    }

    @Test("이미 보여 줬으면 다시 노출하지 않음")
    func skipsWhenAlreadyShown() {
        #expect(!AppleIntelligenceIntroSheet.shouldPresent(
            availability: .unavailable(.appleIntelligenceNotEnabled),
            hasBeenShown: true
        ))
    }

    @Test(
        "켤 필요가 없거나 켤 수 없는 상태에서는 노출하지 않음",
        arguments: [
            SystemLanguageModel.Availability.available,
            .unavailable(.modelNotReady),
            .unavailable(.deviceNotEligible)
        ]
    )
    func skipsOtherAvailability(_ availability: SystemLanguageModel.Availability) {
        #expect(!AppleIntelligenceIntroSheet.shouldPresent(
            availability: availability,
            hasBeenShown: false
        ))
    }
}
