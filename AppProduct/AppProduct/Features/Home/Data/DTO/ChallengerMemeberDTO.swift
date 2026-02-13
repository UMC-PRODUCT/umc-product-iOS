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
    /// 소속 파트 (API 문자열: "PLAN", "IOS" 등)
    let part: String
    /// 포인트 상세 목록 (패널티 + 우수 포인트 포함)
    let challengerPoints: [ChallengerPointDTO]
    /// 이름
    let name: String
    /// 닉네임
    let nickname: String
    /// 이메일
    let email: String
    /// 학교 ID
    let schoolId: Int
    /// 학교 이름
    let schoolName: String
    /// 프로필 이미지 URL
    let profileImageLink: String
    /// 멤버 상태 (ACTIVE / INACTIVE / WITHDRAWN)
    let status: MemberStatus
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
