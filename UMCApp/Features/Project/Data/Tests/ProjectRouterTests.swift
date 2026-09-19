//
//  ProjectRouterTests.swift
//  ProjectDataTests
//
//  Created by euijjang97 on 9/19/26.
//
//  프로젝트 API 37개 엔드포인트의 path·method·task 계약과 쿼리·본문 인코딩을 검증한다.
//  서버 스펙: cygnus-server `ProjectQueryController` 외 7개 컨트롤러.
//

import Foundation
import Testing
import Moya
import CoreNetwork
import UMCFoundation
import ProjectDomain
@testable import ProjectData

@Suite("ProjectRouter")
struct ProjectRouterTests {

    // MARK: - Contract

    @Test("ProjectRouter 32개 케이스의 path·method·task 가 서버 스펙과 같다")
    func projectRouterContract() throws {
        let base = "/api/v1/projects"
        let reason = ProjectReasonQueryDTO(reason: "사유")
        let filter = ProjectApplicationFilter()
        var checkedCount = 0
        func check(
            _ router: ProjectRouter,
            _ path: String,
            _ method: Moya.Method,
            _ kind: TaskKind,
            sourceLocation: SourceLocation = #_sourceLocation
        ) {
            checkedCount += 1
            expectContract(router, path, method, kind, sourceLocation: sourceLocation)
        }

        check(.searchProjects(query: .init(query: .init(gisuId: "9"))), base, .get, .query)
        check(.getProject(projectId: "1"), "\(base)/1", .get, .plain)
        check(.getMembers(projectId: "1"), "\(base)/1/members", .get, .plain)
        check(.getMembersBatch(query: .init(projectIds: ["1"])), "\(base)/members", .get, .query)
        check(
            .getManagedProjects(query: .init(gisuId: "9", keyword: nil, page: 0, size: 20)),
            "\(base)/me/managed", .get, .query
        )
        check(.getDraftProject(query: .init(gisuId: "9")), "\(base)/me/draft", .get, .query)
        check(
            .createDraftProject(body: .init(gisuId: 9, productOwnerMemberId: nil)),
            base, .post, .json
        )
        check(
            .updateProject(projectId: "1", body: .init(update: .init())),
            "\(base)/1", .patch, .json
        )
        check(.submitProject(projectId: "1"), "\(base)/1/submit", .post, .plain)
        check(
            .transferOwnership(projectId: "1", body: .init(newOwnerMemberId: 2, reason: nil)),
            "\(base)/1/transfer-ownership", .post, .json
        )
        check(
            .addMember(projectId: "1", body: .init(memberId: 2, part: .design)),
            "\(base)/1/members", .post, .json
        )
        check(
            .removeMember(projectId: "1", memberId: "2", query: reason),
            "\(base)/1/members/2", .delete, .query
        )
        check(
            .changeMemberStatus(
                projectId: "1",
                memberId: "2",
                body: .init(status: .withdrawn, reason: "사유")
            ),
            "\(base)/1/members/2/status", .patch, .json
        )
        check(.deleteProject(projectId: "1"), "\(base)/1", .delete, .plain)
        check(.publishProject(projectId: "1"), "\(base)/1/publish", .post, .plain)
        check(
            .updatePartQuotas(projectId: "1", body: try .init(entries: [])),
            "\(base)/1/part-quotas", .put, .json
        )
        check(
            .abortProject(projectId: "1", body: .init(reason: "사유")),
            "\(base)/1/abort", .post, .json
        )
        check(
            .completeProjects(body: try .init(projectIds: ["1"])),
            "\(base)/complete", .post, .json
        )
        check(.getApplicationForm(projectId: "1"), "\(base)/1/application-form", .get, .plain)
        check(
            .saveApplicationForm(
                projectId: "1",
                body: try .init(title: nil, description: nil, sections: [])
            ),
            "\(base)/1/application-form", .put, .json
        )
        check(
            .createApplication(projectId: "1", body: .init(matchingRoundId: 3)),
            "\(base)/1/applications", .post, .json
        )
        check(
            .updateAnswers(projectId: "1", applicationId: "4", body: try .init(answers: [])),
            "\(base)/1/applications/4", .put, .json
        )
        check(
            .cancelApplication(projectId: "1", applicationId: "4", query: reason),
            "\(base)/1/applications/4", .delete, .query
        )
        check(
            .submitApplication(projectId: "1", applicationId: "4"),
            "\(base)/1/applications/4/submit", .post, .plain
        )
        check(
            .decideApplication(
                projectId: "1",
                applicationId: "4",
                body: .init(decision: .approved, reason: nil)
            ),
            "\(base)/1/applications/4/decision", .patch, .json
        )
        check(
            .getMyApplications(query: .init(gisuId: "9", status: nil)),
            "\(base)/me/applications", .get, .query
        )
        check(
            .getApplicationsBatch(query: .init(projectIds: ["1"], filter: filter)),
            "\(base)/applications", .get, .query
        )
        check(
            .getApplications(projectId: "1", query: .init(filter: filter)),
            "\(base)/1/applications", .get, .query
        )
        check(
            .getApplication(projectId: "1", applicationId: "4"),
            "\(base)/1/applications/4", .get, .plain
        )
        check(
            .getPermissions(query: .init(parameterName: "ids", projectIds: ["1"])),
            "\(base)/permissions", .get, .query
        )
        check(
            .getStatistics(query: .init(chapterId: "5")),
            "\(base)/statistics", .get, .query
        )
        check(
            .getMatchingStatistics(query: .init(chapterId: "5")),
            "\(base)/statistics/matchings", .get, .query
        )

        #expect(checkedCount == 32)
    }

    @Test("ProjectMatchingRoundRouter 5개 케이스의 path·method·task 가 서버 스펙과 같다")
    func matchingRoundRouterContract() throws {
        let base = "/api/v1/project/matching-rounds"
        let draft = ProjectMatchingRoundDraft(
            name: "1차",
            description: nil,
            type: .planDeveloper,
            phase: .first,
            chapterId: "5",
            startsAt: Date(timeIntervalSince1970: 0),
            endsAt: Date(timeIntervalSince1970: 3600),
            decisionDeadline: Date(timeIntervalSince1970: 7200)
        )
        var checkedCount = 0
        func check(
            _ router: ProjectMatchingRoundRouter,
            _ path: String,
            _ method: Moya.Method,
            _ kind: TaskKind,
            sourceLocation: SourceLocation = #_sourceLocation
        ) {
            checkedCount += 1
            expectContract(router, path, method, kind, sourceLocation: sourceLocation)
        }

        check(.getMatchingRounds(query: .init(chapterId: "5", time: nil)), base, .get, .query)
        check(.createMatchingRound(body: try .init(draft: draft)), base, .post, .json)
        check(
            .updateMatchingRound(matchingRoundId: "3", body: .init(update: .init())),
            "\(base)/3", .patch, .json
        )
        check(.deleteMatchingRound(matchingRoundId: "3"), "\(base)/3", .delete, .plain)
        check(.autoDecide(matchingRoundId: "3"), "\(base)/3/auto-decide", .post, .plain)

        #expect(checkedCount == 5)
    }

    // MARK: - Query Encoding

    @Test("배열 쿼리는 대괄호 없이 같은 키를 반복한다 (Spring List 바인딩)")
    func arrayQueryHasNoBrackets() throws {
        let router = ProjectRouter.getMembersBatch(query: .init(projectIds: ["1", "2"]))

        let query = try encodedQuery(router.task)

        #expect(query.contains("projectIds=1&projectIds=2"))
        #expect(!query.contains("%5B%5D"))
    }

    @Test("권한 조회는 쿼리 이름이 ids 다")
    func permissionQueryUsesIds() throws {
        let router = ProjectRouter.getPermissions(
            query: .init(parameterName: "ids", projectIds: ["7"])
        )

        #expect(try encodedQuery(router.task) == "ids=7")
    }

    @Test("검색 쿼리는 파트를 서버 값으로, 비어 있는 필터는 빼고 보낸다")
    func searchQueryParameters() throws {
        let query = ProjectSearchQuery(
            gisuId: "9",
            parts: [.design, .server(type: .spring)],
            statuses: [.inProgress]
        )
        let router = ProjectRouter.searchProjects(query: .init(query: query))

        let parameters = try #require(parameters(router.task))

        #expect(parameters["gisuId"] as? String == "9")
        #expect(parameters["parts"] as? [String] == ["DESIGN", "SPRINGBOOT"])
        #expect(parameters["statuses"] as? [String] == ["IN_PROGRESS"])
        #expect(parameters["page"] as? Int == 0)
        #expect(parameters["keyword"] == nil)
        #expect(parameters["schoolIds"] == nil)
    }

    @Test("사유가 없으면 reason 쿼리를 보내지 않는다")
    func reasonQueryOmittedWhenNil() throws {
        let router = ProjectRouter.cancelApplication(
            projectId: "1",
            applicationId: "4",
            query: .init(reason: nil)
        )

        #expect(try #require(parameters(router.task)).isEmpty)
    }

    // MARK: - Body Encoding

    @Test("요청 본문의 id 는 서버 Long 에 맞춰 숫자로 보낸다")
    func bodyEncodesIdsAsNumbers() throws {
        let body = try CompleteProjectsRequestDTO(projectIds: ["1", "22"])

        let json = try String(decoding: JSONEncoder().encode(body), as: UTF8.self)

        #expect(json == #"{"projectIds":[1,22]}"#)
    }

    @Test("숫자가 아닌 id 는 요청을 보내기 전에 실패한다")
    func nonNumericIdThrows() {
        #expect(throws: RepositoryError.self) {
            try CompleteProjectsRequestDTO(projectIds: ["abc"])
        }
    }

    @Test("PATCH 본문은 nil 필드를 빼서 서버 값을 덮지 않는다")
    func patchBodyOmitsNilFields() throws {
        let body = UpdateProjectRequestDTO(update: .init(name: "새 이름"))

        let json = try String(decoding: JSONEncoder().encode(body), as: UTF8.self)

        #expect(json == #"{"name":"새 이름"}"#)
    }

    // MARK: - BaseTargetType

    @Test(
        "baseURL은 NetworkConfig.baseURL을 사용한다",
        .disabled("UMCApp Secret 인프라 구축 후 활성화")
    )
    func baseURL() {
        #expect(ProjectRouter.getProject(projectId: "1").baseURL == NetworkConfig.baseURL)
    }

    @Test(
        "headers는 NetworkConfig.defaultHeaders를 사용한다",
        .disabled("UMCApp Secret 인프라 구축 후 활성화")
    )
    func headers() {
        #expect(ProjectRouter.getProject(projectId: "1").headers == NetworkConfig.defaultHeaders)
    }
}

// MARK: - Helper

private enum TaskKind: Equatable {
    case plain, query, json, other

    init(_ task: Moya.Task) {
        switch task {
        case .requestPlain:
            self = .plain
        case .requestParameters(_, let encoding) where encoding is URLEncoding:
            self = .query
        case .requestJSONEncodable:
            self = .json
        default:
            self = .other
        }
    }
}

private func expectContract(
    _ target: any TargetType,
    _ path: String,
    _ method: Moya.Method,
    _ kind: TaskKind,
    sourceLocation: SourceLocation
) {
    #expect(target.path == path, "\(target)", sourceLocation: sourceLocation)
    #expect(target.method == method, "\(target)", sourceLocation: sourceLocation)
    #expect(TaskKind(target.task) == kind, "\(target)", sourceLocation: sourceLocation)
}

private func parameters(_ task: Moya.Task) -> [String: Any]? {
    guard case .requestParameters(let parameters, _) = task else { return nil }
    return parameters
}

/// 실제 `URLEncoding` 으로 쿼리 문자열을 만들어 본다.
private func encodedQuery(_ task: Moya.Task) throws -> String {
    guard case .requestParameters(let parameters, let encoding) = task else {
        Issue.record("Expected .requestParameters, got \(task)")
        return ""
    }
    let request = URLRequest(url: URL(string: "https://example.com")!)
    let encoded = try encoding.encode(request, with: parameters)
    return encoded.url?.query ?? ""
}
