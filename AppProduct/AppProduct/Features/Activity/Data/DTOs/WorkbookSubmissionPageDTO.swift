//
//  WorkbookSubmissionPageDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation

/// 워크북 제출 현황 페이지 응답 DTO
///
/// `GET /api/v1/curriculums/workbook-submissions`
struct WorkbookSubmissionPageDTO: Codable, Sendable, Equatable {
    let content: [WorkbookSubmissionItemDTO]
    let nextCursor: Int?
    let hasNext: Bool
}

struct WorkbookSubmissionItemDTO: Codable, Sendable, Equatable {
    let challengerWorkbookId: Int
    let challengerId: Int
    let challengerName: String
    let profileImageUrl: String?
    let schoolName: String
    let part: String
    let workbookTitle: String
    let status: String
    let submissionUrl: String?

    private enum CodingKeys: String, CodingKey {
        case challengerWorkbookId
        case challengerId
        case challengerName
        case profileImageUrl
        case schoolName
        case part
        case workbookTitle
        case status
        case submission
        case submissionUrl
        case submissionURL
        case workbookUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challengerWorkbookId = try container.decode(Int.self, forKey: .challengerWorkbookId)
        challengerId = try container.decode(Int.self, forKey: .challengerId)
        challengerName = try container.decode(String.self, forKey: .challengerName)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        schoolName = try container.decode(String.self, forKey: .schoolName)
        part = try container.decode(String.self, forKey: .part)
        workbookTitle = try container.decode(String.self, forKey: .workbookTitle)
        status = try container.decode(String.self, forKey: .status)

        submissionUrl = try container.decodeIfPresent(String.self, forKey: .submissionUrl)
        ?? container.decodeIfPresent(String.self, forKey: .submissionURL)
        ?? container.decodeIfPresent(String.self, forKey: .submission)
        ?? container.decodeIfPresent(String.self, forKey: .workbookUrl)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(challengerWorkbookId, forKey: .challengerWorkbookId)
        try container.encode(challengerId, forKey: .challengerId)
        try container.encode(challengerName, forKey: .challengerName)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encode(schoolName, forKey: .schoolName)
        try container.encode(part, forKey: .part)
        try container.encode(workbookTitle, forKey: .workbookTitle)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(submissionUrl, forKey: .submissionUrl)
    }
}

extension WorkbookSubmissionItemDTO {
    func toDomain(week: Int) -> StudyMemberItem {
        StudyMemberItem(
            serverID: String(challengerId),
            challengerWorkbookId: challengerWorkbookId,
            name: challengerName,
            nickname: challengerName,
            part: part.toStudyPart,
            university: schoolName,
            studyTopic: workbookTitle.removingWeekPrefix,
            week: week,
            profileImageURL: profileImageUrl,
            submissionURL: submissionUrl,
            isBestWorkbook: status.uppercased() == "BEST"
        )
    }
}

private extension String {
    var removingWeekPrefix: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return self }

        let pattern = #"^(?:(?:Week|WEEK)\s*\d+|\d+\s*주차)\s*-\s*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return trimmed
        }
        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        let stripped = regex.stringByReplacingMatches(
            in: trimmed,
            options: [],
            range: range,
            withTemplate: ""
        )
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var toStudyPart: StudyPart {
        switch self.uppercased() {
        case "IOS":
            return .ios
        case "ANDROID":
            return .android
        case "WEB":
            return .web
        case "SPRINGBOOT":
            return .spring
        case "NODEJS":
            return .nodejs
        case "DESIGN":
            return .design
        case "PLAN", "PM":
            return .pm
        default:
            return .ios
        }
    }
}
