//
//  EditMessageBody.swift
//  CommunityData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation

/// `/app/community/threads/{id}/messages/{messageId}/edit` 본문.
///
/// 서버가 `@JsonAnySetter` 로 모르는 필드를 거절하므로 `content` 외에는 싣지 않는다.
public struct EditMessageBody: Encodable {

    // MARK: - Property

    public let content: String

    // MARK: - Init

    public init(content: String) {
        self.content = content
    }
}
