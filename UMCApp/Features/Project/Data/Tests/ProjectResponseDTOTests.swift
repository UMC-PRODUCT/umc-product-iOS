//
//  ProjectResponseDTOTests.swift
//  ProjectDataTests
//
//  Created by euijjang97 on 9/19/26.
//
//  서버는 Long 을 문자열로 직렬화하지만(`WRITE_NUMBERS_AS_STRINGS`), 원시 `long`·`int`
//  필드는 숫자로 올 수 있다. 두 형태가 섞여도 전부 `String` 으로 받는지, 모르는 enum·파트와
//  `null` 을 화면이 버틸 수 있는 값으로 바꾸는지 검증한다.
//

import Foundation
import Testing
import CoreNetwork
import UMCFoundation
import ProjectDomain
@testable import ProjectData

@Suite("Project Response DTO 디코딩")
struct ProjectResponseDTOTests {

    // MARK: - Project

    @Test("목록 페이지 — 문자열·숫자 id 와 인원 수를 모두 String 으로 받는다")
    func summaryPageDecodesMixedNumbers() throws {
        let json = """
        {
          "content": [{
            "id": "101",
            "name": "UMC 운영 앱",
            "status": "IN_PROGRESS",
            "productOwner": { "memberId": 7, "nickname": "피오" },
            "partQuotas": [
              { "part": "DESIGN", "currentCount": 1, "quota": "2", "status": "RECRUITING" },
              { "part": "NEW_PART", "currentCount": 0, "quota": 1, "status": "RECRUITING" }
            ],
            "partQuotaStatus": "RECRUITING"
          }],
          "page": 0, "size": "20", "totalElements": "1", "totalPages": 1,
          "hasNext": false, "hasPrevious": false
        }
        """

        let page = try decode(ProjectPageResponseDTO<ProjectSummaryResponseDTO>.self, json)
            .toDomain { $0.toDomain() }

        let summary = try #require(page.items.first)
        #expect(summary.id == "101")
        #expect(summary.productOwner?.memberId == "7")
        #expect(summary.status == .inProgress)
        // 모르는 파트는 버린다.
        #expect(summary.partQuotas == [
            ProjectPartQuota(part: .design, currentCount: "1", quota: "2", status: .recruiting)
        ])
        #expect(page.page == "0")
        #expect(page.totalPages == "1")
        #expect(page.hasNext == false)
    }

    @Test("모르는 프로젝트 상태는 .unknown 으로 받는다")
    func unknownStatusFallsBack() throws {
        let json = #"{ "id": 1, "name": "A", "status": "ARCHIVED" }"#

        let summary = try decode(ProjectSummaryResponseDTO.self, json).toDomain()

        #expect(summary.status == .unknown)
        #expect(summary.partQuotas.isEmpty)
    }

    @Test("팀원 일괄 조회 — Map<Long, …> 의 키를 프로젝트 id 로 받는다")
    func membersBatchMapKeys() throws {
        let json = """
        {
          "success": true, "code": "COMMON200", "message": "OK",
          "result": {
            "101": {
              "projectId": "101",
              "productOwner": { "memberId": "7", "nickname": "피오" },
              "coProductOwners": [],
              "partGroups": [{
                "part": "IOS",
                "members": [{
                  "memberId": 8,
                  "matchedRoundInfo": { "matchingRoundId": "11", "type": "PLAN_DEVELOPER",
                                        "phase": "FIRST" }
                }]
              }]
            }
          }
        }
        """

        let members = try decode(APIResponse<[String: ProjectMembersResponseDTO]>.self, json)
            .unwrap()
            .mapValues { $0.toDomain() }

        let project = try #require(members["101"])
        #expect(project.productOwner?.memberId == "7")
        #expect(project.partGroups.first?.part == .front(type: .ios))
        let round = try #require(project.partGroups.first?.members.first?.matchedRound)
        // `matchingRoundId` 키로 와도 id 로 읽는다.
        #expect(round == ProjectMatchingRoundBrief(id: "11", type: .planDeveloper, phase: .first))
    }

    @Test("PO 추가 응답 — 원시 Long 을 문자열로 받는다")
    func identifierDecodesNumberOrString() throws {
        #expect(try decode(ProjectIdentifierResponseDTO.self, "501").value == "501")
        #expect(try decode(ProjectIdentifierResponseDTO.self, #""501""#).value == "501")
    }

    // MARK: - Permission

    @Test("권한 — 빠진 칸은 거부로, 있는 칸은 사유까지 받는다")
    func permissionMissingCapabilityIsDenied() throws {
        let json = """
        {
          "projects": [{
            "projectId": 101,
            "exists": true,
            "canEditInfo": { "allowed": true },
            "status": {
              "canPublish": { "allowed": false, "reasonCode": "NOT_PENDING",
                              "reason": "검토 대기 상태가 아닙니다." }
            }
          }]
        }
        """

        let permission = try #require(
            try decode(ProjectPermissionsResponseDTO.self, json).toDomain().first
        )

        #expect(permission.projectId == "101")
        #expect(permission.canEditInfo.allowed)
        #expect(permission.canDelete == .denied)
        #expect(permission.status.canPublish.reasonCode == "NOT_PENDING")
        #expect(permission.status.canAbort == .denied)
        #expect(permission.applicationForm.canRead == .denied)
    }

    // MARK: - Application

    @Test("내 지원 내역 — 랜덤 매칭은 지원서·차수 id 가 null 이다")
    func myApplicationRandomMatched() throws {
        let json = """
        [{
          "applicationId": null,
          "projectId": 101,
          "project": { "name": "UMC 운영 앱", "partQuotas": [] },
          "matchingRound": { "id": null, "type": null, "phase": "RANDOM_MATCHING" },
          "status": "APPROVED"
        }]
        """

        let application = try #require(
            try decode([MyProjectApplicationResponseDTO].self, json).first?.toDomain()
        )

        #expect(application.applicationId == nil)
        #expect(application.projectId == "101")
        #expect(application.project?.id == "101")
        #expect(application.matchingRound?.id == nil)
        #expect(application.matchingRound?.phase == .randomMatching)
        #expect(application.status == .approved)
    }

    @Test("지원서 상세 — 답변의 id·순서·시각을 풀고 모르는 파트는 버린다")
    func applicationDetailDecodesAnswers() throws {
        let json = """
        {
          "applicationId": "301",
          "applicant": { "memberId": 9, "part": "DESIGN" },
          "matchingRound": { "id": 11, "type": "PLAN_DESIGN", "phase": "SECOND" },
          "status": "SUBMITTED",
          "submittedAt": "2026-09-01T03:00:00.123Z",
          "statusChangedAt": null,
          "formResponse": {
            "formResponseId": 401, "formId": "201", "status": "SUBMITTED",
            "submittedAt": "2026-09-01T03:00:00Z", "lastSavedAt": "2026-09-01T02:59:00Z",
            "sections": [{
              "sectionId": 1, "type": "PART", "allowedParts": ["DESIGN", "NEW_PART"],
              "title": "디자인", "orderNo": 1,
              "questions": [{
                "questionId": "5", "type": "SCHEDULE", "title": "가능한 시간",
                "isRequired": true, "orderNo": "1",
                "options": [{ "optionId": 6, "content": "오전", "orderNo": 1, "isOther": false }],
                "answer": {
                  "answerId": 7, "answeredAsType": "SCHEDULE",
                  "selectedOptions": [{ "questionOptionId": 6, "answeredAsContent": "오전" }],
                  "files": [{ "fileId": "f-1", "originalFileName": "a.pdf" }],
                  "times": ["2026-09-02T01:00:00Z", "2026-09-01T01:00:00Z", "not-a-date"]
                }
              }]
            }]
          }
        }
        """

        let detail = try decode(ProjectApplicationDetailResponseDTO.self, json).toDomain()

        #expect(detail.applicant.memberId == "9")
        #expect(detail.applicant.part == .design)
        #expect(detail.statusChangedAt == nil)
        #expect(detail.submittedAt != nil)
        let form = try #require(detail.formResponse)
        #expect(form.formResponseId == "401")
        let section = try #require(form.sections.first)
        #expect(section.sectionId == "1")
        #expect(section.type == .part)
        #expect(section.allowedParts == [.design])
        let question = try #require(section.questions.first)
        #expect(question.options.first?.optionId == "6")
        let answer = try #require(question.answer)
        #expect(answer.answerId == "7")
        #expect(answer.selectedOptions.first?.questionOptionId == "6")
        #expect(answer.files.first?.fileId == "f-1")
        // 해석할 수 없는 시각은 버리고 시간순으로 맞춘다.
        #expect(answer.times.count == 2)
        #expect(answer.times == answer.times.sorted())
    }

    @Test("지원서 목록 — 상태가 빠지면 .unknown 으로 받는다")
    func applicationSummaryMissingStatus() throws {
        let json = #"{ "applicationId": 301, "applicant": { "memberId": "9" } }"#

        let summary = try decode(ProjectApplicationSummaryResponseDTO.self, json).toDomain()

        #expect(summary.applicationId == "301")
        #expect(summary.status == .unknown)
        #expect(summary.matchingRound == nil)
    }

    // MARK: - Matching Round

    @Test("매칭 차수 — 숫자 id 와 UTC 시각을 받는다")
    func matchingRoundDecodes() throws {
        let json = """
        {
          "id": 11, "name": "1차 매칭", "type": "PLAN_DEVELOPER", "phase": "FIRST",
          "chapterId": "5", "startsAt": "2026-09-01T00:00:00Z",
          "endsAt": "2026-09-03T00:00:00Z", "decisionDeadline": "2026-09-05T00:00:00Z",
          "autoDecisionExecutedAt": null, "autoDecisionExecutedMemberId": null
        }
        """

        let round = try decode(ProjectMatchingRoundResponseDTO.self, json).toDomain()

        #expect(round.id == "11")
        #expect(round.chapterId == "5")
        #expect(round.phase == .first)
        #expect(round.startsAt == Date(timeIntervalSince1970: 1_788_220_800))
        #expect(round.autoDecisionExecutedAt == nil)
    }
}

// MARK: - Helper

private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
    try JSONDecoder().decode(type, from: Data(json.utf8))
}
