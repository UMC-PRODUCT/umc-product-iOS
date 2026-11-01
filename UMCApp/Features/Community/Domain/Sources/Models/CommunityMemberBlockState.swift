//
//  CommunityMemberBlockState.swift
//  CommunityDomain
//
//  Created by euijjang97 on 10/30/26.
//

import CoreDomain
import Foundation
import Observation

/// DI 세션에 귀속되는 개인 차단 상태. 로그아웃 시 DI 캐시와 함께 폐기된다.
@Observable
@MainActor
public final class CommunityMemberBlockState {
    private var localMemberIds: Set<String> = []
    private var localIsLoaded = false
    private var localRevision = 0
    private var localIsUpdating = false
    public let store: MemberBlockStore?

    public var memberIds: Set<String> { store?.blockedMemberIds ?? localMemberIds }
    public var isLoaded: Bool { store?.hasLoaded ?? localIsLoaded }
    public var revision: Int { store?.stateRevision ?? localRevision }
    public var isUpdating: Bool { store?.isUpdating ?? localIsUpdating }

    public nonisolated init(store: MemberBlockStore? = nil) { self.store = store }

    /// 앱에서는 프로필과 같은 저장소를 사용하고 독립 사용 시에는 주입된 조회를 쓴다.
    public func refresh(fetch: () async throws -> Set<String>) async throws {
        if let store {
            try await store.refresh()
        } else {
            let expected = revision
            let ids = try await fetch()
            replace(ids, ifRevision: expected)
        }
    }

    public func update(
        memberId: String,
        isBlocked: Bool,
        perform: () async throws -> Bool
    ) async throws -> Bool {
        if let store {
            try await store.setBlocked(isBlocked, memberId: memberId)
            return store.isBlocked(memberId)
        }
        guard !localIsUpdating else { throw MemberSafetyError.busy }
        localIsUpdating = true
        defer { localIsUpdating = false }
        let result = try await perform()
        set(memberId: memberId, isBlocked: result)
        return result
    }

    /// 인용과 목록 미리보기에는 작성자 ID가 없어 차단 대상 여부를 판정할 수 없다.
    public var hidesUnverifiedPreviews: Bool { !isLoaded || !memberIds.isEmpty }

    public func replace(_ ids: Set<String>, ifRevision expected: Int) {
        guard store == nil, revision == expected, !isUpdating else { return }
        if memberIds != ids || !isLoaded { localRevision += 1 }
        localMemberIds = ids
        localIsLoaded = true
    }

    public func set(memberId: String, isBlocked: Bool) {
        guard store == nil else { return }
        if isBlocked { localMemberIds.insert(memberId) } else { localMemberIds.remove(memberId) }
        localRevision += 1
    }

    public func displayMessage(_ message: ThreadMessage) -> ThreadMessage {
        var copy = message
        copy.isSenderBlocked = message.isSenderBlocked || memberIds.contains(message.senderId)
        return copy.redactedForBlocking(hideReply: hidesUnverifiedPreviews)
    }
}
