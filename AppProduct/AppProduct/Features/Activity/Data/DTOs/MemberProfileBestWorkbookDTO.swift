//
//  MemberProfileBestWorkbookDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/24/26.
//

import Foundation

/// 멤버 프로필 응답에서 베스트 워크북 점수 계산에 필요한 최소 DTO
///
/// `GET /api/v1/member/profile/{memberId}`
struct MemberProfileBestWorkbookDTO: Codable, Sendable, Equatable {
    let challengerRecords: [MemberBestWorkbookRecordDTO]

    private enum CodingKeys: String, CodingKey {
        case challengerRecords
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challengerRecords = try container.decodeIfPresent(
            [MemberBestWorkbookRecordDTO].self,
            forKey: .challengerRecords
        ) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(challengerRecords, forKey: .challengerRecords)
    }
}

/// 챌린저 레코드 내 워크북 포인트 정보 DTO
///
/// `challengerPoints`를 우선으로 사용하고, 비어 있으면 `points`(fallback)를 사용합니다.
struct MemberBestWorkbookRecordDTO: Codable, Sendable, Equatable {
    let challengerPoints: [MemberBestWorkbookPointDTO]
    let fallbackPoints: [MemberBestWorkbookPointDTO]

    private enum CodingKeys: String, CodingKey {
        case challengerPoints
        case points
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challengerPoints = try container.decodeIfPresent(
            [MemberBestWorkbookPointDTO].self,
            forKey: .challengerPoints
        ) ?? []
        fallbackPoints = try container.decodeIfPresent(
            [MemberBestWorkbookPointDTO].self,
            forKey: .points
        ) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(challengerPoints, forKey: .challengerPoints)
        try container.encode(fallbackPoints, forKey: .points)
    }

    /// 챌린저 포인트 우선 사용, 없으면 points fallback 사용
    var resolvedPoints: [MemberBestWorkbookPointDTO] {
        challengerPoints.isEmpty ? fallbackPoints : challengerPoints
    }
}

/// 워크북 단일 포인트 항목 DTO
///
/// 포인트 타입(예: `BEST_WORKBOOK`)과 점수를 포함합니다.
struct MemberBestWorkbookPointDTO: Codable, Sendable, Equatable {
    let pointType: String
    let point: Double

    private enum CodingKeys: String, CodingKey {
        case pointType
        case point
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pointType = try container.decodeIfPresent(String.self, forKey: .pointType) ?? ""
        point = try container.decodeDoubleFlexibleIfPresent(forKey: .point) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pointType, forKey: .pointType)
        try container.encode(point, forKey: .point)
    }
}

extension MemberProfileBestWorkbookDTO {
    /// BEST_WORKBOOK 포인트 합계를 화면용 +점수(Int)로 변환합니다.
    ///
    /// 서버 포인트가 `-0.5` 단위이므로 절대값 합계에 10을 곱해 표시 점수로 사용합니다.
    var bestWorkbookDisplayPoint: Int {
        let totalBestPoint = challengerRecords
            .flatMap(\.resolvedPoints)
            .filter { $0.pointType.uppercased() == "BEST_WORKBOOK" }
            .reduce(0.0) { partial, item in
                partial + item.point
            }

        return Int((abs(totalBestPoint) * 10).rounded())
    }
}

private extension KeyedDecodingContainer {
    /// Double, Int, String 형태로 인코딩된 값을 Double로 유연하게 디코딩합니다.
    ///
    /// 서버 응답 포맷이 타입 일관성을 보장하지 않을 때 사용합니다.
    /// - Parameter key: 디코딩할 CodingKey
    /// - Returns: 디코딩 성공 시 Double, 키가 없거나 변환 불가 시 nil
    func decodeDoubleFlexibleIfPresent(forKey key: Key) throws -> Double? {
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return Double(value)
        }
        if let value = try? decode(String.self, forKey: key),
           let doubleValue = Double(value) {
            return doubleValue
        }
        return nil
    }
}
