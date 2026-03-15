//
//  CurriculumProgressDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation

/// 내 커리큘럼 진행 상황 응답 DTO
///
/// `GET /api/v1/curriculums/challengers/me/progress`
struct ChallengerCurriculumProgressDTO: Codable, Sendable, Equatable {
    let curriculumId: String
    let curriculumTitle: String
    let part: String
    let completedCount: String
    let totalCount: String
    let workbooks: [ChallengerWorkbookProgressDTO]

    private enum CodingKeys: String, CodingKey {
        case curriculumId
        case curriculumTitle
        case part
        case completedCount
        case totalCount
        case workbooks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        curriculumId = try container.decodeFlexibleString(forKey: .curriculumId)
        curriculumTitle = try container.decode(String.self, forKey: .curriculumTitle)
        part = try container.decode(String.self, forKey: .part)
        completedCount = try container.decodeFlexibleString(forKey: .completedCount)
        totalCount = try container.decodeFlexibleString(forKey: .totalCount)
        workbooks = try container.decode([ChallengerWorkbookProgressDTO].self, forKey: .workbooks)
    }
}

/// 챌린저 워크북 진행 항목 DTO
struct ChallengerWorkbookProgressDTO: Codable, Sendable, Equatable {
    let originalWorkbookId: String?
    let challengerWorkbookId: String?
    let weekNo: String
    let title: String
    let description: String
    let missionType: String
    let status: String?
    let isReleased: Bool
    let isInProgress: Bool

    private enum CodingKeys: String, CodingKey {
        case originalWorkbookId
        case challengerWorkbookId
        case weekNo
        case title
        case description
        case missionType
        case status
        case isReleased
        case isInProgress
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        originalWorkbookId = container.decodeFlexibleOptionalString(forKey: .originalWorkbookId)
        challengerWorkbookId = container.decodeFlexibleOptionalString(forKey: .challengerWorkbookId)
        weekNo = try container.decodeFlexibleString(forKey: .weekNo)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        missionType = try container.decode(String.self, forKey: .missionType)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        isReleased = try container.decode(Bool.self, forKey: .isReleased)
        isInProgress = try container.decode(Bool.self, forKey: .isInProgress)
    }
}

// MARK: - toDomain

extension ChallengerCurriculumProgressDTO {
    func toDomain(
        scheduleByWeek: [Int: WorkbookSchedule] = [:],
        now: Date = .now
    ) -> CurriculumData {
        let missions = workbooks
            .map { $0.toDomain(platform: part, scheduleByWeek: scheduleByWeek, now: now) }
            .sorted { $0.week < $1.week }
        let serverCompleted = Int(completedCount) ?? 0
        let localCompleted = missions.filter { $0.status == .pass }.count
        let completed = max(serverCompleted, localCompleted)
        let total = Int(totalCount) ?? workbooks.count
        let currentTitle = currentCurriculumTitle

        return CurriculumData(
            progress: CurriculumProgressModel(
                partType: UMCPartType(apiValue: part),
                partName: partDisplayName,
                curriculumTitle: currentTitle,
                completedCount: completed,
                totalCount: total
            ),
            missions: missions
        )
    }

    private var partDisplayName: String {
        let name = UMCPartType(apiValue: part)?.name ?? part
        return "\(name) PART CURRICULUM"
    }

    private var currentCurriculumTitle: String {
        workbooks.first(where: { $0.isInProgress })?.title ?? curriculumTitle
    }
}

private extension ChallengerWorkbookProgressDTO {
    func toDomain(
        platform: String,
        scheduleByWeek: [Int: WorkbookSchedule],
        now: Date
    ) -> MissionCardModel {
        let missionTitle = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let week = Int(weekNo) ?? 0
        return MissionCardModel(
            originalWorkbookId: originalWorkbookId.flatMap(Int.init)
                ?? challengerWorkbookId.flatMap(Int.init),
            challengerWorkbookId: challengerWorkbookId.flatMap(Int.init),
            week: week,
            platform: platform,
            title: title,
            missionTitle: missionTitle.isEmpty ? title : missionTitle,
            missionType: MissionType(rawValue: missionType),
            status: missionStatus(
                schedule: scheduleByWeek[week],
                now: now
            )
        )
    }

    func missionStatus(
        schedule: WorkbookSchedule?,
        now: Date
    ) -> MissionStatus {
        if !isReleased {
            return .locked
        }

        let normalizedStatus = status?.uppercased()
        switch normalizedStatus {
        case "PASS", "APPROVED", "BEST":
            return .pass
        case "FAIL", "REJECTED":
            return .fail
        case "SUBMITTED", "PENDING_APPROVAL", "UNDER_REVIEW":
            return .pendingApproval
        case "IN_PROGRESS", "PROGRESS":
            return .inProgress
        case "NOT_STARTED", "NOT_STARTED_YET", "READY":
            return releasedStatusFallback
        case "LOCKED":
            return releasedStatusFallback
        case "PENDING":
            return releasedStatusFallback
        case nil:
            // status가 내려오지 않으면 기존 플래그 기준으로 보정
            if isInProgress {
                return .inProgress
            }
            return releasedStatusFallback
        default:
            return releasedStatusFallback
        }
    }

    var releasedStatusFallback: MissionStatus {
        .inProgress
    }
}

// MARK: - Flexible Decoding Helper

private extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) throws -> String {
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

    func decodeFlexibleOptionalString(forKey key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(Int(value))
        }
        return nil
    }
}
