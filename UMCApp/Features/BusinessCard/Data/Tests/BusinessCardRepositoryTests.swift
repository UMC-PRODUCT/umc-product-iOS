//
//  BusinessCardRepositoryTests.swift
//  BusinessCardDataTests
//
//  Created by One on 8/16/26.
//

import Foundation
import Testing
import Moya
import CoreDomain
import UMCFoundation
import BusinessCardDomain
@testable import BusinessCardData

@Suite("BusinessCardRepository — 앞면은 정본 프로필, 뒷면은 내 명함 API")
struct BusinessCardRepositoryTests {

    @Test("forceRefresh를 정본 저장소에 그대로 전달하고 매핑 결과를 돌려준다")
    func delegatesForceRefresh() async throws {
        let stub = StubMemberProfileRepository(
            profile: makeProfile(records: [makeRecord(gisu: "12", part: "IOS")])
        )
        let sut = BusinessCardRepository(
            memberProfileRepository: stub,
            networkRequesting: StubRequesting(body: Self.visibilityJSON)
        )

        let card = try await sut.fetchMyCard(forceRefresh: true)

        #expect(stub.lastForceRefresh == true)
        #expect(card.memberId == "42")
        #expect(card.generation == "12")
    }

    /// 내 명함 경로도 같은 변환을 탄다. 기록이 없으면 예전에는 「운영진 · 0기」 명함이
    /// 그려졌는데, 그건 내 화면에 남의 정보만큼이나 틀린 값이다 (#1223).
    @Test("정본 프로필에 기록·역할이 없으면 내 명함도 실패한다")
    func failsWhenProfileHasNoRecords() async throws {
        let stub = StubMemberProfileRepository(profile: makeProfile(records: []))
        let sut = BusinessCardRepository(
            memberProfileRepository: stub,
            networkRequesting: StubRequesting(body: Self.visibilityJSON)
        )

        await #expect(throws: AppError.self) {
            _ = try await sut.fetchMyCard(forceRefresh: false)
        }
    }

    // MARK: - 뒷면 (#1678)

    /// 정본 프로필은 공개 여부 없이 값을 모두 준다. 그대로 그리면 남에게 숨긴 값이 내 명함과
    /// 교환 페이로드에 남는다.
    @Test("뒷면은 프로필 값을 쓰되 공개 여부에서 비공개인 이메일·링크를 빼고, 앞면은 그대로 둔다")
    func backFaceHidesPrivateItems() async throws {
        let requesting = StubRequesting(body: Self.visibilityJSON)
        let sut = BusinessCardRepository(
            memberProfileRepository: StubMemberProfileRepository(profile: makeFullProfile()),
            networkRequesting: requesting
        )

        let card = try await sut.fetchMyCard(forceRefresh: false)

        #expect(requesting.requestedPaths == ["/api/v1/member/me/business-card/edit"])
        #expect(card.name == "정의찬")
        #expect(card.university == "한양대학교")
        #expect(card.email == "login@umc.dev")
        #expect(card.github == "https://github.com/umc")
        #expect(card.instagram == "https://instagram.com/umc")
        #expect(card.blog == nil)
        // 응답에 없는 종류는 모르니 숨긴다.
        #expect(card.linkedIn == nil)
    }

    @Test("이메일이 비공개(isPublic false)면 이메일 줄을 비운다")
    func privateEmailIsDropped() async throws {
        let sut = BusinessCardRepository(
            memberProfileRepository: StubMemberProfileRepository(profile: makeFullProfile()),
            networkRequesting: StubRequesting(body: """
            {"success":true,"code":"200","message":"ok","result":{
              "memberId":"42","contact":{"email":null,"isPublic":false},"links":[]
            }}
            """)
        )

        let card = try await sut.fetchMyCard(forceRefresh: false)

        #expect(card.email == nil)
        #expect(card.github == nil)
    }

    @Test("공개 여부를 못 받으면 프로필 값으로 대신 그리지 않고 실패한다")
    func failsWhenVisibilityFails() async throws {
        let sut = BusinessCardRepository(
            memberProfileRepository: StubMemberProfileRepository(profile: makeFullProfile()),
            networkRequesting: StubRequesting(error: URLError(.notConnectedToInternet))
        )

        await #expect(throws: URLError.self) {
            _ = try await sut.fetchMyCard(forceRefresh: false)
        }
    }

    // MARK: - 공개 여부 캐시 (#1678)

    @Test("한 번 받은 공개 여부는 다시 묻지 않고 forceRefresh일 때만 다시 받는다")
    func reusesVisibilityUntilForceRefresh() async throws {
        let requesting = StubRequesting(body: Self.visibilityJSON)
        let sut = makeCachingSUT(requesting)

        _ = try await sut.fetchMyCard(forceRefresh: false)
        _ = try await sut.fetchMyCard(forceRefresh: false)
        #expect(requesting.requestedPaths.count == 1)

        _ = try await sut.fetchMyCard(forceRefresh: true)
        #expect(requesting.requestedPaths.count == 2)
    }

    @Test("캐시를 비우면 다음 조회에서 공개 여부를 다시 받는다")
    func refetchesAfterInvalidation() async throws {
        let requesting = StubRequesting(body: Self.visibilityJSON)
        let sut = makeCachingSUT(requesting)
        _ = try await sut.fetchMyCard(forceRefresh: false)

        await sut.invalidateMyCardCache()
        _ = try await sut.fetchMyCard(forceRefresh: false)

        #expect(requesting.requestedPaths.count == 2)
    }

    /// 근거리 교환은 인터넷 없이도 된다. 교환 화면이 명함을 읽을 때마다 서버를 부르면
    /// 행사장처럼 신호가 약한 곳에서 교환을 시작하지 못한다.
    @Test("한 번 받은 뒤에는 인터넷이 끊겨도 받아 둔 공개 여부로 명함을 만든다")
    func servesCachedVisibilityOffline() async throws {
        let requesting = StubRequesting(body: Self.visibilityJSON)
        let sut = makeCachingSUT(requesting)
        _ = try await sut.fetchMyCard(forceRefresh: false)

        requesting.error = URLError(.notConnectedToInternet)
        let card = try await sut.fetchMyCard(forceRefresh: false)

        #expect(card.email == "login@umc.dev")
        #expect(card.github == "https://github.com/umc")
        #expect(card.blog == nil)
    }

    // MARK: - Fixture

    /// 이메일·GitHub·Instagram은 공개, Blog는 비공개, LinkedIn은 응답에 없다.
    private static let visibilityJSON = """
    {"success":true,"code":"200","message":"ok","result":{
      "memberId":"42","name":"정의찬","schoolName":"한양대학교",
      "contact":{"email":null,"isPublic":true},
      "links":[
        {"type":"INSTAGRAM","link":"https://instagram.com/umc","isPublic":true},
        {"type":"GITHUB","link":"https://github.com/umc","isPublic":true},
        {"type":"BLOG","link":"https://blog.umc.dev","isPublic":false},
        {"type":"PERSONAL","link":null,"isPublic":true}
      ]
    }}
    """

    // MARK: - Private Function

    private func makeCachingSUT(_ requesting: StubRequesting) -> BusinessCardRepository {
        BusinessCardRepository(
            memberProfileRepository: StubMemberProfileRepository(profile: makeFullProfile()),
            networkRequesting: requesting
        )
    }

    /// 로그인 이메일과 링크 다섯 종을 모두 채운 프로필.
    private func makeFullProfile() -> Profile {
        makeProfile(
            records: [makeRecord(gisu: "12", part: "IOS")],
            email: "login@umc.dev",
            links: ProfileExternalLinks(
                id: "1", linkedIn: "https://linkedin.com/in/umc",
                instagram: "https://instagram.com/umc", github: "https://github.com/umc",
                blog: "https://blog.umc.dev", personal: "https://umc.dev"
            )
        )
    }

    private func makeProfile(
        records: [ProfileChallengerRecord],
        email: String = "",
        links: ProfileExternalLinks? = nil
    ) -> Profile {
        Profile(
            memberId: "42", name: "정의찬", nickname: "제옹", generations: [],
            email: email, externalLinks: links, challengerRecords: records
        )
    }

    private func makeRecord(gisu: String, part: String) -> ProfileChallengerRecord {
        ProfileChallengerRecord(
            challengerId: "c\(gisu)", memberId: "42", gisu: gisu, gisuId: gisu,
            chapterId: nil, chapterName: nil, part: part,
            schoolId: "1", schoolName: "한양대학교",
            name: "정의찬", nickname: "제옹", email: nil, profileImageLink: nil,
            status: .active, challengerPoints: []
        )
    }
}

private final class StubMemberProfileRepository:
    MemberProfileRepositoryProtocol, @unchecked Sendable {
    private let profile: Profile
    private(set) var lastForceRefresh: Bool?

    init(profile: Profile) { self.profile = profile }

    func fetchMyProfile() async throws -> Profile {
        profile
    }

    func fetchMyProfile(forceRefresh: Bool) async throws -> Profile {
        lastForceRefresh = forceRefresh
        return profile
    }
}

private final class StubRequesting: BusinessCardNetworkRequesting, @unchecked Sendable {
    private let body: String
    var error: Error?
    private(set) var requestedPaths: [String] = []

    init(body: String = "", error: Error? = nil) {
        self.body = body
        self.error = error
    }

    func request<T: TargetType>(_ target: T) async throws -> Response {
        requestedPaths.append(target.path)
        if let error { throw error }
        return Response(statusCode: 200, data: Data(body.utf8))
    }
}
