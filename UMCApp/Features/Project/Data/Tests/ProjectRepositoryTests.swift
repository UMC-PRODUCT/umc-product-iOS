//
//  ProjectRepositoryTests.swift
//  ProjectDataTests
//
//  Created by euijjang97 on 9/19/26.
//
//  `APIResponse` 봉투 처리 — `result: null`·원시 Long·`void` 응답·`success: false` 를
//  저장소가 어떻게 돌려주는지 검증한다.
//

import Foundation
import Moya
import Testing
import UMCFoundation
import ProjectDomain
@testable import ProjectData

@Suite("Project Repository 응답 처리")
struct ProjectRepositoryTests {

    private final class StubRequesting: ProjectNetworkRequesting, @unchecked Sendable {
        var body = ""
        private(set) var requestedPath: String?

        func request<T: TargetType>(_ target: T) async throws -> Response {
            requestedPath = target.path
            return Response(statusCode: 200, data: Data(body.utf8))
        }
    }

    @Test("작성 중인 초안이 없으면(result: null) nil 을 돌려준다")
    func draftNullResultIsNil() async throws {
        let stub = StubRequesting()
        stub.body = #"{"success":true,"code":"COMMON200","message":"OK","result":null}"#

        let draft = try await ProjectRepository(networkRequesting: stub)
            .fetchDraftProject(gisuId: "9")

        #expect(draft == nil)
    }

    @Test("PO 추가 — 원시 Long 이 숫자로 와도 문자열 id 로 돌려준다")
    func addMemberReturnsIdentifier() async throws {
        let stub = StubRequesting()
        stub.body = #"{"success":true,"code":"COMMON200","message":"OK","result":501}"#

        let projectMemberId = try await ProjectRepository(networkRequesting: stub)
            .addMember(projectId: "101", memberId: "7", part: .design)

        #expect(projectMemberId == "501")
        #expect(stub.requestedPath == "/api/v1/projects/101/members")
    }

    @Test("본문 없는 명령은 success 만 확인한다")
    func voidCommandSucceeds() async throws {
        let stub = StubRequesting()
        stub.body = #"{"success":true,"code":"COMMON200","message":"OK","result":null}"#

        try await ProjectMatchingRoundRepository(networkRequesting: stub)
            .deleteMatchingRound(matchingRoundId: "11")
    }

    @Test("success: false 면 RepositoryError 를 던진다")
    func failureThrows() async {
        let stub = StubRequesting()
        stub.body = #"{"success":false,"code":"PROJECT400","message":"상태가 맞지 않습니다."}"#

        await #expect(throws: RepositoryError.self) {
            try await ProjectRepository(networkRequesting: stub).deleteProject(projectId: "101")
        }
    }

    @Test("요청 본문 id 가 숫자가 아니면 보내기 전에 실패한다")
    func nonNumericBodyIdThrowsBeforeRequest() async {
        let stub = StubRequesting()

        await #expect(throws: RepositoryError.self) {
            try await ProjectApplicationRepository(networkRequesting: stub)
                .createApplication(projectId: "101", matchingRoundId: "abc")
        }
        #expect(stub.requestedPath == nil)
    }
}
