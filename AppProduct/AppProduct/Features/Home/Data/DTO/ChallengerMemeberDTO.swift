//
//  ChallengerMemeberDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/11/26.
//

import Foundation

/// 현재 기수 패널티 조회 Response DTO
///
/// `GET /api/v1/challenger/{id}`
struct ChallengerMemberDTO: Codable {

    // MARK: - Property

    /// 챌린저 고유 ID
    let challengerId: Int
    /// 멤버 고유 ID
    let memberId: Int
    /// 기수 번호 (예: 9, 10)
    let gisu: Int
    /// 서버 기수 식별 ID
    let gisuId: Int
    /// 지부 ID
    let chapterId: Int?
    /// 지부명
    let chapterName: String?
    /// 소속 파트 (API 문자열: "PLAN", "IOS" 등)
    let part: String
    /// 포인트 상세 목록 (패널티 + 우수 포인트 포함)
    let challengerPoints: [ChallengerPointDTO]
    /// 이름
    let name: String
    /// 닉네임
    let nickname: String
    /// 이메일
    let email: String?
    /// 학교 ID
    let schoolId: Int
    /// 학교 이름
    let schoolName: String
    /// 프로필 이미지 URL
    let profileImageLink: String?
    /// 멤버 상태 (ACTIVE / INACTIVE / WITHDRAWN)
    let status: MemberStatus

    private enum CodingKeys: String, CodingKey {
        case challengerId
        case memberId
        case gisu
        case gisuId
        case chapterId
        case chapterName
        case part
        case challengerPoints
        case name
        case nickname
        case email
        case schoolId
        case schoolName
        case profileImageLink
        case status
    }

    private enum FallbackCodingKeys: String, CodingKey {
        case memberStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challengerId = try container.decodeIntFlexibleIfPresent(forKey: .challengerId) ?? 0
        memberId = try container.decodeIntFlexibleIfPresent(forKey: .memberId) ?? 0
        gisu = try container.decodeIntFlexibleIfPresent(forKey: .gisu) ?? 0
        gisuId = try container.decodeIntFlexibleIfPresent(forKey: .gisuId) ?? 0
        chapterId = try container.decodeIntFlexibleIfPresent(forKey: .chapterId)
        chapterName = try container.decodeIfPresent(String.self, forKey: .chapterName)
        part = try container.decodeIfPresent(String.self, forKey: .part) ?? ""
        challengerPoints = try container.decodeIfPresent([ChallengerPointDTO].self, forKey: .challengerPoints)
            ?? decoder.decodePointsArrayFallback()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email)
        schoolId = try container.decodeIntFlexibleIfPresent(forKey: .schoolId) ?? 0
        schoolName = try container.decodeIfPresent(String.self, forKey: .schoolName) ?? ""
        profileImageLink = try container.decodeIfPresent(String.self, forKey: .profileImageLink)
        let fallbackContainer = try decoder.container(keyedBy: FallbackCodingKeys.self)
        status = try container.decodeIfPresent(MemberStatus.self, forKey: .status)
            ?? (try fallbackContainer.decodeIfPresent(MemberStatus.self, forKey: .memberStatus))
            ?? .inactive
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

private extension Decoder {
    func decodePointsArrayFallback() throws -> [ChallengerPointDTO] {
        let container = try self.container(keyedBy: DynamicCodingKey.self)
        guard let key = DynamicCodingKey(stringValue: "points") else {
            return []
        }
        return try container.decodeIfPresent([ChallengerPointDTO].self, forKey: key) ?? []
    }
}

// MARK: - ChallengerPointDTO

/// 포인트 상세 항목 DTO
struct ChallengerPointDTO: Codable {
    /// 포인트 고유 ID
    let id: Int
    /// 포인트 유형 (BEST_WORKBOOK / WARNING / OUT)
    let pointType: PointType
    /// 부여된 포인트 값
    let point: Double
    /// 사유 설명
    let description: String
    /// 생성 시각 (ISO 8601 형식)
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case pointType
        case point
        case description
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntFlexibleIfPresent(forKey: .id) ?? 0
        pointType = try container.decodeIfPresent(PointType.self, forKey: .pointType) ?? .warning
        if let pointValue = try? container.decode(Double.self, forKey: .point) {
            point = pointValue
        } else if let intValue = try? container.decode(Int.self, forKey: .point) {
            point = Double(intValue)
        } else {
            let stringValue = try container.decodeIfPresent(String.self, forKey: .point) ?? "0"
            guard let parsed = Double(stringValue) else {
                throw DecodingError.typeMismatch(
                    Double.self,
                    DecodingError.Context(
                        codingPath: container.codingPath + [CodingKeys.point],
                        debugDescription: "Expected Double or String-number for key 'point'"
                    )
                )
            }
            point = parsed
        }
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
    }
}

// MARK: - PointType

/// 포인트 유형 열거형
enum PointType: String, Codable {
    /// 우수 워크북 포인트
    case bestWorkbook = "BEST_WORKBOOK"
    /// 경고 패널티
    case warning = "WARNING"
    /// 퇴출 패널티
    case out = "OUT"
}

private extension KeyedDecodingContainer {
    func decodeIntFlexible(forKey key: Key) throws -> Int {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key),
           let intValue = Int(value) {
            return intValue
        }
        if let value = try? decode(Double.self, forKey: key) {
            return Int(value)
        }
        throw DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected Int/String-number/Double for key '\(key.stringValue)'"
            )
        )
    }

    func decodeIntFlexibleIfPresent(forKey key: Key) throws -> Int? {
        if (try? decodeNil(forKey: key)) == true {
            return nil
        }
        return try? decodeIntFlexible(forKey: key)
    }
}

// MARK: - toDomain

extension ChallengerMemberDTO {
    /// DTO → GenerationData 변환 (홈 화면 패널티 카드용)
    ///
    /// - Parameter gisuId: MyProfileDTO의 RoleDTO에서 전달받은 기수 식별 ID
    /// - Returns: 패널티만 필터링된 `GenerationData`
    ///
    /// - Note: `bestWorkbook` 포인트는 제외하고 `warning`, `out`만 포함합니다.
    func toGenerationData(gisuId: Int) -> GenerationData {
        // 패널티 유형(warning, out)만 필터링
        let penaltyPoints = challengerPoints.filter {
            $0.pointType == .warning || $0.pointType == .out
        }

        // ISO 8601 → yyyy.MM.dd 표시 형식 변환
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy.MM.dd"

        let logs = penaltyPoints.map { point in
            let dateString: String
            if let date = formatter.date(from: point.createdAt) {
                dateString = displayFormatter.string(from: date)
            } else {
                dateString = point.createdAt
            }
            return PenaltyInfoItem(
                reason: point.description,
                date: dateString,
                penaltyPoint: Int(point.point)
            )
        }

        let total = penaltyPoints.reduce(0) { $0 + Int($1.point) }

        return GenerationData(
            gisuId: gisuId,
            gen: gisu,
            penaltyPoint: total,
            penaltyLogs: logs
        )
    }
}
