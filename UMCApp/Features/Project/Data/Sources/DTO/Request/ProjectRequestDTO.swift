//
//  ProjectRequestDTO.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//
//  프로젝트 API 요청 본문 DTO 모음. 서버 `Long` 필드는 `Int` 로 보낸다(요청 DTO 는
//  핵심 규칙 #2·#3 예외). 도메인 `String` id 는 ``projectServerInt(_:field:)`` 로 바꾼다.
//  optional 은 synthesized `Encodable` 이 `nil` 이면 키를 빼므로, PATCH 에서 안 바꿀 필드가
//  서버 값을 덮지 않는다.
//

import Foundation
import UMCFoundation
import ProjectDomain

// MARK: - Project

/// `POST /api/v1/projects`
public struct CreateDraftProjectRequestDTO: Encodable, Equatable {
    public let gisuId: Int
    /// `nil` 이면 요청자가 PO 가 된다.
    public let productOwnerMemberId: Int?

    public init(gisuId: Int, productOwnerMemberId: Int?) {
        self.gisuId = gisuId
        self.productOwnerMemberId = productOwnerMemberId
    }
}

/// `PATCH /api/v1/projects/{projectId}` — 파일 id 는 서버도 문자열이다.
public struct UpdateProjectRequestDTO: Encodable, Equatable {
    public let name: String?
    public let description: String?
    public let externalLink: String?
    public let thumbnailFileId: String?
    public let logoFileId: String?

    public init(update: ProjectInfoUpdate) {
        self.name = update.name
        self.description = update.description
        self.externalLink = update.externalLink
        self.thumbnailFileId = update.thumbnailFileId
        self.logoFileId = update.logoFileId
    }
}

/// `POST /{projectId}/transfer-ownership`
public struct TransferProjectOwnershipRequestDTO: Encodable, Equatable {
    public let newOwnerMemberId: Int
    public let reason: String?

    public init(newOwnerMemberId: Int, reason: String?) {
        self.newOwnerMemberId = newOwnerMemberId
        self.reason = reason
    }
}

/// `POST /{projectId}/members`
public struct AddProjectMemberRequestDTO: Encodable, Equatable {
    public let memberId: Int
    public let part: UMCPartType

    public init(memberId: Int, part: UMCPartType) {
        self.memberId = memberId
        self.part = part
    }
}

/// `PATCH /{projectId}/members/{memberId}/status`
public struct ChangeProjectMemberStatusRequestDTO: Encodable, Equatable {
    public let status: String
    public let reason: String

    public init(status: ProjectMemberStatus, reason: String) {
        self.status = status.rawValue
        self.reason = reason
    }
}

/// `PUT /{projectId}/part-quotas`
public struct UpdatePartQuotasRequestDTO: Encodable, Equatable {
    public let entries: [Entry]

    public struct Entry: Encodable, Equatable {
        public let part: UMCPartType
        public let quota: Int
    }

    public init(entries: [ProjectPartQuotaEntry]) throws {
        self.entries = try entries.map {
            Entry(part: $0.part, quota: try projectServerInt($0.quota, field: "quota"))
        }
    }
}

/// `POST /{projectId}/abort`
public struct AbortProjectRequestDTO: Encodable, Equatable {
    public let reason: String

    public init(reason: String) {
        self.reason = reason
    }
}

/// `POST /api/v1/projects/complete`
public struct CompleteProjectsRequestDTO: Encodable, Equatable {
    public let projectIds: [Int]

    public init(projectIds: [String]) throws {
        self.projectIds = try projectIds.map { try projectServerInt($0, field: "projectIds") }
    }
}

// MARK: - Application Form

/// `PUT /{projectId}/application-form` — id 가 `nil` 인 섹션·질문·선택지는 서버가 새로 만든다.
public struct UpsertApplicationFormRequestDTO: Encodable, Equatable {
    public let title: String?
    public let description: String?
    public let sections: [Section]

    public init(title: String?, description: String?, sections: [ProjectFormSection]) throws {
        self.title = title
        self.description = description
        self.sections = try sections.map(Section.init)
    }

    public struct Section: Encodable, Equatable {
        public let sectionId: Int?
        public let type: String
        public let allowedParts: [UMCPartType]
        public let title: String
        public let description: String?
        public let orderNo: Int
        public let questions: [Question]

        init(_ section: ProjectFormSection) throws {
            self.sectionId = try section.sectionId.map {
                try projectServerInt($0, field: "sectionId")
            }
            self.type = section.type.rawValue
            // Set 순서는 매번 달라 요청 본문이 흔들린다 — apiValue 로 정렬해 고정한다.
            self.allowedParts = section.allowedParts.sorted { $0.apiValue < $1.apiValue }
            self.title = section.title
            self.description = section.description
            self.orderNo = try projectServerInt(section.orderNo, field: "orderNo")
            self.questions = try section.questions.map(Question.init)
        }
    }

    public struct Question: Encodable, Equatable {
        public let questionId: Int?
        public let type: String
        public let title: String
        public let description: String?
        public let isRequired: Bool
        public let orderNo: Int
        public let options: [Option]

        init(_ question: ProjectFormQuestion) throws {
            self.questionId = try question.questionId.map {
                try projectServerInt($0, field: "questionId")
            }
            self.type = question.type.rawValue
            self.title = question.title
            self.description = question.description
            self.isRequired = question.isRequired
            self.orderNo = try projectServerInt(question.orderNo, field: "orderNo")
            self.options = try question.options.map(Option.init)
        }
    }

    public struct Option: Encodable, Equatable {
        public let optionId: Int?
        public let content: String
        public let orderNo: Int
        public let isOther: Bool

        init(_ option: ProjectFormOption) throws {
            self.optionId = try option.optionId.map { try projectServerInt($0, field: "optionId") }
            self.content = option.content
            self.orderNo = try projectServerInt(option.orderNo, field: "orderNo")
            self.isOther = option.isOther
        }
    }
}

// MARK: - Application

/// `POST /{projectId}/applications`
public struct CreateProjectApplicationRequestDTO: Encodable, Equatable {
    public let matchingRoundId: Int

    public init(matchingRoundId: Int) {
        self.matchingRoundId = matchingRoundId
    }
}

/// `PUT /{projectId}/applications/{applicationId}`
public struct UpdateApplicationAnswersRequestDTO: Encodable, Equatable {
    public let answers: [Answer]

    public struct Answer: Encodable, Equatable {
        public let questionId: Int
        public let textValue: String?
        public let selectedOptionIds: [Int]
        /// 파일 id 는 서버도 문자열이다.
        public let fileIds: [String]
    }

    public init(answers: [ProjectAnswerInput]) throws {
        self.answers = try answers.map {
            Answer(
                questionId: try projectServerInt($0.questionId, field: "questionId"),
                textValue: $0.textValue,
                selectedOptionIds: try $0.selectedOptionIds.map {
                    try projectServerInt($0, field: "selectedOptionIds")
                },
                fileIds: $0.fileIds
            )
        }
    }
}

/// `PATCH .../applications/{applicationId}/decision`
public struct UpdateApplicationDecisionRequestDTO: Encodable, Equatable {
    public let status: String
    public let reason: String?

    public init(decision: ProjectApplicationDecision, reason: String?) {
        self.status = decision.rawValue
        self.reason = reason
    }
}

// MARK: - Matching Round

/// `POST /api/v1/project/matching-rounds` — 시각은 UTC ISO 8601.
public struct CreateProjectMatchingRoundRequestDTO: Encodable, Equatable {
    public let name: String
    public let description: String?
    public let type: String
    public let phase: String
    public let chapterId: Int
    public let startsAt: String
    public let endsAt: String
    public let decisionDeadline: String

    public init(draft: ProjectMatchingRoundDraft) throws {
        self.name = draft.name
        self.description = draft.description
        self.type = draft.type.rawValue
        self.phase = draft.phase.rawValue
        self.chapterId = try projectServerInt(draft.chapterId, field: "chapterId")
        self.startsAt = ServerDateTimeConverter.toUTCDateTimeString(draft.startsAt)
        self.endsAt = ServerDateTimeConverter.toUTCDateTimeString(draft.endsAt)
        self.decisionDeadline = ServerDateTimeConverter.toUTCDateTimeString(draft.decisionDeadline)
    }
}

/// `PATCH /api/v1/project/matching-rounds/{matchingRoundId}` — 서버가 `chapterId` 를 거부한다.
public struct UpdateProjectMatchingRoundRequestDTO: Encodable, Equatable {
    public let name: String?
    public let description: String?
    public let type: String?
    public let phase: String?
    public let startsAt: String?
    public let endsAt: String?
    public let decisionDeadline: String?

    public init(update: ProjectMatchingRoundUpdate) {
        self.name = update.name
        self.description = update.description
        self.type = update.type?.rawValue
        self.phase = update.phase?.rawValue
        self.startsAt = update.startsAt.map(ServerDateTimeConverter.toUTCDateTimeString)
        self.endsAt = update.endsAt.map(ServerDateTimeConverter.toUTCDateTimeString)
        self.decisionDeadline = update.decisionDeadline.map(
            ServerDateTimeConverter.toUTCDateTimeString
        )
    }
}
