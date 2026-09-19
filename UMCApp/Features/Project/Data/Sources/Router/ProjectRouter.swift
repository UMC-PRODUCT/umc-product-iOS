//
//  ProjectRouter.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import Moya
import CoreNetwork

/// 프로젝트 API 라우터 (`/api/v1/projects`).
///
/// 조회·관리·지원 폼·지원서·권한·통계 32개. 매칭 차수는 ``ProjectMatchingRoundRouter``.
/// Deprecated 인 `GET /{projectId}/statistics` 는 넣지 않는다.
public enum ProjectRouter {

    // MARK: - Query

    /// 프로젝트 목록
    case searchProjects(query: ProjectSearchQueryDTO)
    /// 프로젝트 상세
    case getProject(projectId: String)
    /// 팀 구성
    case getMembers(projectId: String)
    /// 여러 프로젝트의 팀 구성
    case getMembersBatch(query: ProjectIdsQueryDTO)
    /// 내가 관리하는 프로젝트 목록
    case getManagedProjects(query: ProjectManagedQueryDTO)
    /// 내 임시저장 프로젝트
    case getDraftProject(query: ProjectGisuQueryDTO)

    // MARK: - Command

    /// 임시저장 프로젝트 생성
    case createDraftProject(body: CreateDraftProjectRequestDTO)
    /// 기본 정보 수정
    case updateProject(projectId: String, body: UpdateProjectRequestDTO)
    /// 검토 요청
    case submitProject(projectId: String)
    /// PO 위임
    case transferOwnership(projectId: String, body: TransferProjectOwnershipRequestDTO)
    /// 팀원 추가
    case addMember(projectId: String, body: AddProjectMemberRequestDTO)
    /// 팀원 제외
    case removeMember(projectId: String, memberId: String, query: ProjectReasonQueryDTO)
    /// 팀원 상태 변경
    case changeMemberStatus(
        projectId: String,
        memberId: String,
        body: ChangeProjectMemberStatusRequestDTO
    )
    /// 프로젝트 삭제
    case deleteProject(projectId: String)
    /// 공개 승인
    case publishProject(projectId: String)
    /// 파트 TO 일괄 설정
    case updatePartQuotas(projectId: String, body: UpdatePartQuotasRequestDTO)
    /// 중단
    case abortProject(projectId: String, body: AbortProjectRequestDTO)
    /// 일괄 완료
    case completeProjects(body: CompleteProjectsRequestDTO)

    // MARK: - Application Form

    /// 지원 폼 조회
    case getApplicationForm(projectId: String)
    /// 지원 폼 저장
    case saveApplicationForm(projectId: String, body: UpsertApplicationFormRequestDTO)

    // MARK: - Application

    /// 지원서 생성
    case createApplication(projectId: String, body: CreateProjectApplicationRequestDTO)
    /// 답변 저장
    case updateAnswers(
        projectId: String,
        applicationId: String,
        body: UpdateApplicationAnswersRequestDTO
    )
    /// 지원 취소
    case cancelApplication(projectId: String, applicationId: String, query: ProjectReasonQueryDTO)
    /// 지원서 제출
    case submitApplication(projectId: String, applicationId: String)
    /// 합격·불합격 결정
    case decideApplication(
        projectId: String,
        applicationId: String,
        body: UpdateApplicationDecisionRequestDTO
    )

    // MARK: - Application Query

    /// 내 지원 내역
    case getMyApplications(query: ProjectMyApplicationsQueryDTO)
    /// 여러 프로젝트의 지원서 목록
    case getApplicationsBatch(query: ProjectApplicationsQueryDTO)
    /// 프로젝트 하나의 지원서 목록
    case getApplications(projectId: String, query: ProjectApplicationsQueryDTO)
    /// 지원서 상세
    case getApplication(projectId: String, applicationId: String)

    // MARK: - Permission · Statistics

    /// 여러 프로젝트에 대한 내 권한
    case getPermissions(query: ProjectIdsQueryDTO)
    /// 지원 통계
    case getStatistics(query: ProjectStatisticsQueryDTO)
    /// 지부 매칭 통계
    case getMatchingStatistics(query: ProjectChapterQueryDTO)
}

// MARK: - BaseTargetType

extension ProjectRouter: BaseTargetType {

    /// 배열 쿼리를 `ids=1&ids=2` 로 싣는다 — Moya 기본값(`ids[]=`)은 Spring 이 못 읽는다.
    static let queryEncoding = URLEncoding(destination: .queryString, arrayEncoding: .noBrackets)

    private static let basePath = "/api/v1/projects"

    public var path: String {
        let base = Self.basePath
        switch self {
        case .searchProjects, .createDraftProject:
            return base
        case .getProject(let projectId),
             .updateProject(let projectId, _),
             .deleteProject(let projectId):
            return "\(base)/\(projectId)"
        case .getMembers(let projectId), .addMember(let projectId, _):
            return "\(base)/\(projectId)/members"
        case .getMembersBatch:
            return "\(base)/members"
        case .getManagedProjects:
            return "\(base)/me/managed"
        case .getDraftProject:
            return "\(base)/me/draft"
        case .submitProject(let projectId):
            return "\(base)/\(projectId)/submit"
        case .transferOwnership(let projectId, _):
            return "\(base)/\(projectId)/transfer-ownership"
        case .removeMember(let projectId, let memberId, _):
            return "\(base)/\(projectId)/members/\(memberId)"
        case .changeMemberStatus(let projectId, let memberId, _):
            return "\(base)/\(projectId)/members/\(memberId)/status"
        case .publishProject(let projectId):
            return "\(base)/\(projectId)/publish"
        case .updatePartQuotas(let projectId, _):
            return "\(base)/\(projectId)/part-quotas"
        case .abortProject(let projectId, _):
            return "\(base)/\(projectId)/abort"
        case .completeProjects:
            return "\(base)/complete"
        case .getApplicationForm(let projectId), .saveApplicationForm(let projectId, _):
            return "\(base)/\(projectId)/application-form"
        case .createApplication(let projectId, _), .getApplications(let projectId, _):
            return "\(base)/\(projectId)/applications"
        case .updateAnswers(let projectId, let applicationId, _),
             .cancelApplication(let projectId, let applicationId, _),
             .getApplication(let projectId, let applicationId):
            return "\(base)/\(projectId)/applications/\(applicationId)"
        case .submitApplication(let projectId, let applicationId):
            return "\(base)/\(projectId)/applications/\(applicationId)/submit"
        case .decideApplication(let projectId, let applicationId, _):
            return "\(base)/\(projectId)/applications/\(applicationId)/decision"
        case .getMyApplications:
            return "\(base)/me/applications"
        case .getApplicationsBatch:
            return "\(base)/applications"
        case .getPermissions:
            return "\(base)/permissions"
        case .getStatistics:
            return "\(base)/statistics"
        case .getMatchingStatistics:
            return "\(base)/statistics/matchings"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .searchProjects, .getProject, .getMembers, .getMembersBatch,
             .getManagedProjects, .getDraftProject, .getApplicationForm,
             .getMyApplications, .getApplicationsBatch, .getApplications,
             .getApplication, .getPermissions, .getStatistics, .getMatchingStatistics:
            return .get
        case .createDraftProject, .submitProject, .transferOwnership, .addMember,
             .publishProject, .abortProject, .completeProjects, .createApplication,
             .submitApplication:
            return .post
        case .updateProject, .changeMemberStatus, .decideApplication:
            return .patch
        case .updatePartQuotas, .saveApplicationForm, .updateAnswers:
            return .put
        case .removeMember, .deleteProject, .cancelApplication:
            return .delete
        }
    }

    public var task: Moya.Task {
        switch self {
        case .getProject, .getMembers, .submitProject, .deleteProject, .publishProject,
             .getApplicationForm, .submitApplication, .getApplication:
            return .requestPlain

        case .searchProjects(let query):
            return .requestParameters(parameters: query.toParameters, encoding: Self.queryEncoding)
        case .getMembersBatch(let query), .getPermissions(let query):
            return .requestParameters(parameters: query.toParameters, encoding: Self.queryEncoding)
        case .getManagedProjects(let query):
            return .requestParameters(parameters: query.toParameters, encoding: Self.queryEncoding)
        case .getDraftProject(let query):
            return .requestParameters(parameters: query.toParameters, encoding: Self.queryEncoding)
        case .removeMember(_, _, let query), .cancelApplication(_, _, let query):
            return .requestParameters(parameters: query.toParameters, encoding: Self.queryEncoding)
        case .getMyApplications(let query):
            return .requestParameters(parameters: query.toParameters, encoding: Self.queryEncoding)
        case .getApplicationsBatch(let query), .getApplications(_, let query):
            return .requestParameters(parameters: query.toParameters, encoding: Self.queryEncoding)
        case .getStatistics(let query):
            return .requestParameters(parameters: query.toParameters, encoding: Self.queryEncoding)
        case .getMatchingStatistics(let query):
            return .requestParameters(parameters: query.toParameters, encoding: Self.queryEncoding)

        case .createDraftProject(let body):
            return .requestJSONEncodable(body)
        case .updateProject(_, let body):
            return .requestJSONEncodable(body)
        case .transferOwnership(_, let body):
            return .requestJSONEncodable(body)
        case .addMember(_, let body):
            return .requestJSONEncodable(body)
        case .changeMemberStatus(_, _, let body):
            return .requestJSONEncodable(body)
        case .updatePartQuotas(_, let body):
            return .requestJSONEncodable(body)
        case .abortProject(_, let body):
            return .requestJSONEncodable(body)
        case .completeProjects(let body):
            return .requestJSONEncodable(body)
        case .saveApplicationForm(_, let body):
            return .requestJSONEncodable(body)
        case .createApplication(_, let body):
            return .requestJSONEncodable(body)
        case .updateAnswers(_, _, let body):
            return .requestJSONEncodable(body)
        case .decideApplication(_, _, let body):
            return .requestJSONEncodable(body)
        }
    }
}
