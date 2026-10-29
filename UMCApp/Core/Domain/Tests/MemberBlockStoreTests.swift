//
//  MemberBlockStoreTests.swift
//  CoreDomainTests
//
//  Created by euijjang97 on 10/29/26.
//

import Testing
@testable import CoreDomain

@Suite("회원 차단 — 서버 확정·세션 격리")
@MainActor
struct MemberBlockStoreTests {
    @Test("차단과 해제는 서버 성공 후 기존 메시지의 서버 플래그도 덮어쓴다")
    func blockAndUnblockOverrideOldMessageFlags() async throws {
        let store = MemberBlockStore(repository: BlockRepositoryStub(), currentMemberId: "me")
        try await store.refresh()
        try await store.setBlocked(true, memberId: "other")
        #expect(store.isBlocked("other", serverValue: false))
        try await store.setBlocked(false, memberId: "other")
        #expect(!store.isBlocked("other", serverValue: true))
    }

    @Test("서버 변경 실패는 기존 차단 상태를 유지한다")
    func failedMutationKeepsBlockedState() async throws {
        let repository = BlockRepositoryStub(blocked: ["other"], failsMutation: true)
        let store = MemberBlockStore(repository: repository, currentMemberId: "me")
        try await store.refresh()
        await #expect(throws: MemberSafetyError.self) {
            try await store.setBlocked(false, memberId: "other")
        }
        #expect(store.isBlocked("other"))
        #expect(!store.isUpdating)
    }

    @Test("로그아웃은 이전 계정의 상태와 서버 플래그를 무효화한다")
    func resetInvalidatesSession() async throws {
        let store = MemberBlockStore(repository: BlockRepositoryStub(blocked: ["other"]), currentMemberId: "me")
        try await store.refresh()
        store.reset()
        #expect(!store.isBlocked("other", serverValue: true))
        await #expect(throws: MemberSafetyError.self) {
            try await store.setBlocked(true, memberId: "other")
        }
    }

    @Test("로그아웃 후 완료된 차단 요청은 이전 계정 상태를 되살리지 않는다")
    func lateMutationAfterResetIsDiscarded() async throws {
        let repository = GatedBlockRepository()
        let store = MemberBlockStore(repository: repository, currentMemberId: "me")
        try await store.refresh()
        let request = Task { try await store.setBlocked(true, memberId: "other") }
        await repository.waitUntilStarted()
        store.reset()
        await repository.release()
        try await request.value
        #expect(store.blockedMemberIds.isEmpty)
        #expect(!store.isUpdating)
        #expect(!store.isBlocked("other", serverValue: true))
    }

    @Test("자기 자신은 차단할 수 없다")
    func selfBlockRejected() async {
        let store = MemberBlockStore(repository: BlockRepositoryStub(), currentMemberId: "me")
        await #expect(throws: MemberSafetyError.self) {
            try await store.setBlocked(true, memberId: "me")
        }
    }

    @Test("사용자 신고는 복수 사유를 허용하고 공백 상세를 거절한다")
    func validatesReportDraft() {
        #expect(!MemberReportDraft(reasons: [], detail: "내용").isValid)
        #expect(!MemberReportDraft(reasons: [.other], detail: " \n ").isValid)
        #expect(MemberReportDraft(reasons: [.harassment, .spam], detail: "내용").isValid)
    }
}

private actor BlockRepositoryStub: MemberBlockRepositoryProtocol {
    private var blocked: Set<String>
    private let failsMutation: Bool

    init(blocked: Set<String> = [], failsMutation: Bool = false) {
        self.blocked = blocked
        self.failsMutation = failsMutation
    }

    func fetchBlockedMemberIds() async throws -> Set<String> { blocked }
    func setBlocked(_ value: Bool, memberId: String) async throws -> Bool {
        if failsMutation { throw MemberSafetyError.busy }
        if value { blocked.insert(memberId) } else { blocked.remove(memberId) }
        return value
    }
}

private actor GatedBlockRepository: MemberBlockRepositoryProtocol {
    private var gate: CheckedContinuation<Bool, Never>?
    private var waiter: CheckedContinuation<Void, Never>?
    private var hasStarted = false
    func fetchBlockedMemberIds() async throws -> Set<String> { [] }
    func setBlocked(_ blocked: Bool, memberId: String) async throws -> Bool {
        hasStarted = true
        waiter?.resume()
        waiter = nil
        return await withCheckedContinuation { gate = $0 }
    }
    func waitUntilStarted() async {
        guard !hasStarted else { return }
        await withCheckedContinuation { waiter = $0 }
    }
    func release() {
        gate?.resume(returning: true)
        gate = nil
    }
}
