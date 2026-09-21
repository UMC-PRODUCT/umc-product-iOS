//
//  WorkbookDetail.swift
//  ActivityDomain
//
//  Created by euijjang97 on 9/21/26.
//

import Foundation

public struct WorkbookFeedback: Equatable, Sendable {
    public let missionFeedbackId: String
    public let reviewerMemberId: String
    public let content: String
    public let feedbackResult: String

    public init(
        missionFeedbackId: String,
        reviewerMemberId: String,
        content: String,
        feedbackResult: String
    ) {
        self.missionFeedbackId = missionFeedbackId
        self.reviewerMemberId = reviewerMemberId
        self.content = content
        self.feedbackResult = feedbackResult
    }
}

public struct WorkbookSubmission: Equatable, Sendable {
    public let missionSubmissionId: String
    public let originalWorkbookMissionId: String
    public let submittedContent: String?
    public let status: String
    public let feedbacks: [WorkbookFeedback]

    public init(
        missionSubmissionId: String,
        originalWorkbookMissionId: String,
        submittedContent: String?,
        status: String,
        feedbacks: [WorkbookFeedback]
    ) {
        self.missionSubmissionId = missionSubmissionId
        self.originalWorkbookMissionId = originalWorkbookMissionId
        self.submittedContent = submittedContent
        self.status = status
        self.feedbacks = feedbacks
    }
}

public struct WorkbookMission: Equatable, Sendable {
    public let originalWorkbookMissionId: String
    public let title: String
    public let description: String?
    public let missionType: String
    public let isNecessary: Bool

    public init(
        originalWorkbookMissionId: String,
        title: String,
        description: String?,
        missionType: String,
        isNecessary: Bool
    ) {
        self.originalWorkbookMissionId = originalWorkbookMissionId
        self.title = title
        self.description = description
        self.missionType = missionType
        self.isNecessary = isNecessary
    }
}

public struct OriginalWorkbookDetail: Equatable, Sendable {
    public let originalWorkbookId: String
    public let title: String
    public let description: String?
    public let content: String?
    public let url: String?
    public let missionList: [WorkbookMission]

    public init(
        originalWorkbookId: String,
        title: String,
        description: String?,
        content: String?,
        url: String?,
        missionList: [WorkbookMission]
    ) {
        self.originalWorkbookId = originalWorkbookId
        self.title = title
        self.description = description
        self.content = content
        self.url = url
        self.missionList = missionList
    }
}

public struct ChallengerWorkbookDetail: Equatable, Sendable {
    public let challengerWorkbookId: String
    public let originalWorkbookId: String
    public let receivedStudyGroupId: String?
    public let memberId: String
    public let isExcused: Bool
    public let content: String?
    public let submissions: [WorkbookSubmission]

    public init(
        challengerWorkbookId: String,
        originalWorkbookId: String,
        receivedStudyGroupId: String?,
        memberId: String,
        isExcused: Bool,
        content: String?,
        submissions: [WorkbookSubmission]
    ) {
        self.challengerWorkbookId = challengerWorkbookId
        self.originalWorkbookId = originalWorkbookId
        self.receivedStudyGroupId = receivedStudyGroupId
        self.memberId = memberId
        self.isExcused = isExcused
        self.content = content
        self.submissions = submissions
    }
}

public struct WorkbookListItem: Identifiable, Equatable, Sendable {
    public let originalWorkbookId: String
    public let challengerWorkbookId: String?
    public let title: String
    public let endsAt: Date?
    public var id: String { originalWorkbookId }

    public init(
        originalWorkbookId: String, challengerWorkbookId: String?, title: String,
        endsAt: Date?
    ) {
        self.originalWorkbookId = originalWorkbookId
        self.challengerWorkbookId = challengerWorkbookId
        self.title = title
        self.endsAt = endsAt
    }
}

public struct WorkbookDetail: Equatable, Sendable {
    public let original: OriginalWorkbookDetail?
    public let challenger: ChallengerWorkbookDetail
    public init(original: OriginalWorkbookDetail?, challenger: ChallengerWorkbookDetail) {
        self.original = original
        self.challenger = challenger
    }
}

public enum WorkbookMutation: Sendable {
    case submit(missionId: String, workbookId: String, content: String?)
    case editSubmission(id: String, content: String)
    case withdraw(id: String)
    case feedback(submissionId: String, content: String, result: String)
    case editFeedback(id: String, content: String)
    case deleteFeedback(id: String)
}
