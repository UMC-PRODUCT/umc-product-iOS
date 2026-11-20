//
//  ThreadMemberProfileRepositoryTests.swift
//  CommunityDataTests
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
import Testing
import Moya
import CoreNetwork
import UMCFoundation
import CommunityDomain
@testable import CommunityData

@Suite("ThreadMemberProfileRepository — 스레드에서 연 다른 회원 프로필 (#1681)")
struct ThreadMemberProfileRepositoryTests {

    @Test("GET /api/v1/member/profile/{memberId} — 본문 없음")
    func routerContract() {
        let router = CommunityThreadRouter.getMemberProfile(memberId: "42")

        #expect(router.path == "/api/v1/member/profile/42")
        #expect(router.method == .get)
        guard case .requestPlain = router.task else {
            Issue.record("requestPlain이 아님"); return
        }
    }

    /// 서버는 비공개로 둔 링크를 `null` 로 준다. 입력하지 않은 링크와 구분하지 않는다.
    @Test("응답을 화면 값으로 옮기고, 비공개·빈 링크는 값 없이 둔다")
    func mapsPublicProfile() async throws {
        let network = StubProfileNetwork(body: Self.profileJSON)
        let useCase = ThreadMemberProfileUseCase(
            repository: ThreadMemberProfileRepository(networkRequesting: network)
        )

        let profile = try await useCase.loadProfile(memberId: "42")

        #expect(network.requestedPaths == ["/api/v1/member/profile/42"])
        #expect(profile.name == "김철수")
        #expect(profile.nickname == "철수")
        #expect(profile.schoolName == "한국대학교")
        #expect(profile.generation == "10")
        #expect(profile.part == .front(type: .ios))
        #expect(profile.links.map(\.kind) == ThreadMemberProfile.Kind.allCases)
        #expect(profile.links.first { $0.kind == .github }?.value == "https://github.com/chulsoo")
        #expect(profile.links.first { $0.kind == .blog }?.value == nil)
        #expect(profile.links.first { $0.kind == .instagram }?.value == nil)
    }

    @Test("응답을 읽지 못하면 디코딩 오류로 알린다")
    func decodingFailure() async {
        let repository = ThreadMemberProfileRepository(
            networkRequesting: StubProfileNetwork(body: "{\"success\":true,\"result\":[]}")
        )

        await #expect(throws: RepositoryError.self) {
            _ = try await repository.fetchProfile(memberId: "42")
        }
    }

    // MARK: - Fixture

    /// GitHub·LinkedIn만 공개, Blog·Instagram은 비공개(`null`), 개인 사이트는 빈 문자열.
    private static let profileJSON = """
    {"success":true,"code":"200","message":"ok","result":{
      "id":42,"name":"김철수","nickname":"철수","email":"chulsoo@umc.dev",
      "schoolId":900,"schoolName":"한국대학교","status":"ACTIVE",
      "profile":{"id":5,"linkedIn":"https://linkedin.com/in/chulsoo","instagram":null,
                 "github":"https://github.com/chulsoo","blog":null,"personal":""},
      "roles":[],
      "challengerRecords":[{
        "challengerId":111,"memberId":42,"gisu":10,"gisuId":210,"chapterId":300,
        "chapterName":"서울","part":"IOS","schoolId":900,"schoolName":"한국대학교",
        "name":"김철수","nickname":"철수","email":null,"status":"ACTIVE","challengerPoints":[]
      }]
    }}
    """
}

/// ``CommunityThreadNetworkRequesting`` 가짜 구현 — 고정 응답을 돌려주고 경로를 기록한다.
private final class StubProfileNetwork: CommunityThreadNetworkRequesting, @unchecked Sendable {
    private let body: String
    private(set) var requestedPaths: [String] = []

    init(body: String) {
        self.body = body
    }

    func request<T: TargetType>(_ target: T) async throws -> Response {
        requestedPaths.append(target.path)
        return Response(statusCode: 200, data: Data(body.utf8))
    }
}
