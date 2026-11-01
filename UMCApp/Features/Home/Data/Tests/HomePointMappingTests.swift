//
//  HomePointMappingTests.swift
//  HomeDataTests
//
//  Created by euijjang97 on 11/1/26.
//

import CoreDomain
import HomeDomain
import Testing
@testable import HomeData

@Suite("Home 상벌점 부호 기반 집계")
struct HomePointMappingTests {
    @Test("CUSTOM과 알 수 없는 유형도 서버 점수 부호로 분류한다")
    func classifiesPointsBySign() {
        let generation = makeRecord(points: [
            makePoint(id: "custom-reward", type: "CUSTOM", value: 3),
            makePoint(id: "unknown-reward", type: "NEW_REWARD", value: 2),
            makePoint(id: "custom-penalty", type: "CUSTOM", value: -4),
        ]).toHomeGeneration()

        #expect(generation.rewardPoint == 5)
        #expect(generation.penaltyPoint == 4)
        #expect(generation.totalPoint == 1)
        #expect(generation.pointLogs.first { $0.id == "custom-reward" }?.isReward == true)
        #expect(generation.pointLogs.first { $0.id == "unknown-reward" }?.isReward == true)
        #expect(generation.pointLogs.first { $0.id == "custom-penalty" }?.isReward == false)
    }

    @Test("기존 유형도 유형 기본값 대신 실제 배점의 부호를 따른다")
    func usesRecordedSignForLegacyTypes() {
        let generation = makeRecord(points: [
            makePoint(id: "warning", type: "WARNING", value: 1),
            makePoint(id: "best", type: "BEST_WORKBOOK", value: -0.5),
        ]).toHomeGeneration()

        #expect(generation.rewardPoint == 1)
        #expect(generation.penaltyPoint == 0.5)
        #expect(generation.totalPoint == 0.5)
        #expect(generation.pointLogs.first { $0.id == "warning" }?.isReward == true)
        #expect(generation.pointLogs.first { $0.id == "best" }?.isReward == false)
    }

    @Test("벌점이 더 크면 총점은 음수이며 소수 배점을 유지한다")
    func preservesNegativeTotal() {
        let generation = makeRecord(points: [
            makePoint(id: "reward", type: "CUSTOM", value: 1.5),
            makePoint(id: "penalty", type: "CUSTOM", value: -4),
        ]).toHomeGeneration()

        #expect(generation.totalPoint == -2.5)
        #expect(generation.pointLogs.first { $0.id == "penalty" }?.point == -4)
    }

    @Test("0점은 집계에 영향을 주지 않고 내역을 보존한다")
    func preservesZeroPointRecord() {
        let generation = makeRecord(points: [
            makePoint(id: "zero", type: "CUSTOM", value: 0),
        ]).toHomeGeneration()

        #expect(generation.rewardPoint == 0)
        #expect(generation.penaltyPoint == 0)
        #expect(generation.totalPoint == 0)
        #expect(generation.pointLogs.count == 1)
        #expect(generation.pointLogs.first?.point == 0)
    }

    private func makePoint(id: String, type: String, value: Double) -> ProfileChallengerPoint {
        ProfileChallengerPoint(
            id: id,
            pointType: type,
            point: value,
            description: id,
            createdAt: "2026-11-01T00:00:00Z"
        )
    }

    private func makeRecord(points: [ProfileChallengerPoint]) -> ProfileChallengerRecord {
        ProfileChallengerRecord(
            challengerId: "1", memberId: "1", gisu: "12", gisuId: "12",
            chapterId: nil, chapterName: nil, part: "IOS", schoolId: "1",
            schoolName: "학교", name: nil, nickname: nil, email: nil,
            profileImageLink: nil, status: .active, challengerPoints: points
        )
    }
}
