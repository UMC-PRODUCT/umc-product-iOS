//
//  WorkbookDetailDTO.swift
//  ActivityData
//
//  Created by euijjang97 on 9/21/26.
//

import ActivityDomain
import Foundation
import UMCFoundation

struct WorkbookFeedbackDTO: Codable {
    let missionFeedbackId: String
    let reviewerMemberId: String
    let content: String
    let feedbackResult: String

    enum CodingKeys: String, CodingKey {
        case missionFeedbackId, reviewerMemberId, content, feedbackResult
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        missionFeedbackId = values.decodeFlexibleStringOrNil(forKey: .missionFeedbackId) ?? ""
        reviewerMemberId = values.decodeFlexibleStringOrNil(forKey: .reviewerMemberId) ?? ""
        content = try values.decode(String.self, forKey: .content)
        feedbackResult = try values.decode(String.self, forKey: .feedbackResult)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(missionFeedbackId, forKey: .missionFeedbackId)
        try values.encode(reviewerMemberId, forKey: .reviewerMemberId)
        try values.encode(content, forKey: .content)
        try values.encode(feedbackResult, forKey: .feedbackResult)
    }

    func toDomain() -> WorkbookFeedback {
        WorkbookFeedback(
            missionFeedbackId: missionFeedbackId,
            reviewerMemberId: reviewerMemberId,
            content: content,
            feedbackResult: feedbackResult
        )
    }
}

struct WorkbookSubmissionDTO: Codable {
    let missionSubmissionId: String
    let originalWorkbookMissionId: String
    let submittedContent: String?
    let status: String
    let feedbacks: [WorkbookFeedbackDTO]

    enum CodingKeys: String, CodingKey {
        case missionSubmissionId, originalWorkbookMissionId, submittedContent, status, feedbacks
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        missionSubmissionId = values.decodeFlexibleStringOrNil(forKey: .missionSubmissionId) ?? ""
        originalWorkbookMissionId =
            values.decodeFlexibleStringOrNil(forKey: .originalWorkbookMissionId) ?? ""
        submittedContent = try values.decodeIfPresent(String.self, forKey: .submittedContent)
        status = try values.decode(String.self, forKey: .status)
        feedbacks =
            try values.decodeIfPresent([WorkbookFeedbackDTO].self, forKey: .feedbacks) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(missionSubmissionId, forKey: .missionSubmissionId)
        try values.encode(originalWorkbookMissionId, forKey: .originalWorkbookMissionId)
        try values.encodeIfPresent(submittedContent, forKey: .submittedContent)
        try values.encode(status, forKey: .status)
        try values.encode(feedbacks, forKey: .feedbacks)
    }

    func toDomain() -> WorkbookSubmission {
        WorkbookSubmission(
            missionSubmissionId: missionSubmissionId,
            originalWorkbookMissionId: originalWorkbookMissionId,
            submittedContent: submittedContent,
            status: status,
            feedbacks: feedbacks.map { $0.toDomain() }
        )
    }
}

struct WorkbookMissionDTO: Codable {
    let originalWorkbookMissionId: String
    let title: String
    let description: String?
    let missionType: String
    let isNecessary: Bool

    enum CodingKeys: String, CodingKey {
        case originalWorkbookMissionId, title, description, missionType, isNecessary
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        originalWorkbookMissionId =
            values.decodeFlexibleStringOrNil(forKey: .originalWorkbookMissionId) ?? ""
        title = try values.decode(String.self, forKey: .title)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        missionType = try values.decode(String.self, forKey: .missionType)
        isNecessary = try values.decode(Bool.self, forKey: .isNecessary)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(originalWorkbookMissionId, forKey: .originalWorkbookMissionId)
        try values.encode(title, forKey: .title)
        try values.encodeIfPresent(description, forKey: .description)
        try values.encode(missionType, forKey: .missionType)
        try values.encode(isNecessary, forKey: .isNecessary)
    }

    func toDomain() -> WorkbookMission {
        WorkbookMission(
            originalWorkbookMissionId: originalWorkbookMissionId,
            title: title,
            description: description,
            missionType: missionType,
            isNecessary: isNecessary
        )
    }
}

struct OriginalWorkbookDetailDTO: Codable {
    let originalWorkbookId: String
    let title: String
    let description: String?
    let content: String?
    let url: String?
    let missionList: [WorkbookMissionDTO]

    enum CodingKeys: String, CodingKey {
        case originalWorkbookId, title, description, content, url, missionList
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        originalWorkbookId = values.decodeFlexibleStringOrNil(forKey: .originalWorkbookId) ?? ""
        title = try values.decode(String.self, forKey: .title)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        content = try values.decodeIfPresent(String.self, forKey: .content)
        url = try values.decodeIfPresent(String.self, forKey: .url)
        missionList =
            try values.decodeIfPresent([WorkbookMissionDTO].self, forKey: .missionList) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(originalWorkbookId, forKey: .originalWorkbookId)
        try values.encode(title, forKey: .title)
        try values.encodeIfPresent(description, forKey: .description)
        try values.encodeIfPresent(content, forKey: .content)
        try values.encodeIfPresent(url, forKey: .url)
        try values.encode(missionList, forKey: .missionList)
    }

    func toDomain() -> OriginalWorkbookDetail {
        OriginalWorkbookDetail(
            originalWorkbookId: originalWorkbookId,
            title: title,
            description: description,
            content: content,
            url: url,
            missionList: missionList.map { $0.toDomain() }
        )
    }
}

struct ChallengerWorkbookDetailDTO: Codable {
    let challengerWorkbookId: String
    let originalWorkbookId: String
    let receivedStudyGroupId: String?
    let memberId: String
    let isExcused: Bool
    let content: String?
    let submissions: [WorkbookSubmissionDTO]

    enum CodingKeys: String, CodingKey {
        case challengerWorkbookId, originalWorkbookId, receivedStudyGroupId, memberId, isExcused,
            content, submissions
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        challengerWorkbookId =
            values.decodeFlexibleStringOrNil(forKey: .challengerWorkbookId) ?? ""
        originalWorkbookId = values.decodeFlexibleStringOrNil(forKey: .originalWorkbookId) ?? ""
        receivedStudyGroupId = values.decodeFlexibleStringOrNil(forKey: .receivedStudyGroupId)
        memberId = values.decodeFlexibleStringOrNil(forKey: .memberId) ?? ""
        isExcused = try values.decode(Bool.self, forKey: .isExcused)
        content = try values.decodeIfPresent(String.self, forKey: .content)
        submissions =
            try values.decodeIfPresent([WorkbookSubmissionDTO].self, forKey: .submissions) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(challengerWorkbookId, forKey: .challengerWorkbookId)
        try values.encode(originalWorkbookId, forKey: .originalWorkbookId)
        try values.encodeIfPresent(receivedStudyGroupId, forKey: .receivedStudyGroupId)
        try values.encode(memberId, forKey: .memberId)
        try values.encode(isExcused, forKey: .isExcused)
        try values.encodeIfPresent(content, forKey: .content)
        try values.encode(submissions, forKey: .submissions)
    }

    func toDomain() -> ChallengerWorkbookDetail {
        ChallengerWorkbookDetail(
            challengerWorkbookId: challengerWorkbookId,
            originalWorkbookId: originalWorkbookId,
            receivedStudyGroupId: receivedStudyGroupId,
            memberId: memberId,
            isExcused: isExcused,
            content: content,
            submissions: submissions.map { $0.toDomain() }
        )
    }
}
