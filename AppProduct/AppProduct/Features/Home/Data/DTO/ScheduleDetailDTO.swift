//
//  ScheduleDetailDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/13/26.
//

import Foundation

/// 일정 상세 조회 API 응답 DTO
///
/// 서버에서 반환하는 일정 상세 정보를 매핑합니다.
/// `toScheduleDetailData()`를 통해 Domain 모델로 변환합니다.
///
/// - SeeAlso: ``ScheduleDetailData``
struct ScheduleDetailDTO: Codable, Sendable, Equatable {
    /// 일정 고유 식별자
    let scheduleId: Int
    /// 일정 제목
    let name: String
    /// 일정 설명 (메모)
    let description: String
    /// 카테고리 태그 목록 (예: ["스터디", "프로젝트"])
    let tags: [String]
    /// 시작 일시 (ISO 8601 문자열)
    let startsAt: String
    /// 종료 일시 (ISO 8601 문자열)
    let endsAt: String
    /// 하루 종일 일정 여부
    let isAllDay: Bool
    /// 장소명
    let locationName: String
    /// 장소 위도
    let latitude: Double
    /// 장소 경도
    let longitude: Double
    /// 참여 상태 (예: "참여 예정")
    let status: String
    /// D-Day 값 (음수: 미래, 양수: 과거)
    let dDay: Int
    /// 출석 승인 필요 여부
    let requiresAttendanceApproval: Bool
}

// MARK: - toDomain

extension ScheduleDetailDTO {

    /// DTO → ScheduleDetailData 변환
    func toScheduleDetailData() -> ScheduleDetailData {
        let startsDate = Self.parseISO8601(startsAt)
        let endsDate = Self.parseISO8601(endsAt)
        return ScheduleDetailData(
            scheduleId: scheduleId,
            name: name,
            description: description,
            tags: tags,
            startsAt: startsDate,
            endsAt: endsDate,
            isAllDay: isAllDay,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            status: status,
            dDay: dDay,
            requiresAttendanceApproval: requiresAttendanceApproval
        )
    }

    /// ISO 8601 문자열 → Date 변환 (fractionalSeconds 우선 시도)
    private static func parseISO8601(_ string: String) -> Date {
        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [
            .withInternetDateTime, .withFractionalSeconds
        ]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        return formatterWithFraction.date(from: string)
            ?? formatter.date(from: string)
            ?? .now
    }
}
