//
//  NoticeListRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/11/26.
//

import Foundation

/// 홈 화면 최근 공지 Request DTO
struct NoticeListRequestDTO {
    /// 기수 ID (필수)
    let gisuId: Int
    /// 지부 ID (null이면 해당 기수의 전체 공지 조회)
    let chapterId: Int?
    /// 학교 ID (null이면 지부 레벨까지만 필터링)
    let schoolId: Int?
    /// 파트 (null이면 파트 구분 없이 조회)
    let part: UMCPartType?
    /// 페이지 번호 (0부터 시작)
    let page: Int
    /// 페이지 크기
    let size: Int
    /// 정렬 기준
    let sort: [String]

    init(
        gisuId: Int,
        chapterId: Int? = nil,
        schoolId: Int? = nil,
        part: UMCPartType? = nil,
        page: Int = 0,
        size: Int = 10,
        sort: [String] = ["createdAt,DESC"]
    ) {
        self.gisuId = gisuId
        self.chapterId = chapterId
        self.schoolId = schoolId
        self.part = part
        self.page = page
        self.size = size
        self.sort = sort
    }

    /// Query Parameter Dictionary 변환
    var queryItems: [String: Any] {
        var params: [String: Any] = [
            "gisuId": gisuId,
            "page": page,
            "size": size
        ]
        if !sort.isEmpty {
            params["sort"] = sort
        }
        if let chapterId { params["chapterId"] = chapterId }
        if let schoolId { params["schoolId"] = schoolId }
        if let part { params["part"] = part.apiValue }
        return params
    }
}

/// 홈 화면 최근 공지 Response DTO
struct NoticeListResponseDTO: Codable {
    let id: String
    let title: String
    let content: String
    let shouldSendNotification: Bool
    let viewCount: String
    let createdAt: String
    /// 서버 응답은 targetInfo를 단일 객체로 내려줍니다.
    let targetInfo: TargetInfoDTO
    let authorChallengerId: String
    let authorNickname: String
    let authorName: String

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case shouldSendNotification
        case viewCount
        case createdAt
        case targetInfo
        case authorChallengerId
        case authorNickname
        case authorName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeStringFlexible(forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.shouldSendNotification = try container.decode(Bool.self, forKey: .shouldSendNotification)
        self.viewCount = try container.decodeStringFlexible(forKey: .viewCount)
        self.createdAt = try container.decode(String.self, forKey: .createdAt)
        self.targetInfo = try container.decode(TargetInfoDTO.self, forKey: .targetInfo)
        self.authorChallengerId = try container.decodeStringFlexible(forKey: .authorChallengerId)
        self.authorNickname = try container.decode(String.self, forKey: .authorNickname)
        self.authorName = try container.decode(String.self, forKey: .authorName)
    }
}

// MARK: - toDomain

extension NoticeListResponseDTO {
    /// DTO → RecentNoticeData 변환
    func toRecentNoticeData() -> RecentNoticeData {
        let category: RecentCategory
        if targetInfo.targetSchoolId != nil {
            category = .univ
        } else if targetInfo.targetChapterId != nil {
            category = .oranization
        } else {
            category = .operationsTeam
        }

        let date = createdAt.toISO8601Date()

        return RecentNoticeData(
            category: category,
            title: title,
            createdAt: date
        )
    }
}

// MARK: - TargetInfoDTO

struct TargetInfoDTO: Codable {
    let targetGisuId: Int
    let targetChapterId: Int?
    let targetSchoolId: Int?
    let targetParts: [UMCPartType]?

    private enum CodingKeys: String, CodingKey {
        case targetGisuId
        case targetChapterId
        case targetSchoolId
        case targetParts
    }

    init(
        targetGisuId: Int,
        targetChapterId: Int?,
        targetSchoolId: Int?,
        targetParts: UMCPartType?
    ) {
        self.targetGisuId = targetGisuId
        self.targetChapterId = targetChapterId
        self.targetSchoolId = targetSchoolId
        self.targetParts = targetParts.map { [$0] }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.targetGisuId = try container.decodeIntFlexible(forKey: .targetGisuId)
        self.targetChapterId = try container.decodeIntFlexibleIfPresent(forKey: .targetChapterId)
        self.targetSchoolId = try container.decodeIntFlexibleIfPresent(forKey: .targetSchoolId)
        self.targetParts = try container.decodeIfPresent([UMCPartType].self, forKey: .targetParts)
    }
}

// MARK: - PageDTO

/// Spring Boot Pageable 공통 응답 DTO (Offset 기반)
struct PageDTO<T: Codable>: Codable {
    /// 현재 페이지 항목 목록
    let content: [T]
    /// 현재 페이지 번호 (0부터 시작)
    let page: Int
    /// 한 페이지 항목 수
    let size: Int
    /// 전체 항목 수
    let totalElements: Int
    /// 전체 페이지 수
    let totalPages: Int
    /// 다음 페이지 존재 여부
    let hasNext: Bool
    /// 이전 페이지 존재 여부
    let hasPrevious: Bool
}

private extension KeyedDecodingContainer {
    func decodeStringFlexible(forKey key: Key) throws -> String {
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(Int(value))
        }
        throw DecodingError.typeMismatch(
            String.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected String/Int/Double for key '\(key.stringValue)'"
            )
        )
    }

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
        return try decodeIntFlexible(forKey: key)
    }
}

private extension String {
    func toISO8601Date() -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsed = formatter.date(from: self) {
            return parsed
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: self) ?? Date()
    }
}
