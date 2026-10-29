//
//  MemberBlockStore.swift
//  CoreDomain
//
//  Created by euijjang97 on 10/29/26.
//

import Foundation
import Observation

/// 회원 차단은 스레드 멤버십과 독립적인, 현재 계정 소유의 관계다.
public protocol MemberBlockRepositoryProtocol: Sendable {
    func fetchBlockedMemberIds() async throws -> Set<String>
    func setBlocked(_ blocked: Bool, memberId: String) async throws -> Bool
}

public enum MemberSafetyError: LocalizedError {
    case unavailableSession, invalidTarget, busy

    public var errorDescription: String? {
        switch self {
        case .unavailableSession: "로그인 후 다시 시도해 주세요."
        case .invalidTarget: "자기 자신은 차단할 수 없어요."
        case .busy: "처리 중입니다. 잠시 후 다시 시도해 주세요."
        }
    }
}

/// 프로필과 모든 채팅방이 공유하는 세션 단위 차단 상태.
/// 서버 성공 후에만 반영하며 reset 이후 도착한 이전 계정 응답은 버린다.
@MainActor @Observable
public final class MemberBlockStore {
    public let currentMemberId: String?
    public private(set) var blockedMemberIds: Set<String> = []
    public private(set) var isUpdating = false
    public private(set) var hasLoaded = false
    @ObservationIgnored private let repository: MemberBlockRepositoryProtocol
    private var isActive = true
    @ObservationIgnored private var revision = UUID()

    public nonisolated init(repository: MemberBlockRepositoryProtocol, currentMemberId: String?) {
        self.repository = repository
        self.currentMemberId = currentMemberId
    }

    public func isBlocked(_ memberId: String, serverValue: Bool = false) -> Bool {
        guard isActive, currentMemberId != nil, memberId != currentMemberId else { return false }
        return hasLoaded ? blockedMemberIds.contains(memberId) : serverValue
    }

    public func refresh() async throws {
        guard isActive, currentMemberId != nil else { throw MemberSafetyError.unavailableSession }
        guard !isUpdating else { return }
        let requestRevision = revision
        let ids = try await repository.fetchBlockedMemberIds()
        guard isActive, revision == requestRevision else { return }
        blockedMemberIds = ids
        hasLoaded = true
    }

    public func setBlocked(_ blocked: Bool, memberId: String) async throws {
        guard isActive, currentMemberId != nil else { throw MemberSafetyError.unavailableSession }
        guard memberId != currentMemberId, !memberId.isEmpty else {
            throw MemberSafetyError.invalidTarget
        }
        guard !isUpdating else { throw MemberSafetyError.busy }
        isUpdating = true
        revision = UUID()
        let requestRevision = revision
        defer { if revision == requestRevision { isUpdating = false } }
        let result = try await repository.setBlocked(blocked, memberId: memberId)
        guard isActive, revision == requestRevision else { return }
        if result { blockedMemberIds.insert(memberId) } else { blockedMemberIds.remove(memberId) }
        // 프로필에서는 목록 조회 성공 후에만 변경을 허용한다.
    }

    public func reset() {
        revision = UUID()
        isActive = false
        blockedMemberIds = []
        hasLoaded = false
        isUpdating = false
    }
}
