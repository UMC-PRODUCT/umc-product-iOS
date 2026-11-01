// Created by euijjang97 on 11/1/26.
import Foundation
import Testing
import Moya
import ActivityDomain
@testable import ActivityData

#if DEBUG
private final class AdministrationNetwork: NetworkRequesting {
    enum StubError: Error { case unexpectedRequest }
    var responses: [Data]
    var paths: [String] = []
    var methods: [Moya.Method] = []
    var tasks: [Moya.Task] = []
    init(_ json: [String]) { responses = json.map { Data($0.utf8) } }
    func request<T: TargetType>(_ target: T) async throws -> Response {
        paths.append(target.path)
        methods.append(target.method)
        tasks.append(target.task)
        guard !responses.isEmpty else { throw StubError.unexpectedRequest }
        return Response(statusCode: 200, data: responses.removeFirst())
    }
}

@Suite("운영진 멤버 관리 서버 계약")
struct MemberAdministrationRepositoryTests {
    @Test("검색은 챌린저별 기수와 학교 식별자를 보존한다")
    func searchPreservesScope() async throws {
        let network = AdministrationNetwork([#"{"success":true,"result":{"totalCount":"1","page":{"content":[{"memberId":7,"challengerId":"99","gisuId":10,"generation":"11","schoolId":"5","name":"이름","nickname":"닉","schoolName":"학교","part":null,"roleTypes":["SCHOOL_PRESIDENT"]}],"hasNext":true}}}"#])
        let repository = MemberAdministrationRepository(networkRequesting: network)
        let result = try await repository.search(
            filter: .init(keyword: "검색", gisuId: "10", chapterId: "2", schoolId: "5", part: "IOS"), page: 1
        )
        #expect(result.members.first?.id == "99")
        #expect(result.members.first?.schoolId == "5")
        #expect(result.members.first?.generation == "11")
        #expect(result.members.first?.member.part == .admin)
        #expect(result.hasNext)
        #expect(network.paths == ["/api/v2/challenger/search"])
        guard case let .requestParameters(query, _) = network.tasks[0] else {
            Issue.record("검색 쿼리 누락"); return
        }
        #expect(query["page"] as? Int == 1)
        #expect(query["keyword"] as? String == "검색")
        #expect(query["chapterId"] as? String == "2")
        #expect(query["gisuId"] as? String == "10")
    }

    @Test("기수와 조직은 숫자 및 문자열 ID를 읽는다")
    func filtersDecode() async throws {
        let network = AdministrationNetwork([
            #"{"success":true,"result":{"gisuList":[{"gisuId":10,"generation":"11","isActive":true}]}}"#,
            #"{"success":true,"result":{"gisus":[{"gisuId":"10","chapters":[{"chapterId":2,"chapterName":"지부","schools":[{"schoolId":"5","schoolName":"학교"}]}],"schools":[{"schoolId":5,"schoolName":"학교","chapterId":"2"}]}]}}"#
        ])
        let repository = MemberAdministrationRepository(networkRequesting: network)
        let generations = try await repository.fetchGenerations()
        let organization = try await repository.fetchOrganizations(gisuId: "10")
        #expect(generations.first?.id == "10")
        #expect(generations.first?.name == "11기")
        #expect(generations.first?.isActive == true)
        #expect(organization.schools.first?.parentId == "2")
        #expect(organization.chapters.first?.id == "2")
    }

    @Test("사유 수정은 newDescription을 보내고 result 없는 성공을 처리한다")
    func editDescription() async throws {
        let network = AdministrationNetwork([#"{"success":true,"code":"COMMON200","message":"성공"}"#])
        let repository = MemberAdministrationRepository(networkRequesting: network)
        try await repository.updatePointDescription(pointId: "42", description: "정정")
        #expect(network.paths == ["/api/v1/challenger/points/42"])
        #expect(network.methods == [.patch])
        guard case let .requestJSONEncodable(body) = network.tasks[0] else {
            Issue.record("본문 누락"); return
        }
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: String]
        #expect(json == ["newDescription": "정정"])
    }

    @Test("시스템 권한은 선택 필드지만 조회 실패를 권한 없음으로 숨기지 않는다")
    func authorityContract() async throws {
        let network = AdministrationNetwork([
            #"{"success":true,"result":{"roles":[{"id":1,"challengerId":2,"gisu":"11","gisuId":"10","roleType":"SCHOOL_PRESIDENT","organizationType":"SCHOOL","organizationId":5}]}}"#,
            #"{"success":true,"result":{"isSuperAdmin":true}}"#
        ])
        let repository = MemberAdministrationRepository(networkRequesting: network)
        let authority = try await repository.fetchAuthority()
        #expect(authority.isSuperAdmin)
        #expect(authority.roles.first?.gisuId == "10")
        #expect(authority.roles.first?.organizationId == "5")
        #expect(network.paths == ["/api/v1/member/me", "/api/v2/member/me"])
        let absent = AdministrationNetwork([
            #"{"success":true,"result":{"roles":[]}}"#,
            #"{"success":true,"result":{}}"#
        ])
        let fallback = try await MemberAdministrationRepository(
            networkRequesting: absent
        ).fetchAuthority()
        #expect(!fallback.isSuperAdmin)
        let failed = AdministrationNetwork([
            #"{"success":true,"result":{"roles":[]}}"#,
            #"{"success":false,"code":"FORBIDDEN","message":"권한 없음"}"#
        ])
        await #expect(throws: (any Error).self) {
            try await MemberAdministrationRepository(networkRequesting: failed).fetchAuthority()
        }
    }

    @Test("사유 수정 실패 envelope를 호출자에게 전달한다")
    func editFailure() async {
        let network = AdministrationNetwork([
            #"{"success":false,"code":"FORBIDDEN","message":"권한 없음"}"#
        ])
        await #expect(throws: (any Error).self) {
            try await MemberAdministrationRepository(networkRequesting: network)
                .updatePointDescription(pointId: "42", description: "정정")
        }
    }

    @Test("서버의 UTF16 200자 제한을 이모지에도 적용한다")
    func reasonUTF16Boundary() async throws {
        let accepted = AdministrationNetwork([#"{"success":true}"#])
        try await MemberAdministrationRepository(networkRequesting: accepted)
            .updatePointDescription(pointId: "42", description: String(repeating: "😀", count: 100))
        #expect(accepted.paths.count == 1)
        let rejected = AdministrationNetwork([])
        await #expect(throws: (any Error).self) {
            try await MemberAdministrationRepository(networkRequesting: rejected)
                .updatePointDescription(pointId: "42", description: String(repeating: "😀", count: 101))
        }
        #expect(rejected.paths.isEmpty)
    }

    @Test("빈 사유는 서버에 전송하지 않는다")
    func rejectsBlankReason() async {
        let network = AdministrationNetwork([])
        let repository = MemberAdministrationRepository(networkRequesting: network)
        await #expect(throws: (any Error).self) {
            try await repository.updatePointDescription(pointId: "42", description: "  \n")
        }
        #expect(network.paths.isEmpty)
    }
}
#endif
