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
}

/// 챌린저 워크북 진행 항목 DTO
struct ChallengerWorkbookProgressDTO: Codable, Sendable, Equatable {
    let challengerWorkbookId: String?
    let weekNo: String
    let title: String
    let description: String
    let missionType: String
    let status: String?
    let isReleased: Bool
    let isInProgress: Bool
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
        let completed = Int(completedCount) ?? missions.filter { $0.status == .pass }.count
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
        case "LOCKED":
            return .locked
        case "PENDING":
            return pendingStatus(schedule: schedule, now: now)
        case nil:
            // status가 내려오지 않으면 기존 플래그 기준으로 보정
            if isInProgress {
                return .inProgress
            }
            return pendingStatus(schedule: schedule, now: now)
        default:
            return .locked
        }
    }

    private func pendingStatus(
        schedule: WorkbookSchedule?,
        now: Date
    ) -> MissionStatus {
        guard let schedule else {
            return isInProgress ? .inProgress : .locked
        }
        if let startDate = schedule.startDate, now < startDate {
            return .locked
        }
        if let startDate = schedule.startDate,
           let endDate = schedule.endDate,
           now >= startDate && now <= endDate {
            return .inProgress
        }
        if let startDate = schedule.startDate, now >= startDate {
            return .inProgress
        }
        return .locked
    }
}
