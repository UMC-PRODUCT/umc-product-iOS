//
//  ReportMemberUseCaseTests.swift
//  CoreDomainTests
//
//  Created by euijjang97 on 11/1/26.
//

import Testing
@testable import CoreDomain

@Suite("사용자 신고 — 입력 검증과 세션 격리")
@MainActor
struct ReportMemberUseCaseTests {
    @Test("잘못된 대상·빈 사유·초과 상세는 전송하지 않는다")
    func rejectsInvalidInput() async {
        let repository = ReportRepositorySpy()
        let useCase = ReportMemberUseCase(repository: repository, currentMemberId: "9")
        for target in ["9", "", "../9", "0", "abc"] {
            await #expect(throws: MemberReportError.self) {
                try await useCase.execute(memberId: target, draft: validDraft)
            }
        }
        for draft in [MemberReportDraft(), MemberReportDraft(reasons: [.other], detail: " \n "),
                      MemberReportDraft(reasons: [.spam], detail: String(repeating: "가", count: 501))] {
            await #expect(throws: MemberReportError.self) {
                try await useCase.execute(memberId: "12", draft: draft)
            }
        }
        #expect(repository.calls.isEmpty)
    }

    @Test("신고 대상과 복수 사유·원문을 전달하고 성공 후 재신고를 막는다")
    func submitsOnce() async throws {
        let repository = ReportRepositorySpy()
        let useCase = ReportMemberUseCase(repository: repository, currentMemberId: "9")
        try await useCase.execute(memberId: "12", draft: validDraft)
        #expect(repository.calls.first?.0 == "12")
        #expect(repository.calls.first?.1 == validDraft)
        await #expect(throws: MemberReportError.alreadyReported) {
            try await useCase.execute(memberId: "12", draft: validDraft)
        }
        #expect(repository.calls.count == 1)
    }

    @Test("실패 후 재시도할 수 있고 세션 초기화 후에는 전송하지 않는다")
    func retriesFailureAndRejectsExpiredSession() async throws {
        let repository = ReportRepositorySpy()
        repository.shouldFail = true
        let useCase = ReportMemberUseCase(repository: repository, currentMemberId: "9")
        await #expect(throws: MemberReportError.self) {
            try await useCase.execute(memberId: "12", draft: validDraft)
        }
        repository.shouldFail = false
        try await useCase.execute(memberId: "12", draft: validDraft)
        useCase.reset()
        await #expect(throws: MemberReportError.unavailableSession) {
            try await useCase.execute(memberId: "13", draft: validDraft)
        }
        #expect(repository.calls.count == 2)
    }

    @Test("로그아웃 후 늦게 완료된 신고는 성공으로 반환하지 않는다")
    func rejectsLateCompletionAfterReset() async {
        let repository = GatedMemberReportRepository()
        let useCase = ReportMemberUseCase(repository: repository, currentMemberId: "9")
        let request = Task {
            await #expect(throws: MemberReportError.unavailableSession) {
                try await useCase.execute(memberId: "12", draft: validDraft)
            }
        }
        await repository.waitUntilStarted()
        await #expect(throws: MemberReportError.busy) {
            try await useCase.execute(memberId: "13", draft: validDraft)
        }
        useCase.reset()
        repository.complete()
        _ = await request.value
    }

    private var validDraft: MemberReportDraft {
        MemberReportDraft(reasons: [.other, .harassment], detail: "  구체적인 신고 내용  ")
    }
}

@MainActor
private final class ReportRepositorySpy: MemberReportRepositoryProtocol {
    var calls: [(String, MemberReportDraft)] = []
    var shouldFail = false
    func report(memberId: String, draft: MemberReportDraft) async throws {
        calls.append((memberId, draft))
        if shouldFail { throw MemberReportError.invalidDraft }
    }
}

@MainActor
private final class GatedMemberReportRepository: MemberReportRepositoryProtocol {
    private var continuation: CheckedContinuation<Void, Never>?
    private var waiter: CheckedContinuation<Void, Never>?

    func report(memberId: String, draft: MemberReportDraft) async throws {
        await withCheckedContinuation {
            continuation = $0
            waiter?.resume()
            waiter = nil
        }
    }

    func waitUntilStarted() async {
        guard continuation == nil else { return }
        await withCheckedContinuation { waiter = $0 }
    }

    func complete() { continuation?.resume(); continuation = nil }
}
