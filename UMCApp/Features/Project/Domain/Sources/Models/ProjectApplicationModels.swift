//
//  ProjectApplicationModels.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//
//  지원 폼·지원서 도메인 모델. 폼 구조(섹션·질문·선택지)는 폼 저장 요청과 조회 응답,
//  지원서 상세의 응답 폼이 같은 모양이라 한 벌로 쓴다.
//

import Foundation
import UMCFoundation

/// 프로젝트 지원 폼 (서버 `GetApplicationFormResponse`·`UpsertApplicationFormResponse`).
public struct ProjectApplicationForm: Sendable, Equatable {
    public let projectId: String
    public let applicationFormId: String
    public let title: String?
    public let description: String?
    public let sections: [ProjectFormSection]

    public init(
        projectId: String,
        applicationFormId: String,
        title: String?,
        description: String?,
        sections: [ProjectFormSection]
    ) {
        self.projectId = projectId
        self.applicationFormId = applicationFormId
        self.title = title
        self.description = description
        self.sections = sections
    }
}

/// 지원 폼 섹션 (서버 `ApplicationFormSection`·`SectionView`).
public struct ProjectFormSection: Sendable, Equatable {
    /// 새로 만드는 섹션이면 `nil` — 저장 요청에서 `nil` 은 생성, 값이 있으면 수정이다.
    public let sectionId: String?
    public let type: ProjectFormSectionType
    /// `part` 섹션을 볼 수 있는 파트. 비어 있으면 제한 없음.
    public let allowedParts: Set<UMCPartType>
    public let title: String
    public let description: String?
    public let orderNo: String
    public let questions: [ProjectFormQuestion]

    public init(
        sectionId: String?,
        type: ProjectFormSectionType,
        allowedParts: Set<UMCPartType>,
        title: String,
        description: String?,
        orderNo: String,
        questions: [ProjectFormQuestion]
    ) {
        self.sectionId = sectionId
        self.type = type
        self.allowedParts = allowedParts
        self.title = title
        self.description = description
        self.orderNo = orderNo
        self.questions = questions
    }
}

/// 지원 폼 질문 (서버 `ApplicationQuestionItem`·`QuestionView`).
public struct ProjectFormQuestion: Sendable, Equatable {
    public let questionId: String?
    public let type: ProjectQuestionType
    public let title: String
    public let description: String?
    public let isRequired: Bool
    public let orderNo: String
    public let options: [ProjectFormOption]
    /// 지원서 상세에서만 채워진다. 폼 조회·저장에서는 항상 `nil`.
    public let answer: ProjectApplicationAnswer?

    public init(
        questionId: String?,
        type: ProjectQuestionType,
        title: String,
        description: String?,
        isRequired: Bool,
        orderNo: String,
        options: [ProjectFormOption],
        answer: ProjectApplicationAnswer? = nil
    ) {
        self.questionId = questionId
        self.type = type
        self.title = title
        self.description = description
        self.isRequired = isRequired
        self.orderNo = orderNo
        self.options = options
        self.answer = answer
    }
}

/// 지원 폼 선택지 (서버 `ApplicationQuestionOptionItem`·`OptionView`).
public struct ProjectFormOption: Sendable, Equatable {
    public let optionId: String?
    public let content: String
    public let orderNo: String
    /// 「기타」 자유 입력 선택지인지.
    public let isOther: Bool

    public init(optionId: String?, content: String, orderNo: String, isOther: Bool) {
        self.optionId = optionId
        self.content = content
        self.orderNo = orderNo
        self.isOther = isOther
    }
}

/// 제출된 답변 (서버 `AnswerView`).
public struct ProjectApplicationAnswer: Sendable, Equatable {
    public let answerId: String
    /// 답변 당시의 질문 유형 — 이후 질문 유형이 바뀌어도 답변은 이 유형으로 해석한다.
    public let answeredAsType: ProjectQuestionType
    public let textValue: String?
    public let selectedOptions: [ProjectSelectedOption]
    public let files: [ProjectAnswerFile]
    public let times: [Date]

    public init(
        answerId: String,
        answeredAsType: ProjectQuestionType,
        textValue: String?,
        selectedOptions: [ProjectSelectedOption],
        files: [ProjectAnswerFile],
        times: [Date]
    ) {
        self.answerId = answerId
        self.answeredAsType = answeredAsType
        self.textValue = textValue
        self.selectedOptions = selectedOptions
        self.files = files
        self.times = times
    }
}

/// 답변에서 고른 선택지 (서버 `SelectedOptionView`).
public struct ProjectSelectedOption: Sendable, Equatable {
    public let questionOptionId: String
    /// 답변 당시의 선택지 문구.
    public let answeredAsContent: String?

    public init(questionOptionId: String, answeredAsContent: String?) {
        self.questionOptionId = questionOptionId
        self.answeredAsContent = answeredAsContent
    }
}

/// 답변 첨부 파일 (서버 `FileView`).
public struct ProjectAnswerFile: Sendable, Equatable {
    public let fileId: String
    public let originalFileName: String?
    public let url: String?

    public init(fileId: String, originalFileName: String?, url: String?) {
        self.fileId = fileId
        self.originalFileName = originalFileName
        self.url = url
    }
}

/// 답변 저장 항목 (`PUT .../applications/{applicationId}` 요청의 `answers[]`).
public struct ProjectAnswerInput: Sendable, Equatable {
    public let questionId: String
    public let textValue: String?
    public let selectedOptionIds: [String]
    public let fileIds: [String]

    public init(
        questionId: String,
        textValue: String? = nil,
        selectedOptionIds: [String] = [],
        fileIds: [String] = []
    ) {
        self.questionId = questionId
        self.textValue = textValue
        self.selectedOptionIds = selectedOptionIds
        self.fileIds = fileIds
    }
}

/// 지원서 명령의 결과 (서버 `ProjectApplicationStatusResponse`).
public struct ProjectApplicationResult: Sendable, Equatable {
    public let applicationId: String
    public let status: ProjectApplicationStatus

    public init(applicationId: String, status: ProjectApplicationStatus) {
        self.applicationId = applicationId
        self.status = status
    }
}

/// 지원자 (서버 `Applicant`).
public struct ProjectApplicant: Sendable, Equatable {
    public let memberId: String
    public let nickname: String?
    public let name: String?
    public let schoolName: String?
    public let part: UMCPartType?

    public init(
        memberId: String,
        nickname: String?,
        name: String?,
        schoolName: String?,
        part: UMCPartType?
    ) {
        self.memberId = memberId
        self.nickname = nickname
        self.name = name
        self.schoolName = schoolName
        self.part = part
    }
}

/// 내 지원 내역 항목 (서버 `MyProjectApplicationResponse`).
///
/// 랜덤 매칭으로 합류한 프로젝트는 지원서가 없어 `applicationId` 가 `nil` 이고
/// `matchingRound.phase` 가 `.randomMatching` 이다.
public struct MyProjectApplication: Sendable, Equatable {
    public let applicationId: String?
    public let projectId: String
    public let project: ProjectSummary?
    public let matchingRound: ProjectMatchingRoundBrief?
    public let status: ProjectApplicationStatus?

    public init(
        applicationId: String?,
        projectId: String,
        project: ProjectSummary?,
        matchingRound: ProjectMatchingRoundBrief?,
        status: ProjectApplicationStatus?
    ) {
        self.applicationId = applicationId
        self.projectId = projectId
        self.project = project
        self.matchingRound = matchingRound
        self.status = status
    }
}

/// 프로젝트에 들어온 지원서 목록 항목 (서버 `ProjectApplicantResponse`).
public struct ProjectApplicationSummary: Sendable, Equatable {
    public let applicationId: String
    public let applicant: ProjectApplicant
    public let matchingRound: ProjectMatchingRoundBrief?
    public let status: ProjectApplicationStatus
    public let submittedAt: Date?
    public let statusChangedAt: Date?

    public init(
        applicationId: String,
        applicant: ProjectApplicant,
        matchingRound: ProjectMatchingRoundBrief?,
        status: ProjectApplicationStatus,
        submittedAt: Date?,
        statusChangedAt: Date?
    ) {
        self.applicationId = applicationId
        self.applicant = applicant
        self.matchingRound = matchingRound
        self.status = status
        self.submittedAt = submittedAt
        self.statusChangedAt = statusChangedAt
    }
}

/// 지원서 상세 (서버 `ProjectApplicationDetailResponse`).
public struct ProjectApplicationDetail: Sendable, Equatable {
    public let applicationId: String
    public let applicant: ProjectApplicant
    public let matchingRound: ProjectMatchingRoundBrief?
    /// 지원자 본인이 결과 발표 전에 보면 `nil` 로 가려진다.
    public let status: ProjectApplicationStatus?
    public let submittedAt: Date?
    public let statusChangedAt: Date?
    public let formResponse: ProjectFormResponse?

    public init(
        applicationId: String,
        applicant: ProjectApplicant,
        matchingRound: ProjectMatchingRoundBrief?,
        status: ProjectApplicationStatus?,
        submittedAt: Date?,
        statusChangedAt: Date?,
        formResponse: ProjectFormResponse?
    ) {
        self.applicationId = applicationId
        self.applicant = applicant
        self.matchingRound = matchingRound
        self.status = status
        self.submittedAt = submittedAt
        self.statusChangedAt = statusChangedAt
        self.formResponse = formResponse
    }
}

/// 지원서의 폼 응답 (서버 `FormResponseView`). 질문마다 `answer` 가 붙는다.
public struct ProjectFormResponse: Sendable, Equatable {
    public let formResponseId: String
    public let formId: String
    public let status: ProjectFormResponseStatus
    public let submittedAt: Date?
    public let lastSavedAt: Date?
    public let sections: [ProjectFormSection]

    public init(
        formResponseId: String,
        formId: String,
        status: ProjectFormResponseStatus,
        submittedAt: Date?,
        lastSavedAt: Date?,
        sections: [ProjectFormSection]
    ) {
        self.formResponseId = formResponseId
        self.formId = formId
        self.status = status
        self.submittedAt = submittedAt
        self.lastSavedAt = lastSavedAt
        self.sections = sections
    }
}

/// 지원서 목록 필터 (`GET /{projectId}/applications`·`GET /applications`). 전부 선택.
public struct ProjectApplicationFilter: Sendable, Equatable {
    public let matchingRoundId: String?
    public let part: UMCPartType?
    public let status: ProjectApplicationStatus?

    public init(
        matchingRoundId: String? = nil,
        part: UMCPartType? = nil,
        status: ProjectApplicationStatus? = nil
    ) {
        self.matchingRoundId = matchingRoundId
        self.part = part
        self.status = status
    }
}
