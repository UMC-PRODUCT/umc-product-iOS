//
//  MemberSummaryResponseDTO.swift
//  AuthData
//
//  Created by euijjang97 on 9/19/26.
//

import UMCFoundation

/// 내 종합 정보 조회 응답 DTO
///
/// `GET /api/v2/member/me` (서버 `MemberSummaryV2Response`)
///
/// 비밀번호 등록/변경 분기에 필요한 `hasLocalCredential`만 디코딩한다. 나머지 필드(활동 일수·
/// 기수별 이력 등)는 v1 `/member/me` 대체를 검토할 때 추가한다.
public struct MemberSummaryResponseDTO: Codable, Sendable, Equatable {

    // MARK: - Property

    /// 로컬(이메일/비밀번호) 자격증명 보유 여부
    public let hasLocalCredential: Bool

    private enum CodingKeys: String, CodingKey {
        case hasLocalCredential
    }

    // MARK: - Init

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // 키가 빠지면 기존 동작(#1446 「비밀번호 변경」)을 유지하는 쪽으로 둔다.
        hasLocalCredential = try container.decodeBoolFlexibleIfPresent(
            forKey: .hasLocalCredential
        ) ?? true
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hasLocalCredential, forKey: .hasLocalCredential)
    }
}
