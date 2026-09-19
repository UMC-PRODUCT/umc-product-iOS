//
//  ProjectApplicationResponseDTO.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//
//  지원 폼·지원서 응답 DTO 모음. 폼 구조(섹션·질문·선택지)는 폼 조회·저장과 지원서 상세가
//  같은 모양이라 한 벌로 받는다 — 지원서 상세에만 질문별 `answer` 가 붙는다.
//  시각(`Instant`)은 UTC ISO 8601 문자열로 받아 `toDomain()` 에서 해석한다.
//

import Foundation
import UMCFoundation
import ProjectDomain

// MARK: - Form

/// 폼 조회·저장 응답 (서버 `GetApplicationFormResponse`·`UpsertApplicationFormResponse`).
public struct ProjectApplicationFormResponseDTO: Codable {
    let projectId: String
    let applicationFormId: String
    let title: String?
    let description: String?
    let sections: [ProjectFormSectionDTO]

    private enum CodingKeys: String, CodingKey {
        case projectId, applicationFormId, title, description, sections
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try container.decodeFlexibleString(forKey: .projectId)
        applicationFormId = try container.decodeFlexibleString(forKey: .applicationFormId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        sections = try container.decodeIfPresent(
            [ProjectFormSectionDTO].self,
            forKey: .sections
        ) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(applicationFormId, forKey: .applicationFormId)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(sections, forKey: .sections)
    }

    public func toDomain() -> ProjectApplicationForm {
        ProjectApplicationForm(
            projectId: projectId,
            applicationFormId: applicationFormId,
            title: title,
            description: description,
            sections: sections.map { $0.toDomain() }
        )
    }
}

/// 폼 섹션 (서버 `ApplicationFormSection`·`SectionView`).
public struct ProjectFormSectionDTO: Codable {
    let sectionId: String?
    let type: String
    let allowedParts: [String]
    let title: String
    let description: String?
    let orderNo: String
    let questions: [ProjectFormQuestionDTO]

    private enum CodingKeys: String, CodingKey {
        case sectionId, type, allowedParts, title, description, orderNo, questions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sectionId = try container.decodeFlexibleStringIfPresent(forKey: .sectionId)
        type = try container.decode(String.self, forKey: .type)
        allowedParts = try container.decodeIfPresent([String].self, forKey: .allowedParts) ?? []
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        orderNo = try container.decodeProjectCount(forKey: .orderNo)
        questions = try container.decodeIfPresent(
            [ProjectFormQuestionDTO].self,
            forKey: .questions
        ) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(sectionId, forKey: .sectionId)
        try container.encode(type, forKey: .type)
        try container.encode(allowedParts, forKey: .allowedParts)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(orderNo, forKey: .orderNo)
        try container.encode(questions, forKey: .questions)
    }

    public func toDomain() -> ProjectFormSection {
        ProjectFormSection(
            sectionId: sectionId,
            type: ProjectFormSectionType(rawValue: type) ?? .unknown,
            allowedParts: Set(allowedParts.compactMap(UMCPartType.init(apiValue:))),
            title: title,
            description: description,
            orderNo: orderNo,
            questions: questions.map { $0.toDomain() }
        )
    }
}

/// 폼 질문 (서버 `ApplicationQuestionItem`·`QuestionView`).
public struct ProjectFormQuestionDTO: Codable {
    let questionId: String?
    let type: String
    let title: String
    let description: String?
    let isRequired: Bool
    let orderNo: String
    let options: [ProjectFormOptionDTO]
    let answer: ProjectFormAnswerDTO?

    private enum CodingKeys: String, CodingKey {
        case questionId, type, title, description, isRequired, orderNo, options, answer
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        questionId = try container.decodeFlexibleStringIfPresent(forKey: .questionId)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isRequired = try container.decodeBoolFlexibleIfPresent(forKey: .isRequired) ?? false
        orderNo = try container.decodeProjectCount(forKey: .orderNo)
        options = try container.decodeIfPresent(
            [ProjectFormOptionDTO].self,
            forKey: .options
        ) ?? []
        answer = try container.decodeIfPresent(ProjectFormAnswerDTO.self, forKey: .answer)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(questionId, forKey: .questionId)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isRequired, forKey: .isRequired)
        try container.encode(orderNo, forKey: .orderNo)
        try container.encode(options, forKey: .options)
        try container.encodeIfPresent(answer, forKey: .answer)
    }

    public func toDomain() -> ProjectFormQuestion {
        ProjectFormQuestion(
            questionId: questionId,
            type: ProjectQuestionType(rawValue: type) ?? .unknown,
            title: title,
            description: description,
            isRequired: isRequired,
            orderNo: orderNo,
            options: options.map { $0.toDomain() },
            answer: answer?.toDomain()
        )
    }
}

/// 질문 선택지 (서버 `ApplicationQuestionOptionItem`·`OptionView`).
public struct ProjectFormOptionDTO: Codable {
    let optionId: String?
    let content: String
    let orderNo: String
    let isOther: Bool

    private enum CodingKeys: String, CodingKey {
        case optionId, content, orderNo, isOther
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        optionId = try container.decodeFlexibleStringIfPresent(forKey: .optionId)
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        orderNo = try container.decodeProjectCount(forKey: .orderNo)
        isOther = try container.decodeBoolFlexibleIfPresent(forKey: .isOther) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(optionId, forKey: .optionId)
        try container.encode(content, forKey: .content)
        try container.encode(orderNo, forKey: .orderNo)
        try container.encode(isOther, forKey: .isOther)
    }

    public func toDomain() -> ProjectFormOption {
        ProjectFormOption(optionId: optionId, content: content, orderNo: orderNo, isOther: isOther)
    }
}

/// 질문 답변 (서버 `AnswerView`) — 지원서 상세에만 온다.
public struct ProjectFormAnswerDTO: Codable {
    let answerId: String
    let answeredAsType: String?
    let textValue: String?
    let selectedOptions: [SelectedOptionDTO]
    let files: [FileDTO]
    let times: [String]

    private enum CodingKeys: String, CodingKey {
        case answerId, answeredAsType, textValue, selectedOptions, files, times
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        answerId = try container.decodeFlexibleString(forKey: .answerId)
        answeredAsType = try container.decodeIfPresent(String.self, forKey: .answeredAsType)
        textValue = try container.decodeIfPresent(String.self, forKey: .textValue)
        selectedOptions = try container.decodeIfPresent(
            [SelectedOptionDTO].self,
            forKey: .selectedOptions
        ) ?? []
        files = try container.decodeIfPresent([FileDTO].self, forKey: .files) ?? []
        times = try container.decodeIfPresent([String].self, forKey: .times) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(answerId, forKey: .answerId)
        try container.encodeIfPresent(answeredAsType, forKey: .answeredAsType)
        try container.encodeIfPresent(textValue, forKey: .textValue)
        try container.encode(selectedOptions, forKey: .selectedOptions)
        try container.encode(files, forKey: .files)
        try container.encode(times, forKey: .times)
    }

    public func toDomain() -> ProjectApplicationAnswer {
        ProjectApplicationAnswer(
            answerId: answerId,
            answeredAsType: answeredAsType.flatMap(ProjectQuestionType.init(rawValue:))
                ?? .unknown,
            textValue: textValue,
            selectedOptions: selectedOptions.map { $0.toDomain() },
            files: files.map { $0.toDomain() },
            // 서버는 `Set<Instant>` 라 순서가 없다 — 시간순으로 맞춘다.
            times: times.compactMap(ServerDateTimeConverter.parseUTCDateTime).sorted()
        )
    }

    /// 고른 선택지. 선택지가 나중에 바뀌어도 답할 때의 문구가 `answeredAsContent` 로 남는다.
    public struct SelectedOptionDTO: Codable {
        let questionOptionId: String
        let answeredAsContent: String?

        private enum CodingKeys: String, CodingKey {
            case questionOptionId, answeredAsContent
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            questionOptionId = try container.decodeFlexibleString(forKey: .questionOptionId)
            answeredAsContent = try container.decodeIfPresent(
                String.self,
                forKey: .answeredAsContent
            )
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(questionOptionId, forKey: .questionOptionId)
            try container.encodeIfPresent(answeredAsContent, forKey: .answeredAsContent)
        }

        func toDomain() -> ProjectSelectedOption {
            ProjectSelectedOption(
                questionOptionId: questionOptionId,
                answeredAsContent: answeredAsContent
            )
        }
    }

    /// 첨부 파일.
    public struct FileDTO: Codable {
        let fileId: String
        let originalFileName: String?
        let url: String?

        private enum CodingKeys: String, CodingKey {
            case fileId, originalFileName, url
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            fileId = try container.decodeFlexibleString(forKey: .fileId)
            originalFileName = try container.decodeIfPresent(
                String.self,
                forKey: .originalFileName
            )
            url = try container.decodeIfPresent(String.self, forKey: .url)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(fileId, forKey: .fileId)
            try container.encodeIfPresent(originalFileName, forKey: .originalFileName)
            try container.encodeIfPresent(url, forKey: .url)
        }

        func toDomain() -> ProjectAnswerFile {
            ProjectAnswerFile(fileId: fileId, originalFileName: originalFileName, url: url)
        }
    }
}

// MARK: - Application

/// 지원서 상태 전이 응답 (서버 `ProjectApplicationStatusResponse`).
public struct ProjectApplicationStatusResponseDTO: Codable {
    let applicationId: String
    let status: String

    private enum CodingKeys: String, CodingKey {
        case applicationId, status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        applicationId = try container.decodeFlexibleString(forKey: .applicationId)
        status = try container.decode(String.self, forKey: .status)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(applicationId, forKey: .applicationId)
        try container.encode(status, forKey: .status)
    }

    public func toDomain() -> ProjectApplicationResult {
        ProjectApplicationResult(
            applicationId: applicationId,
            status: ProjectApplicationStatus(rawValue: status) ?? .unknown
        )
    }
}

/// 지원자 (서버 `Applicant`).
public struct ProjectApplicantDTO: Codable {
    let memberId: String
    let nickname: String?
    let name: String?
    let schoolName: String?
    let part: String?

    private enum CodingKeys: String, CodingKey {
        case memberId, nickname, name, schoolName, part
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try container.decodeFlexibleString(forKey: .memberId)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        schoolName = try container.decodeIfPresent(String.self, forKey: .schoolName)
        part = try container.decodeIfPresent(String.self, forKey: .part)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(memberId, forKey: .memberId)
        try container.encodeIfPresent(nickname, forKey: .nickname)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(schoolName, forKey: .schoolName)
        try container.encodeIfPresent(part, forKey: .part)
    }

    public func toDomain() -> ProjectApplicant {
        ProjectApplicant(
            memberId: memberId,
            nickname: nickname,
            name: name,
            schoolName: schoolName,
            part: part.flatMap(UMCPartType.init(apiValue:))
        )
    }
}

/// 내 지원 내역 원소 (서버 `MyProjectApplicationResponse`).
///
/// 랜덤 매칭으로 합류한 프로젝트는 지원서가 없어 `applicationId` 가 `null`,
/// 차수는 `RANDOM_MATCHING`, 상태는 `APPROVED` 로 온다.
public struct MyProjectApplicationResponseDTO: Codable {
    let applicationId: String?
    let projectId: String
    let project: ProjectBriefDTO?
    let matchingRound: ProjectMatchingRoundBriefDTO?
    let status: String?

    private enum CodingKeys: String, CodingKey {
        case applicationId, projectId, project, matchingRound, status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        applicationId = try container.decodeFlexibleStringIfPresent(forKey: .applicationId)
        projectId = try container.decodeFlexibleString(forKey: .projectId)
        project = try container.decodeIfPresent(ProjectBriefDTO.self, forKey: .project)
        matchingRound = try container.decodeIfPresent(
            ProjectMatchingRoundBriefDTO.self,
            forKey: .matchingRound
        )
        status = try container.decodeIfPresent(String.self, forKey: .status)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(applicationId, forKey: .applicationId)
        try container.encode(projectId, forKey: .projectId)
        try container.encodeIfPresent(project, forKey: .project)
        try container.encodeIfPresent(matchingRound, forKey: .matchingRound)
        try container.encodeIfPresent(status, forKey: .status)
    }

    public func toDomain() -> MyProjectApplication {
        MyProjectApplication(
            applicationId: applicationId,
            projectId: projectId,
            project: project?.toDomain(projectId: projectId),
            matchingRound: matchingRound?.toDomain(),
            status: status.map { ProjectApplicationStatus(rawValue: $0) ?? .unknown }
        )
    }

    /// 프로젝트 요약 (서버 `ProjectBrief` — id 는 바깥 `projectId` 에 있다).
    public struct ProjectBriefDTO: Codable {
        let name: String
        let thumbnailImageUrl: String?
        let productOwner: ProjectMemberBriefDTO?
        let partQuotas: [ProjectPartQuotaDTO]

        private enum CodingKeys: String, CodingKey {
            case name, thumbnailImageUrl, productOwner, partQuotas
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
            thumbnailImageUrl = try container.decodeIfPresent(
                String.self,
                forKey: .thumbnailImageUrl
            )
            productOwner = try container.decodeIfPresent(
                ProjectMemberBriefDTO.self,
                forKey: .productOwner
            )
            partQuotas = try container.decodeIfPresent(
                [ProjectPartQuotaDTO].self,
                forKey: .partQuotas
            ) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(thumbnailImageUrl, forKey: .thumbnailImageUrl)
            try container.encodeIfPresent(productOwner, forKey: .productOwner)
            try container.encode(partQuotas, forKey: .partQuotas)
        }

        func toDomain(projectId: String) -> ProjectSummary {
            ProjectSummary(
                id: projectId,
                name: name,
                description: nil,
                thumbnailImageURL: thumbnailImageUrl,
                status: nil,
                productOwner: productOwner?.toDomain(),
                partQuotas: partQuotas.compactMap { $0.toDomain() },
                partQuotaStatus: nil
            )
        }
    }
}

/// 지원서 목록 원소 (서버 `ProjectApplicantResponse`). 상태는 제출·합격·불합격만 온다.
public struct ProjectApplicationSummaryResponseDTO: Codable {
    let applicationId: String
    let applicant: ProjectApplicantDTO
    let matchingRound: ProjectMatchingRoundBriefDTO?
    let status: String?
    let submittedAt: String?
    let statusChangedAt: String?

    private enum CodingKeys: String, CodingKey {
        case applicationId, applicant, matchingRound, status, submittedAt, statusChangedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        applicationId = try container.decodeFlexibleString(forKey: .applicationId)
        applicant = try container.decode(ProjectApplicantDTO.self, forKey: .applicant)
        matchingRound = try container.decodeIfPresent(
            ProjectMatchingRoundBriefDTO.self,
            forKey: .matchingRound
        )
        status = try container.decodeIfPresent(String.self, forKey: .status)
        submittedAt = try container.decodeIfPresent(String.self, forKey: .submittedAt)
        statusChangedAt = try container.decodeIfPresent(String.self, forKey: .statusChangedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(applicationId, forKey: .applicationId)
        try container.encode(applicant, forKey: .applicant)
        try container.encodeIfPresent(matchingRound, forKey: .matchingRound)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(submittedAt, forKey: .submittedAt)
        try container.encodeIfPresent(statusChangedAt, forKey: .statusChangedAt)
    }

    public func toDomain() -> ProjectApplicationSummary {
        ProjectApplicationSummary(
            applicationId: applicationId,
            applicant: applicant.toDomain(),
            matchingRound: matchingRound?.toDomain(),
            status: status.flatMap(ProjectApplicationStatus.init(rawValue:)) ?? .unknown,
            submittedAt: submittedAt.flatMap(ServerDateTimeConverter.parseUTCDateTime),
            statusChangedAt: statusChangedAt.flatMap(ServerDateTimeConverter.parseUTCDateTime)
        )
    }
}

/// 지원서 상세 (서버 `ProjectApplicationDetailResponse`).
public struct ProjectApplicationDetailResponseDTO: Codable {
    let applicationId: String
    let applicant: ProjectApplicantDTO
    let matchingRound: ProjectMatchingRoundBriefDTO?
    let status: String?
    let submittedAt: String?
    let statusChangedAt: String?
    let formResponse: FormResponseDTO?

    private enum CodingKeys: String, CodingKey {
        case applicationId, applicant, matchingRound, status, submittedAt, statusChangedAt
        case formResponse
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        applicationId = try container.decodeFlexibleString(forKey: .applicationId)
        applicant = try container.decode(ProjectApplicantDTO.self, forKey: .applicant)
        matchingRound = try container.decodeIfPresent(
            ProjectMatchingRoundBriefDTO.self,
            forKey: .matchingRound
        )
        status = try container.decodeIfPresent(String.self, forKey: .status)
        submittedAt = try container.decodeIfPresent(String.self, forKey: .submittedAt)
        statusChangedAt = try container.decodeIfPresent(String.self, forKey: .statusChangedAt)
        formResponse = try container.decodeIfPresent(FormResponseDTO.self, forKey: .formResponse)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(applicationId, forKey: .applicationId)
        try container.encode(applicant, forKey: .applicant)
        try container.encodeIfPresent(matchingRound, forKey: .matchingRound)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(submittedAt, forKey: .submittedAt)
        try container.encodeIfPresent(statusChangedAt, forKey: .statusChangedAt)
        try container.encodeIfPresent(formResponse, forKey: .formResponse)
    }

    public func toDomain() -> ProjectApplicationDetail {
        ProjectApplicationDetail(
            applicationId: applicationId,
            applicant: applicant.toDomain(),
            matchingRound: matchingRound?.toDomain(),
            status: status.map { ProjectApplicationStatus(rawValue: $0) ?? .unknown },
            submittedAt: submittedAt.flatMap(ServerDateTimeConverter.parseUTCDateTime),
            statusChangedAt: statusChangedAt.flatMap(ServerDateTimeConverter.parseUTCDateTime),
            formResponse: formResponse?.toDomain()
        )
    }

    /// 폼 응답 (서버 `FormResponseView`) — 질문마다 답변이 붙은 폼 구조.
    public struct FormResponseDTO: Codable {
        let formResponseId: String
        let formId: String
        let status: String?
        let submittedAt: String?
        let lastSavedAt: String?
        let sections: [ProjectFormSectionDTO]

        private enum CodingKeys: String, CodingKey {
            case formResponseId, formId, status, submittedAt, lastSavedAt, sections
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            formResponseId = try container.decodeFlexibleString(forKey: .formResponseId)
            formId = try container.decodeFlexibleString(forKey: .formId)
            status = try container.decodeIfPresent(String.self, forKey: .status)
            submittedAt = try container.decodeIfPresent(String.self, forKey: .submittedAt)
            lastSavedAt = try container.decodeIfPresent(String.self, forKey: .lastSavedAt)
            sections = try container.decodeIfPresent(
                [ProjectFormSectionDTO].self,
                forKey: .sections
            ) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(formResponseId, forKey: .formResponseId)
            try container.encode(formId, forKey: .formId)
            try container.encodeIfPresent(status, forKey: .status)
            try container.encodeIfPresent(submittedAt, forKey: .submittedAt)
            try container.encodeIfPresent(lastSavedAt, forKey: .lastSavedAt)
            try container.encode(sections, forKey: .sections)
        }

        func toDomain() -> ProjectFormResponse {
            ProjectFormResponse(
                formResponseId: formResponseId,
                formId: formId,
                status: status.flatMap(ProjectFormResponseStatus.init(rawValue:)) ?? .unknown,
                submittedAt: submittedAt.flatMap(ServerDateTimeConverter.parseUTCDateTime),
                lastSavedAt: lastSavedAt.flatMap(ServerDateTimeConverter.parseUTCDateTime),
                sections: sections.map { $0.toDomain() }
            )
        }
    }
}
