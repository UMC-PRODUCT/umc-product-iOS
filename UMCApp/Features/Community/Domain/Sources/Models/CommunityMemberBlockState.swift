//
//  CommunityMemberBlockState.swift
//  CommunityDomain
//
//  Created by euijjang97 on 10/30/26.
//

import Foundation
import Observation

/// DI 세션에 귀속되는 개인 차단 상태. 로그아웃 시 DI 캐시와 함께 폐기된다.
@Observable
@MainActor
public final class CommunityMemberBlockState {
    public private(set) var memberIds: Set<String> = []
    public private(set) var isLoaded = false
    public private(set) var revision = 0
    public var isUpdating = false

    public nonisolated init() {}

    /// 인용과 목록 미리보기에는 작성자 ID가 없어 차단 대상 여부를 판정할 수 없다.
    public var hidesUnverifiedPreviews: Bool { !isLoaded || !memberIds.isEmpty }

    public func replace(_ ids: Set<String>, ifRevision expected: Int) {
        guard revision == expected, !isUpdating else { return }
        if memberIds != ids || !isLoaded { revision += 1 }
        memberIds = ids
        isLoaded = true
    }

    public func set(memberId: String, isBlocked: Bool) {
        if isBlocked { memberIds.insert(memberId) } else { memberIds.remove(memberId) }
        revision += 1
    }

    public func displayMessage(_ message: ThreadMessage) -> ThreadMessage {
        var copy = message
        copy.isSenderBlocked = message.isSenderBlocked || memberIds.contains(message.senderId)
        return copy.redactedForBlocking(hideReply: hidesUnverifiedPreviews)
    }
}
