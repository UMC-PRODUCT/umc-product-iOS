//
//  ThreadMemberPageQuery.swift
//  CommunityData
//
//  Created by euijjang97 on 9/18/26.
//

import Foundation

/// `GET /threads/{threadId}/members`·`GET /threads/{threadId}/invitable` 쿼리 파라미터.
///
/// 두 엔드포인트 모두 서버 기본값이 `offset=0`, `limit=20` 이다. 쿼리를 빼면 처음 20명만 온다.
public struct ThreadMemberPageQuery: Encodable {

    // MARK: - Property

    public let offset: Int
    public let limit: Int

    // MARK: - Init

    public init(offset: Int, limit: Int) {
        self.offset = offset
        self.limit = limit
    }

    // MARK: - Computed Property

    public var toParameters: [String: Any] {
        ["offset": offset, "limit": limit]
    }
}
