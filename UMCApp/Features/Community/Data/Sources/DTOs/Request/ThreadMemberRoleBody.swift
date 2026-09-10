//
//  ThreadMemberRoleBody.swift
//  CommunityData
//
//  Created by euijjang97 on 8/13/26.
//

import Foundation

/// `PATCH /threads/{threadId}/members/{memberId}/role` 본문.
///
/// 값이 하나뿐이어도 Router 에 인라인 딕셔너리를 두지 않는다(핵심 규칙 #6).
public struct ThreadMemberRoleBody: Encodable {

    // MARK: - Property

    /// ``CommunityDomain/ThreadMemberRole`` 의 rawValue.
    public let role: String

    // MARK: - Init

    public init(role: String) {
        self.role = role
    }
}
