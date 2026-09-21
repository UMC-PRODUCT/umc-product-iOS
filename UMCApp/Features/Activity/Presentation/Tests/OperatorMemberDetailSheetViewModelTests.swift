//
//  OperatorMemberDetailSheetViewModelTests.swift
//  ActivityPresentationTests
//
//  Created by jaewon Lee on 6/28/26.
//

import Foundation
import Testing
import ActivityDomain
import UMCFoundation
@testable import ActivityPresentation

#if DEBUG

// MARK: - Helpers

private typealias GrantHandler = @Sendable (ChallengerPointType, Int, String) async -> Bool
private typealias DeleteHandler = @Sendable (OperatorMemberPenaltyHistory) async -> String?

/// 상벌점 히스토리 픽스처. `date` 는 결정론을 위해 epoch 0 고정입니다.
private func makeHistory(
    id: UUID = UUID(),
    challengerPointId: String? = "P-1",
    pointType: ChallengerPointType,
    penaltyScore: Double
) -> OperatorMemberPenaltyHistory {
    OperatorMemberPenaltyHistory(
        id: id,
        challengerPointId: challengerPointId,
        date: Date(timeIntervalSince1970: 0),
        reason: "사유",
        penaltyScore: penaltyScore,
        pointType: pointType
    )
}

private func makeMember(
    penaltyHistory: [OperatorMemberPenaltyHistory]
) -> MemberManagementItem {
    MemberManagementItem(
        profile: nil,
        name: "홍길동",
        nickname: "홍길동",
        generation: "9기",
        school: "한성대",
        position: "",
        part: .front(type: .ios),
        penalty: 0,
        rewardPoints: 0,
        badge: false,
        managementTeam: .challenger,
        attendanceRecords: [],
        penaltyHistory: penaltyHistory
    )
}

@MainActor
private func makeViewModel(
    onGrant: @escaping GrantHandler = { _, _, _ in true },
    onDelete: @escaping DeleteHandler = { _ in nil }
) -> OperatorMemberDetailSheetViewModel {
    OperatorMemberDetailSheetViewModel(onGrantPoint: onGrant, onDeletePoint: onDelete)
}

/// 삭제 콜백 호출 여부를 기록하는 테스트 더블
private final class DeleteRecorder: @unchecked Sendable {
    private(set) var callCount = 0
    func record() { callCount += 1 }
}

// MARK: - syncState

@MainActor
@Suite("OperatorMemberDetailSheetViewModel — 히스토리 동기화 (도메인 규칙)")
struct OperatorMemberDetailSheetViewModelSyncTests {

    @Test("syncState → 히스토리 분류 기준으로 상/벌 합계 집계")
    func syncStateAggregatesFromHistory() {
        let reward = makeHistory(pointType: .bestWorkbook, penaltyScore: 2)
        let penalty = makeHistory(pointType: .studyLate, penaltyScore: 3)
        let viewModel = makeViewModel()

        viewModel.syncState(from: makeMember(penaltyHistory: [reward, penalty]))

        #expect(viewModel.penaltyHistory.count == 2)
        #expect(viewModel.totalReward == 2)
        #expect(viewModel.totalPenalty == 3)
    }

    @Test("빈 히스토리 → 합계 0")
    func syncStateZeroForEmptyHistory() {
        let viewModel = makeViewModel()

        viewModel.syncState(from: makeMember(penaltyHistory: []))

        #expect(viewModel.penaltyHistory.isEmpty)
        #expect(viewModel.totalReward == 0)
        #expect(viewModel.totalPenalty == 0)
    }

    @Test("CUSTOM 부호는 재조회와 삭제 후에도 같은 합계로 유지된다")
    func signedCustomRoundTripAndDelete() async {
        let reward = makeHistory(pointType: .custom, penaltyScore: 3)
        let penalty = makeHistory(pointType: .custom, penaltyScore: -2)
        let viewModel = makeViewModel()
        viewModel.syncState(from: makeMember(penaltyHistory: [reward, penalty]))
        #expect(reward.isReward)
        #expect(!penalty.isReward)
        #expect(penalty.penaltyScore == 2)
        #expect(viewModel.totalReward == 3)
        #expect(viewModel.totalPenalty == 2)
        await viewModel.deletePenalty(reward, canView: true)
        #expect(viewModel.totalReward == 0)
        #expect(viewModel.totalPenalty == 2)
        await viewModel.deletePenalty(penalty, canView: true)
        #expect(viewModel.totalReward == 0)
        #expect(viewModel.totalPenalty == 0)
    }

}

// MARK: - grantPoint

@MainActor
@Suite("OperatorMemberDetailSheetViewModel — 상벌점 부여 (도메인 규칙)")
struct OperatorMemberDetailSheetViewModelGrantTests {

    @Test(
        "부여 성공 → 상/벌 분류(Custom 은 value 부호, 그 외는 pointType.isReward)",
        arguments: [
            (type: ChallengerPointType.bestWorkbook, value: 2, reward: 2.0, penalty: 0.0),
            (type: ChallengerPointType.studyLate, value: -2, reward: 0.0, penalty: 2.0),
            (type: ChallengerPointType.custom, value: 3, reward: 3.0, penalty: 0.0),
            (type: ChallengerPointType.custom, value: -3, reward: 0.0, penalty: 3.0),
        ]
    )
    func grantPointClassifiesRewardAndPenalty(
        type: ChallengerPointType,
        value: Int,
        reward: Double,
        penalty: Double
    ) async {
        let viewModel = makeViewModel(onGrant: { _, _, _ in true })

        let success = await viewModel.grantPoint(type: type, value: value, reason: "사유")

        #expect(success == true)
        #expect(viewModel.penaltyHistory.count == 1)
        #expect(viewModel.totalReward == reward)
        #expect(viewModel.totalPenalty == penalty)
    }

    @Test("부여 실패 → 상태 불변")
    func grantPointFailureKeepsStateUnchanged() async {
        let viewModel = makeViewModel(onGrant: { _, _, _ in false })

        let success = await viewModel.grantPoint(
            type: .bestWorkbook,
            value: 2,
            reason: "잘했어요"
        )

        #expect(success == false)
        #expect(viewModel.penaltyHistory.isEmpty)
        #expect(viewModel.totalReward == 0)
    }
}

// MARK: - deletePenalty

@MainActor
@Suite("OperatorMemberDetailSheetViewModel — 상벌점 삭제 (도메인 규칙)")
struct OperatorMemberDetailSheetViewModelDeleteTests {

    @Test("삭제 성공 → 목록 제거 + 합계 차감")
    func deletePenaltyRemovesAndUpdatesTotals() async {
        let item = makeHistory(pointType: .studyLate, penaltyScore: 3)
        let viewModel = makeViewModel(onDelete: { _ in nil })
        viewModel.syncState(from: makeMember(penaltyHistory: [item]))

        await viewModel.deletePenalty(item, canView: true)

        #expect(viewModel.penaltyHistory.isEmpty)
        #expect(viewModel.totalPenalty == 0)
    }

    @Test("열람 권한 없음 → 아무 작업도 하지 않음")
    func deletePenaltyBlockedWhenCannotView() async {
        let recorder = DeleteRecorder()
        let item = makeHistory(pointType: .studyLate, penaltyScore: 3)
        let viewModel = makeViewModel(onDelete: { _ in
            recorder.record()
            return nil
        })
        viewModel.syncState(from: makeMember(penaltyHistory: [item]))

        await viewModel.deletePenalty(item, canView: false)

        #expect(viewModel.penaltyHistory.count == 1)
        #expect(recorder.callCount == 0)
    }

    @Test("삭제 실패 → 안내 메시지 표시 + 항목 유지")
    func deletePenaltyFailureShowsMessageKeepsItem() async {
        let item = makeHistory(pointType: .studyLate, penaltyScore: 3)
        let viewModel = makeViewModel(onDelete: { _ in "삭제 실패" })
        viewModel.syncState(from: makeMember(penaltyHistory: [item]))

        await viewModel.deletePenalty(item, canView: true)

        #expect(viewModel.transientHistoryMessage == "삭제 실패")
        #expect(viewModel.penaltyHistory.count == 1)
    }
}

#endif
