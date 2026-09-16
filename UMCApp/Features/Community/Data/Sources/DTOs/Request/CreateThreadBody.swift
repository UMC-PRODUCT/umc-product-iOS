//
//  CreateThreadBody.swift
//  CommunityData
//
//  Created by euijjang97 on 8/13/26.
//

import Foundation

/// `POST /api/v1/community/threads` 본문.
///
/// 개설자는 서버가 자동으로 `OWNER` 로 넣으므로 `memberIds` 에 넣지 않는다. 서버는 이 필드를
/// `List<Long>` 으로 받고(`@Size(max = 99) @UniqueElements`) 미전달이면 빈 배열로 정규화한다.
public struct CreateThreadBody: Encodable {

    // MARK: - Property

    public let title: String
    public let description: String
    public let category: String
    public let icon: String
    public let memberIds: [Int]

    // MARK: - Init

    /// - Parameter memberIds: 생성과 동시에 초대할 멤버. Domain 은 식별자를 String 으로 들고
    ///   다니므로(핵심 규칙 #2) 전송 직전인 여기서만 Int 로 바꾼다 — 숫자로 바꿀 수 없는 값은
    ///   서버가 모르는 식별자라 보내 봐야 400 이므로 버린다(``InviteMembersBody`` 와 같은 판단).
    public init(
        title: String,
        description: String,
        category: String,
        icon: String,
        memberIds: [String] = []
    ) {
        self.title = title
        self.description = description
        self.category = category
        self.icon = icon
        self.memberIds = memberIds.compactMap(Int.init)
    }
}
