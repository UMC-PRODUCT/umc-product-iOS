//
//  ThreadInviteViewModelTests.swift
//  CommunityPresentationTests
//
//  Created by euijjang97 on 8/13/26.
//

import Foundation
import Testing
import CommunityDomain
import CoreDomain
import UMCFoundation
@testable import CommunityPresentation

// MARK: - Test Double

/// 초대 호출을 기록하고 필요하면 실패시키는 UseCase 대역.
@MainActor
private final class StubInviteUseCase: CommunityThreadInviteUseCaseProtocol {

    var shouldFailInvite = false

    private(set) var inviteCalls: [[String]] = []

    func loadCandidates(threadId: String) async throws -> ThreadInviteCandidates {
        ThreadInviteCandidates(candidates: [], remainingSlots: nil)
    }

    func invite(threadId: String, memberIds: [String]) async throws {
        inviteCalls.append(memberIds)
        if shouldFailInvite { throw AppError.unknown(message: "실패") }
    }
}

private func makeChallenger(memberId: String) -> ChallengerInfo {
    ChallengerInfo(
        memberId: memberId,
        gen: "6",
        name: "챌린저\(memberId)",
        nickname: "닉\(memberId)",
        schoolName: "인하대학교",
        profileImage: nil,
        part: .front(type: .ios)
    )
}

// MARK: - Tests

@Suite("ThreadInviteViewModel")
@MainActor
struct ThreadInviteViewModelTests {

    @Test("고른 memberId 로 초대하고 인원 수를 돌려준 뒤 선택을 비운다")
    func invitesSelectedMembers() async {
        let useCase = StubInviteUseCase()
        let viewModel = ThreadInviteViewModel(threadId: "1", useCase: useCase)
        viewModel.invitees = [makeChallenger(memberId: "11"), makeChallenger(memberId: "12")]

        let invitedCount = await viewModel.invite()

        #expect(invitedCount == 2)
        #expect(useCase.inviteCalls.first?.sorted() == ["11", "12"])
        #expect(viewModel.invitees.isEmpty)
    }

    @Test("같은 사람이 두 번 실려도 한 번만 보낸다")
    func deduplicatesMemberIds() async {
        let useCase = StubInviteUseCase()
        let viewModel = ThreadInviteViewModel(threadId: "1", useCase: useCase)
        viewModel.invitees = [makeChallenger(memberId: "11"), makeChallenger(memberId: "11")]

        let invitedCount = await viewModel.invite()

        #expect(invitedCount == 1)
        #expect(useCase.inviteCalls.first == ["11"])
    }

    @Test("초대에 실패하면 사유를 알리고 선택은 그대로 남긴다")
    func keepsSelectionWhenInviteFails() async {
        let useCase = StubInviteUseCase()
        useCase.shouldFailInvite = true
        let viewModel = ThreadInviteViewModel(threadId: "1", useCase: useCase)
        viewModel.invitees = [makeChallenger(memberId: "11")]

        let invitedCount = await viewModel.invite()

        #expect(invitedCount == nil)
        #expect(viewModel.alertPrompt != nil)
        #expect(viewModel.invitees.map(\.memberId) == ["11"])
    }

    @Test("아무도 고르지 않고 닫으면 요청을 보내지 않는다")
    func skipsEmptyInvite() async {
        let useCase = StubInviteUseCase()
        let viewModel = ThreadInviteViewModel(threadId: "1", useCase: useCase)

        let invitedCount = await viewModel.invite()

        #expect(invitedCount == nil)
        #expect(useCase.inviteCalls.isEmpty)
    }
}
