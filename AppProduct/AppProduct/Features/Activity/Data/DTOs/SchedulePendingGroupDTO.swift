//
//  SchedulePendingGroupDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 3/12/26.
//

import Foundation

/// 일괄 조회 응답의 스케줄별 그룹 wrapper DTO
///
/// `GET /api/v1/attendances/pending` 응답 구조:
/// ```json
/// [
///   {
///     "scheduleId": 30,
///     "scheduleName": "1주차 세션",
///     "pendingAttendances": [ ... PendingAttendanceDTO ... ]
///   }
/// ]
/// ```
///
/// - Note: `scheduleId`는 서버에서 Int 또는 String으로 반환될 수 있음.
///   `MemberOAuthDTO`와 동일한 flexible decoding 패턴 적용.
struct SchedulePendingGroupDTO: Codable, Sendable, Equatable {

    // MARK: - Property

    let scheduleId: Int
    let scheduleName: String
    let pendingAttendances: [PendingAttendanceDTO]

    // MARK: - CodingKeys

    private enum CodingKeys: String, CodingKey {
        case scheduleId
        case scheduleName
        case pendingAttendances
    }

    // MARK: - Init

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        scheduleId = try Self.decodeFlexibleInt(
            from: container,
            forKey: .scheduleId
        )
        scheduleName = try container.decode(
            String.self,
            forKey: .scheduleName
        )
        pendingAttendances = try container.decode(
            [PendingAttendanceDTO].self,
            forKey: .pendingAttendances
        )
    }

    /// Int 또는 숫자 String을 Int로 디코딩
    ///
    /// 서버가 숫자를 Int 또는 String으로 반환할 수 있는
    /// 불일치를 안전하게 처리합니다.
    /// 참고: `MemberOAuthDTO.decodeFlexibleInt`
    private static func decodeFlexibleInt(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Int {
        if let intValue = try? container.decode(
            Int.self, forKey: key
        ) {
            return intValue
        }

        if let stringValue = try? container.decode(
            String.self, forKey: key
        ),
           let intValue = Int(stringValue) {
            return intValue
        }

        throw DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(
                codingPath: container.codingPath + [key],
                debugDescription: """
                    \(key.stringValue)는 \
                    Int 또는 숫자 문자열이어야 합니다.
                    """
            )
        )
    }
}

// MARK: - toDomain

extension SchedulePendingGroupDTO {

    /// DTO 그룹 -> (scheduleId, [PendingAttendanceRecord]) 튜플 변환
    ///
    /// 내부 pendingAttendances를
    /// 기존 PendingAttendanceDTO.toDomain()으로 domain 변환합니다.
    func toDomainEntry() -> (Int, [PendingAttendanceRecord]) {
        let records = pendingAttendances.map { $0.toDomain() }
        return (scheduleId, records)
    }
}

