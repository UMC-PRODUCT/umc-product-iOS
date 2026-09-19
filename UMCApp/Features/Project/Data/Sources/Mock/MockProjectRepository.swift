//
//  MockProjectRepository.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//

#if DEBUG
import Foundation
import UMCFoundation
import ProjectDomain

/// 네트워크 없이 프로젝트 화면(#1476~)을 돌려 보기 위한 Mock. 세 저장소 프로토콜을 모두 따른다.
///
/// 명령은 성공만 흉내 내고 상태를 바꾸지 않는다. 릴리스 빌드에는 포함되지 않는다(핵심 규칙 #5).
public struct MockProjectRepository:
    ProjectRepositoryProtocol,
    ProjectApplicationRepositoryProtocol,
    ProjectMatchingRoundRepositoryProtocol {

    // MARK: - Init

    public init() {}

    // MARK: - Project Query

    public func fetchProjects(query: ProjectSearchQuery) async throws
        -> ProjectPage<ProjectSummary> {
        Self.page([Self.summary])
    }

    public func fetchProject(projectId: String) async throws -> ProjectDetail {
        Self.detail
    }

    public func fetchMembers(projectId: String) async throws -> ProjectMembers {
        Self.members
    }

    public func fetchMembers(projectIds: [String]) async throws -> [String: ProjectMembers] {
        Dictionary(uniqueKeysWithValues: projectIds.map { ($0, Self.members) })
    }

    public func fetchManagedProjects(
        gisuId: String,
        keyword: String?,
        page: Int,
        size: Int
    ) async throws -> ProjectPage<ProjectSummary> {
        Self.page([Self.summary])
    }

    public func fetchDraftProject(gisuId: String) async throws -> ProjectDetail? {
        nil
    }

    // MARK: - Project Command

    public func createDraftProject(
        gisuId: String,
        productOwnerMemberId: String?
    ) async throws -> ProjectStatusResult {
        ProjectStatusResult(projectId: Self.projectId, status: .draft)
    }

    public func updateProject(projectId: String, update: ProjectInfoUpdate) async throws
        -> ProjectStatusResult {
        ProjectStatusResult(projectId: projectId, status: .draft)
    }

    public func submitProject(projectId: String) async throws -> ProjectStatusResult {
        ProjectStatusResult(projectId: projectId, status: .pendingReview)
    }

    public func transferOwnership(
        projectId: String,
        newOwnerMemberId: String,
        reason: String?
    ) async throws -> ProjectStatusResult {
        ProjectStatusResult(projectId: projectId, status: .inProgress)
    }

    public func addMember(projectId: String, memberId: String, part: UMCPartType) async throws
        -> String {
        "501"
    }

    public func removeMember(projectId: String, memberId: String, reason: String?) async throws {}

    public func changeMemberStatus(
        projectId: String,
        memberId: String,
        status: ProjectMemberStatus,
        reason: String
    ) async throws {}

    public func deleteProject(projectId: String) async throws {}

    public func publishProject(projectId: String) async throws -> ProjectStatusResult {
        ProjectStatusResult(projectId: projectId, status: .inProgress)
    }

    public func updatePartQuotas(
        projectId: String,
        entries: [ProjectPartQuotaEntry]
    ) async throws {}

    public func abortProject(projectId: String, reason: String) async throws {}

    public func completeProjects(projectIds: [String]) async throws {}

    // MARK: - Permission

    /// 화면 분기를 전부 열어 볼 수 있게 모든 권한을 허용한다.
    public func fetchPermissions(projectIds: [String]) async throws -> [ProjectPermission] {
        let allowed = ProjectCapability(allowed: true)
        return projectIds.map {
            ProjectPermission(
                projectId: $0,
                exists: true,
                canEditInfo: allowed,
                canTransferOwnership: allowed,
                canDelete: allowed,
                applicationForm: .init(
                    canRead: allowed,
                    canCreate: allowed,
                    canEdit: allowed,
                    canPublish: allowed,
                    canDelete: allowed
                ),
                partQuota: .init(canEdit: allowed),
                status: .init(
                    canRequestReview: allowed,
                    canPublish: allowed,
                    canComplete: allowed,
                    canAbort: allowed
                ),
                application: .init(canCreate: allowed, canReadList: allowed, canDecide: allowed),
                member: .init(canRead: allowed, canCreate: allowed, canDelete: allowed),
                statistics: .init(canRead: allowed)
            )
        }
    }

    // MARK: - Statistics

    public func fetchStatistics(projectIds: [String]) async throws -> ProjectChapterStatistics {
        ProjectChapterStatistics(chapterId: nil, projects: [], summary: nil)
    }

    public func fetchStatistics(chapterId: String) async throws -> ProjectChapterStatistics {
        ProjectChapterStatistics(chapterId: chapterId, projects: [], summary: nil)
    }

    public func fetchMatchingStatistics(chapterId: String) async throws
        -> ProjectChapterMatchingStatistics {
        ProjectChapterMatchingStatistics(
            chapterId: chapterId,
            roundMatchingStatistics: [],
            schoolMatchingStatistics: [],
            unclassifiedMatchingStatistics: nil
        )
    }

    // MARK: - Application Form

    public func fetchApplicationForm(projectId: String) async throws -> ProjectApplicationForm? {
        Self.form
    }

    public func saveApplicationForm(
        projectId: String,
        title: String?,
        description: String?,
        sections: [ProjectFormSection]
    ) async throws -> ProjectApplicationForm {
        ProjectApplicationForm(
            projectId: projectId,
            applicationFormId: Self.form.applicationFormId,
            title: title,
            description: description,
            sections: sections
        )
    }

    // MARK: - Application Command

    public func createApplication(projectId: String, matchingRoundId: String) async throws
        -> ProjectApplicationResult {
        ProjectApplicationResult(applicationId: Self.applicationId, status: .draft)
    }

    public func updateAnswers(
        projectId: String,
        applicationId: String,
        answers: [ProjectAnswerInput]
    ) async throws -> ProjectApplicationResult {
        ProjectApplicationResult(applicationId: applicationId, status: .draft)
    }

    public func submitApplication(projectId: String, applicationId: String) async throws
        -> ProjectApplicationResult {
        ProjectApplicationResult(applicationId: applicationId, status: .submitted)
    }

    public func cancelApplication(
        projectId: String,
        applicationId: String,
        reason: String?
    ) async throws -> ProjectApplicationResult {
        ProjectApplicationResult(applicationId: applicationId, status: .cancelled)
    }

    public func decideApplication(
        projectId: String,
        applicationId: String,
        decision: ProjectApplicationDecision,
        reason: String?
    ) async throws -> ProjectApplicationResult {
        ProjectApplicationResult(
            applicationId: applicationId,
            status: decision == .approved ? .approved : .rejected
        )
    }

    // MARK: - Application Query

    public func fetchMyApplications(
        gisuId: String,
        status: ProjectApplicationStatus?
    ) async throws -> [MyProjectApplication] {
        [
            MyProjectApplication(
                applicationId: Self.applicationId,
                projectId: Self.projectId,
                project: Self.summary,
                matchingRound: Self.roundBrief,
                status: .submitted
            )
        ]
    }

    public func fetchApplications(
        projectIds: [String],
        filter: ProjectApplicationFilter
    ) async throws -> [String: [ProjectApplicationSummary]] {
        Dictionary(uniqueKeysWithValues: projectIds.map { ($0, [Self.applicationSummary]) })
    }

    public func fetchApplications(
        projectId: String,
        filter: ProjectApplicationFilter
    ) async throws -> [ProjectApplicationSummary] {
        [Self.applicationSummary]
    }

    public func fetchApplication(projectId: String, applicationId: String) async throws
        -> ProjectApplicationDetail {
        ProjectApplicationDetail(
            applicationId: applicationId,
            applicant: Self.applicant,
            matchingRound: Self.roundBrief,
            status: .submitted,
            submittedAt: Date(),
            statusChangedAt: nil,
            formResponse: nil
        )
    }

    // MARK: - Matching Round

    public func fetchMatchingRounds(chapterId: String?, time: Date?) async throws
        -> [ProjectMatchingRound] {
        let now = Date()
        return [
            ProjectMatchingRound(
                id: Self.matchingRoundId,
                name: "1차 매칭",
                description: nil,
                type: .planDeveloper,
                phase: .first,
                chapterId: chapterId ?? "1",
                startsAt: now,
                endsAt: now.addingTimeInterval(3 * 24 * 3600),
                decisionDeadline: now.addingTimeInterval(5 * 24 * 3600),
                autoDecisionExecutedAt: nil,
                autoDecisionExecutedMemberId: nil,
                createdAt: now,
                updatedAt: now
            )
        ]
    }

    public func createMatchingRound(_ draft: ProjectMatchingRoundDraft) async throws -> String {
        Self.matchingRoundId
    }

    public func updateMatchingRound(
        matchingRoundId: String,
        update: ProjectMatchingRoundUpdate
    ) async throws {}

    public func deleteMatchingRound(matchingRoundId: String) async throws {}

    public func autoDecide(matchingRoundId: String) async throws {}
}

// MARK: - Sample

private extension MockProjectRepository {
    static let projectId = "101"
    static let applicationId = "301"
    static let matchingRoundId = "11"

    static let owner = ProjectMemberBrief(
        memberId: "7",
        nickname: "피오",
        name: "홍길동",
        schoolName: "UMC대학교"
    )

    static let partQuotas = [
        ProjectPartQuota(part: .design, currentCount: "1", quota: "2", status: .recruiting),
        ProjectPartQuota(
            part: .server(type: .spring),
            currentCount: "2",
            quota: "2",
            status: .completed
        )
    ]

    static let summary = ProjectSummary(
        id: projectId,
        name: "UMC 운영 앱",
        description: "동아리 운영 도구를 하나로 모은다.",
        thumbnailImageURL: nil,
        status: .inProgress,
        productOwner: owner,
        partQuotas: partQuotas,
        partQuotaStatus: .recruiting
    )

    static let detail = ProjectDetail(
        id: projectId,
        status: .inProgress,
        name: summary.name,
        description: summary.description,
        thumbnailImageURL: nil,
        logoImageURL: nil,
        externalLink: "https://umc.makeus.in",
        productOwner: owner,
        coProductOwners: [],
        partQuotas: partQuotas,
        partQuotaStatus: .recruiting,
        applicationFormId: "201"
    )

    static let roundBrief = ProjectMatchingRoundBrief(
        id: matchingRoundId,
        type: .planDeveloper,
        phase: .first
    )

    static let members = ProjectMembers(
        projectId: projectId,
        productOwner: ProjectTeamMember(
            memberId: owner.memberId,
            nickname: owner.nickname,
            name: owner.name,
            schoolName: owner.schoolName,
            matchedRound: nil
        ),
        coProductOwners: [],
        partGroups: [
            ProjectPartMembers(
                part: .design,
                members: [
                    ProjectTeamMember(
                        memberId: "8",
                        nickname: "디자이너",
                        name: "김철수",
                        schoolName: "UMC대학교",
                        matchedRound: roundBrief
                    )
                ]
            )
        ]
    )

    static let applicant = ProjectApplicant(
        memberId: "9",
        nickname: "지원자",
        name: "이영희",
        schoolName: "UMC대학교",
        part: .design
    )

    static let applicationSummary = ProjectApplicationSummary(
        applicationId: applicationId,
        applicant: applicant,
        matchingRound: roundBrief,
        status: .submitted,
        submittedAt: Date(),
        statusChangedAt: nil
    )

    static let form = ProjectApplicationForm(
        projectId: projectId,
        applicationFormId: "201",
        title: "UMC 운영 앱 지원서",
        description: nil,
        sections: [
            ProjectFormSection(
                sectionId: "1",
                type: .common,
                allowedParts: [],
                title: "공통 질문",
                description: nil,
                orderNo: "1",
                questions: [
                    ProjectFormQuestion(
                        questionId: "1",
                        type: .longText,
                        title: "지원 동기를 적어 주세요.",
                        description: nil,
                        isRequired: true,
                        orderNo: "1",
                        options: []
                    )
                ]
            )
        ]
    )

    static func page(_ items: [ProjectSummary]) -> ProjectPage<ProjectSummary> {
        ProjectPage(
            items: items,
            page: "0",
            size: "20",
            totalElements: String(items.count),
            totalPages: "1",
            hasNext: false,
            hasPrevious: false
        )
    }
}
#endif
