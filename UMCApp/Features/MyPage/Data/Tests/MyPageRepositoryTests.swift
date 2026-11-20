//
//  MyPageRepositoryTests.swift
//  MyPageDataTests
//
//  Created by 김동민 on 7/5/26.
//
//  진짜 `MyPageRepository` 를 대상으로, 그 아래 네트워크 계층만 가짜(`StubMyPageNetwork`)로
//  주입해 디코딩·도메인 매핑·에러 매핑·링크 정규화·이미지 업로드 오케스트레이션을 검증한다.
//  (엔드포인트 path/method/task 계약은 `MyPageRouterTests` 에서 별도 검증)
//

import Foundation
import Testing
import Moya
import CoreNetwork
import UMCFoundation
import CoreDomain
import MyPageDomain
@testable import MyPageData

// MARK: - Test Doubles

/// ``MyPageNetworkRequesting`` 가짜 구현.
///
/// 미리 설정한 결과(성공 본문 / 던질 에러)를 반환하고, 호출된 라우터의 경로·메서드·타깃을
/// 기록해 엔드포인트 계약과 전송 페이로드를 검증할 수 있게 합니다.
/// `target.path`/`target.method` 만 읽어 `NetworkConfig.baseURL`(테스트 번들 `fatalError`)을
/// 건드리지 않습니다.
private final class StubMyPageNetwork: MyPageNetworkRequesting, @unchecked Sendable {

    enum Outcome {
        /// 200 응답으로 주어진 JSON 본문을 반환
        case success(Data)
        /// 요청 단계에서 에러를 던짐 (비-2xx 등)
        case failure(Error)
    }

    private let outcome: Outcome
    private(set) var requestCount = 0
    private(set) var requestWithoutAuthCount = 0
    private(set) var lastPath: String?
    private(set) var lastMethod: Moya.Method?
    private(set) var lastTarget: MyPageRouter?

    init(_ outcome: Outcome) {
        self.outcome = outcome
    }

    func request<T: TargetType>(_ target: T) async throws -> Response {
        requestCount += 1
        capture(target)
        return try makeResponse()
    }

    func requestWithoutAuth<T: TargetType>(_ target: T) async throws -> Response {
        requestWithoutAuthCount += 1
        capture(target)
        return try makeResponse()
    }

    private func capture<T: TargetType>(_ target: T) {
        lastPath = target.path
        lastMethod = target.method
        lastTarget = target as? MyPageRouter
    }

    private func makeResponse() throws -> Response {
        switch outcome {
        case .success(let data):
            return Response(statusCode: 200, data: data)
        case .failure(let error):
            throw error
        }
    }
}

/// ``MemberProfileRepositoryProtocol`` 가짜 구현.
///
/// `fetchMyProfile()`이 더 이상 `MyPageRouter.getMyProfile`을 거치지 않고 이 정본 파이프라인에
/// 위임하므로, 미리 설정한 ``CoreDomain/Profile`` 값(또는 에러)을 반환합니다.
private final class MockMemberProfileRepository:
    MemberProfileRepositoryProtocol, @unchecked Sendable {

    enum MockError: Error, Equatable {
        case notStubbed
    }

    var result: Result<Profile, Error> = .failure(MockError.notStubbed)
    private(set) var fetchMyProfileCallCount = 0
    private(set) var primeCacheCallCount = 0
    private(set) var primedProfiles: [Profile] = []
    private(set) var lastForceRefresh: Bool?

    func fetchMyProfile() async throws -> Profile {
        try await fetchMyProfile(forceRefresh: false)
    }

    func fetchMyProfile(forceRefresh: Bool) async throws -> Profile {
        fetchMyProfileCallCount += 1
        lastForceRefresh = forceRefresh
        return try result.get()
    }

    func primeCache(with profile: Profile) async {
        primeCacheCallCount += 1
        primedProfiles.append(profile)
    }
}

/// 캐시 합성 검증용 원격 스텁 — 호출 횟수를 기록하고 호출 시점의 `profileToReturn`을 반환한다.
private actor FakeRemoteMemberProfileRepository: MemberProfileRepositoryProtocol {

    private(set) var callCount = 0
    private var profileToReturn: Profile

    init(profile: Profile) {
        self.profileToReturn = profile
    }

    func updateProfile(_ profile: Profile) {
        profileToReturn = profile
    }

    func fetchMyProfile() async throws -> Profile {
        callCount += 1
        return profileToReturn
    }
}

/// ``StorageRepositoryProtocol`` 가짜 구현.
///
/// 프로필 이미지 업로드 3단계(prepare → upload → confirm) 호출 순서·인자를 기록합니다.
private final class FakeStorageRepository: StorageRepositoryProtocol, @unchecked Sendable {

    private(set) var callOrder: [String] = []
    private(set) var prepareReceived: (
        fileName: String, contentType: String, fileSize: Int, category: StorageFileCategory
    )?
    private(set) var uploadReceivedURL: String?
    private(set) var confirmReceivedFileId: String?

    private let prepared: StoragePrepareUploadResponseDTO

    init(prepared: StoragePrepareUploadResponseDTO = FakeStorageRepository.defaultPrepared()) {
        self.prepared = prepared
    }

    /// 고정 JSON 으로 만든 기본 prepare 응답 (`StoragePrepareUploadResponseDTO` 는 public init 이 없어 디코딩으로 생성).
    static func defaultPrepared(
        fileId: String = "file-1",
        uploadUrl: String = "https://upload.example.com/put",
        uploadMethod: String = "PUT"
    ) -> StoragePrepareUploadResponseDTO {
        let json = Data("""
        {
            "fileId": "\(fileId)",
            "uploadUrl": "\(uploadUrl)",
            "uploadMethod": "\(uploadMethod)",
            "headers": null,
            "expiresAt": null
        }
        """.utf8)
        // 고정 상수 JSON 이므로 디코딩 실패는 프로그래머 오류.
        return try! JSONDecoder().decode(StoragePrepareUploadResponseDTO.self, from: json)
    }

    func prepareUpload(
        fileName: String,
        contentType: String,
        fileSize: Int,
        category: StorageFileCategory
    ) async throws -> StoragePrepareUploadResponseDTO {
        callOrder.append("prepare")
        prepareReceived = (fileName, contentType, fileSize, category)
        return prepared
    }

    func uploadFile(
        to url: String,
        data: Data,
        method: String,
        headers: [String: String]?,
        contentType: String?
    ) async throws {
        callOrder.append("upload")
        uploadReceivedURL = url
    }

    func confirmUpload(fileId: String) async throws {
        callOrder.append("confirm")
        confirmReceivedFileId = fileId
    }

    func deleteFile(fileId: String) async throws {
        callOrder.append("delete")
    }
}

// MARK: - Fixtures

private enum Fixture {

    /// APIResponse 성공 봉투로 감싼 result 본문
    static func success(_ resultJSON: String) -> Data {
        Data("""
        { "success": true, "code": "200", "message": "성공", "result": \(resultJSON) }
        """.utf8)
    }

    /// result 가 없는 성공 봉투 (PATCH/DELETE/POST void)
    static func successVoid() -> Data {
        Data("""
        { "success": true, "code": "200", "message": "성공", "result": null }
        """.utf8)
    }

    /// isSuccess:false 실패 봉투
    static func failureBody(code: String?, message: String?) -> Data {
        var fields: [String] = ["\"success\": false"]
        if let code { fields.append("\"code\": \"\(code)\"") }
        if let message { fields.append("\"message\": \"\(message)\"") }
        fields.append("\"result\": null")
        return Data("{ \(fields.joined(separator: ", ")) }".utf8)
    }

    /// 캐시 합성 검증용 최소 Profile (기수 기록 없음)
    static func minimalProfile(memberId: String) -> Profile {
        Profile(
            memberId: memberId,
            name: "홍길동",
            nickname: "길동",
            generations: [],
            roles: [],
            challengerRecords: []
        )
    }

    /// 프로필 result 본문 — 최신 챌린저 기록(challengerId 777, gisu 11, IOS)을 가진 멤버(id 42)
    static let profileObject = """
    {
        "id": "42",
        "name": "전체이름",
        "nickname": "전체닉",
        "email": "member@umc.kr",
        "schoolId": "1",
        "schoolName": "전체학교",
        "status": "ACTIVE",
        "roles": [],
        "challengerRecords": [
            {
                "challengerId": "777",
                "memberId": "42",
                "gisu": "11",
                "part": "IOS",
                "challengerPoints": [],
                "name": "김챌린저",
                "nickname": "챌린",
                "schoolId": "1",
                "schoolName": "한성대",
                "status": "ACTIVE"
            }
        ]
    }
    """

    /// 약관 result 본문
    static let termsObject = """
    { "id": "terms-1", "link": "https://umc.it.kr/terms/privacy", "isMandatory": true }
    """
}

// MARK: - Helper

private func makeRepository(
    _ outcome: StubMyPageNetwork.Outcome,
    storage: FakeStorageRepository = FakeStorageRepository(),
    memberProfileRepository: MemberProfileRepositoryProtocol = MockMemberProfileRepository()
) -> (MyPageRepository, StubMyPageNetwork) {
    let stub = StubMyPageNetwork(outcome)
    let repository = MyPageRepository(
        networkRequesting: stub,
        memberProfileRepository: memberProfileRepository,
        storageRepository: storage
    )
    return (repository, stub)
}

// MARK: - Suite: 프로필 조회 매핑

@Suite("MyPageRepository — 프로필 조회 매핑")
struct MyPageRepositoryProfileTests {

    @Test("fetchMyProfile — 정본 파이프라인(Profile)을 ProfileData로 매핑하고 어댑터를 거치지 않는다")
    func fetchMyProfileMapsSuccess() async throws {
        let record = ProfileChallengerRecord(
            challengerId: "777",
            memberId: "42",
            gisu: "11",
            gisuId: "1100",
            chapterId: nil,
            chapterName: nil,
            part: "IOS",
            schoolId: "1",
            schoolName: "한성대",
            name: "김챌린저",
            nickname: "챌린",
            email: nil,
            profileImageLink: nil,
            status: .active,
            challengerPoints: []
        )
        let profile = Profile(
            memberId: "42",
            name: "전체이름",
            nickname: "전체닉",
            generations: ["11"],
            schoolId: "1",
            schoolName: "전체학교",
            roles: [],
            challengerRecords: [record]
        )
        let memberProfileRepository = MockMemberProfileRepository()
        memberProfileRepository.result = .success(profile)
        let (sut, stub) = makeRepository(
            .success(Fixture.successVoid()),
            memberProfileRepository: memberProfileRepository
        )

        let result = try await sut.fetchMyProfile()

        // 정본 Profile → ProfileData 실제 변환 단언 (최신 챌린저 기록 기준 파생값)
        #expect(result.challengeId == 777)
        #expect(result.challengerInfo.gen == "11")
        #expect(result.challengerInfo.name == "김챌린저")
        #expect(result.challengerInfo.nickname == "챌린")
        #expect(result.challengerInfo.part == .front(type: .ios))
        #expect(memberProfileRepository.fetchMyProfileCallCount == 1)
        // 더 이상 MyPageRouter.getMyProfile을 거치지 않는다
        #expect(stub.requestCount == 0)
    }

    @Test("fetchMyProfile — memberProfileRepository가 던진 에러를 그대로 전파한다")
    func fetchMyProfileThrowsServerError() async {
        let memberProfileRepository = MockMemberProfileRepository()
        memberProfileRepository.result = .failure(
            RepositoryError.serverError(code: "M404", message: "회원 없음")
        )
        let (sut, _) = makeRepository(
            .success(Fixture.successVoid()),
            memberProfileRepository: memberProfileRepository
        )

        await #expect(throws: RepositoryError.serverError(code: "M404", message: "회원 없음")) {
            _ = try await sut.fetchMyProfile()
        }
    }

    @Test("fetchMyProfile(forceRefresh:)가 정본 프로필 리포지토리에 플래그를 그대로 전달한다")
    func fetchMyProfilePassesForceRefreshToMemberProfileRepository() async throws {
        let memberProfileRepository = MockMemberProfileRepository()
        memberProfileRepository.result = .success(Fixture.minimalProfile(memberId: "42"))
        let (sut, _) = makeRepository(
            .success(Fixture.successVoid()),
            memberProfileRepository: memberProfileRepository
        )

        _ = try await sut.fetchMyProfile(forceRefresh: true)
        #expect(memberProfileRepository.lastForceRefresh == true)

        _ = try await sut.fetchMyProfile()
        #expect(memberProfileRepository.lastForceRefresh == false)
    }

    @Test("forceRefresh는 캐시를 우회해 서버를 재조회하고, 이후 일반 조회는 캐시에 히트한다")
    func forceRefreshBypassesCacheAndSubsequentFetchHitsRefreshedCache() async throws {
        let remote = FakeRemoteMemberProfileRepository(
            profile: Fixture.minimalProfile(memberId: "42")
        )
        let cached = CachedMemberProfileRepository(remote: remote)
        let (sut, _) = makeRepository(
            .success(Fixture.successVoid()),
            memberProfileRepository: cached
        )

        _ = try await sut.fetchMyProfile()
        var count = await remote.callCount
        #expect(count == 1, "일반 조회 1회 — 캐시 적재")

        _ = try await sut.fetchMyProfile()
        count = await remote.callCount
        #expect(count == 1, "일반 조회 1회 더 — 캐시 히트")

        _ = try await sut.fetchMyProfile(forceRefresh: true)
        count = await remote.callCount
        #expect(count == 2, "forceRefresh — 캐시 우회")

        _ = try await sut.fetchMyProfile()
        count = await remote.callCount
        #expect(count == 2, "일반 조회 1회 더 — 갱신된 캐시 히트")
    }

    @Test("fetchMemberProfile — APIResponse 래핑 응답을 MemberProfileSummary로 매핑하고 memberId를 path에 보간한다")
    func fetchMemberProfileMapsWrapped() async throws {
        let (sut, stub) = makeRepository(.success(Fixture.success(Fixture.profileObject)))

        let summary = try await sut.fetchMemberProfile(memberId: 5)

        #expect(summary.memberId == "42")
        #expect(summary.generation == 11)
        #expect(stub.lastPath == "/api/v1/member/profile/5")
    }

    @Test("fetchMemberProfile — APIResponse 래핑이 아닌 raw DTO 응답도 흡수한다(구버전 호환)")
    func fetchMemberProfileAbsorbsRawDTO() async throws {
        // 봉투 없이 프로필 객체를 그대로 반환 → APIResponse 디코딩 실패 후 raw DTO 폴백 경로
        let (sut, _) = makeRepository(.success(Data(Fixture.profileObject.utf8)))

        let summary = try await sut.fetchMemberProfile(memberId: 5)

        #expect(summary.memberId == "42")
        #expect(summary.name == "김챌린저")
    }
}

// MARK: - Suite: 약관 조회 (비인증 경로)

@Suite("MyPageRepository — 약관 조회")
struct MyPageRepositoryTermsTests {

    @Test("fetchTerms — 비인증(requestWithoutAuth) 경로로 조회하고 MyPageTerms로 매핑한다")
    func fetchTermsUsesUnauthenticatedPath() async throws {
        let (sut, stub) = makeRepository(.success(Fixture.success(Fixture.termsObject)))

        let terms = try await sut.fetchTerms(termsType: "PRIVACY")

        #expect(terms.id == "terms-1")
        #expect(terms.link == "https://umc.it.kr/terms/privacy")
        #expect(terms.isMandatory == true)
        // 인증 요청이 아니라 requestWithoutAuth 로 나가야 한다
        #expect(stub.requestWithoutAuthCount == 1)
        #expect(stub.requestCount == 0)
        #expect(stub.lastPath == "/api/v1/terms/type/PRIVACY")
    }
}

// MARK: - Suite: 챌린저 기록 추가 (에러 매핑 계약)

@Suite("MyPageRepository — 챌린저 기록 추가 에러 매핑")
struct MyPageRepositoryAddRecordTests {

    @Test("addChallengerRecord — 성공 응답이면 throw 없이 완료하고 POST 엔드포인트를 호출한다")
    func addRecordSucceeds() async throws {
        let (sut, stub) = makeRepository(.success(Fixture.successVoid()))

        try await sut.addChallengerRecord(code: "INVITE-42")

        #expect(stub.requestCount == 1)
        #expect(stub.lastPath == "/api/v1/challenger-record/member")
        #expect(stub.lastMethod == .post)
    }

    @Test("addChallengerRecord — 서버 에러 본문(requestFailed)을 RepositoryError.serverError로 승격한다")
    func addRecordMapsServerError() async {
        let message = "기존 Google 계정(te***@example.com)으로 로그인해주세요."
        let body = Fixture.failureBody(code: "CHALLENGER-0023", message: message)
        let (sut, _) = makeRepository(
            .failure(NetworkError.requestFailed(statusCode: 409, data: body))
        )

        await #expect(throws: RepositoryError.serverError(
            code: "CHALLENGER-0023", message: message
        )) {
            try await sut.addChallengerRecord(code: "X")
        }
    }

    @Test("addChallengerRecord — 파싱 불가한 NetworkError는 원본 그대로 전파한다")
    func addRecordPropagatesNonMappableError() async {
        let (sut, _) = makeRepository(.failure(NetworkError.timeout))

        await #expect(throws: NetworkError.timeout) {
            try await sut.addChallengerRecord(code: "X")
        }
    }
}

// MARK: - Suite: 회원 탈퇴 (result 폐기 계약)

@Suite("MyPageRepository — 회원 탈퇴")
struct MyPageRepositoryDeleteTests {

    @Test("deleteMember — 실제 계약(result: 탈퇴 전 회원 스냅샷)에서 throw 없이 완료하고 DELETE /member를 호출한다")
    func deleteMemberSucceeds() async throws {
        // 백엔드 MEMBER-003은 탈퇴 전 회원 정보 스냅샷을 result로 반환하지만 클라이언트는 폐기한다
        let (sut, stub) = makeRepository(.success(Fixture.success(Fixture.profileObject)))

        try await sut.deleteMember(googleAccessToken: nil, kakaoAccessToken: nil)

        #expect(stub.requestCount == 1)
        #expect(stub.lastPath == "/api/v1/member")
        #expect(stub.lastMethod == .delete)
    }

    @Test("deleteMember — 전달받은 access token을 DeleteMemberRequestDTO에 그대로 담는다")
    func deleteMemberForwardsTokensToRequest() async throws {
        let (sut, stub) = makeRepository(.success(Fixture.successVoid()))

        try await sut.deleteMember(
            googleAccessToken: "google-token",
            kakaoAccessToken: "kakao-token"
        )

        guard case let .deleteMember(request) = try #require(stub.lastTarget) else {
            Issue.record("기대한 라우터 케이스는 .deleteMember 입니다")
            return
        }
        #expect(request.googleAccessToken == "google-token")
        #expect(request.kakaoAccessToken == "kakao-token")
    }

    @Test("deleteMember — result가 없는 표준 void 봉투도 성공으로 처리한다")
    func deleteMemberSucceedsWithVoidResult() async throws {
        let (sut, stub) = makeRepository(.success(Fixture.successVoid()))

        try await sut.deleteMember(googleAccessToken: nil, kakaoAccessToken: nil)

        #expect(stub.requestCount == 1)
        #expect(stub.lastPath == "/api/v1/member")
        #expect(stub.lastMethod == .delete)
    }

    @Test("deleteMember — isSuccess:false면 RepositoryError.serverError를 던진다")
    func deleteMemberThrowsServerError() async {
        let (sut, _) = makeRepository(
            .success(Fixture.failureBody(code: "M403", message: "권한이 없습니다."))
        )

        await #expect(throws: RepositoryError.serverError(code: "M403", message: "권한이 없습니다.")) {
            try await sut.deleteMember(googleAccessToken: nil, kakaoAccessToken: nil)
        }
    }

    @Test("deleteMember — 서버 에러 본문(requestFailed)을 RepositoryError.serverError로 승격한다")
    func deleteMemberMapsServerError() async {
        let body = Fixture.failureBody(code: "M403", message: "권한이 없습니다.")
        let (sut, _) = makeRepository(
            .failure(NetworkError.requestFailed(statusCode: 403, data: body))
        )

        await #expect(throws: RepositoryError.serverError(code: "M403", message: "권한이 없습니다.")) {
            try await sut.deleteMember(googleAccessToken: nil, kakaoAccessToken: nil)
        }
    }

    @Test("deleteMember — 파싱 불가한 NetworkError는 원본 그대로 전파한다")
    func deleteMemberPropagatesNonMappableError() async {
        let (sut, _) = makeRepository(.failure(NetworkError.timeout))

        await #expect(throws: NetworkError.timeout) {
            try await sut.deleteMember(googleAccessToken: nil, kakaoAccessToken: nil)
        }
    }
}

// MARK: - Suite: 명함 연락처·링크 (#1678)

@Suite("CardContactSettingsRepository — 명함 수정 API")
struct CardContactSettingsRepositoryTests {

    private static let editJSON = """
    {
      "memberId": "1", "name": "김유엠", "schoolName": "한성대학교",
      "contact": { "email": "one@umc.dev", "isPublic": false },
      "links": [
        { "type": "LINKEDIN", "link": null, "isPublic": true },
        { "type": "INSTAGRAM", "link": "https://instagram.com/umc", "isPublic": false },
        { "type": "GITHUB", "link": "https://github.com/umc", "isPublic": true },
        { "type": "BLOG", "link": null, "isPublic": true },
        { "type": "PERSONAL", "link": null, "isPublic": true },
        { "type": "THREADS", "link": "https://threads.net/umc", "isPublic": true }
      ]
    }
    """

    private func makeSUT(
        _ outcome: StubMyPageNetwork.Outcome,
        profileRepository: MockMemberProfileRepository = MockMemberProfileRepository()
    ) -> (CardContactSettingsRepository, StubMyPageNetwork) {
        let stub = StubMyPageNetwork(outcome)
        let sut = CardContactSettingsRepository(
            networkRequesting: stub,
            memberProfileRepository: profileRepository
        )
        return (sut, stub)
    }

    @Test("조회 — GET /member/me/business-card/edit 응답을 이메일 공개 여부·링크로 옮기고 모르는 종류는 버린다")
    func fetchMapsEditResponse() async throws {
        let (sut, stub) = makeSUT(.success(Fixture.success(Self.editJSON)))

        let settings = try await sut.fetchCardContactSettings()

        #expect(stub.lastPath == "/api/v1/member/me/business-card/edit")
        #expect(stub.lastMethod == .get)
        #expect(settings.isEmailPublic == false)
        #expect(settings.contactEmail == "one@umc.dev")
        #expect(settings.link(.github) == CardContactItem(value: "https://github.com/umc", isPublic: true))
        #expect(settings.link(.instagram).isPublic == false)
        #expect(settings.link(.linkedin) == CardContactItem(value: "", isPublic: true))
        #expect(settings.links.count == SocialLinkType.allCases.count)
    }

    @Test("저장 — PATCH /member/me/business-card 로 보내고, 저장 뒤 정본 프로필을 강제로 다시 읽는다")
    func updateSendsPatchAndRefreshesProfile() async throws {
        let profileRepository = MockMemberProfileRepository()
        let (sut, stub) = makeSUT(
            .success(Fixture.success(Self.editJSON)),
            profileRepository: profileRepository
        )
        let input = CardContactSettings(
            isEmailPublic: false,
            links: [.github: CardContactItem(value: "https://github.com/umc", isPublic: true)]
        )

        let saved = try await sut.updateCardContactSettings(input)

        #expect(stub.lastPath == "/api/v1/member/me/business-card")
        #expect(stub.lastMethod == .patch)
        guard case let .patchMyBusinessCard(request) = try #require(stub.lastTarget) else {
            Issue.record("기대한 라우터 케이스는 .patchMyBusinessCard 입니다"); return
        }
        #expect(request == EditBusinessCardRequestDTO(settings: input))
        #expect(saved.isEmailPublic == false)
        #expect(profileRepository.fetchMyProfileCallCount == 1)
        #expect(profileRepository.lastForceRefresh == true)
    }

    @Test("저장 뒤 프로필 재조회가 실패해도 저장 결과는 그대로 돌려준다")
    func updateIgnoresProfileRefreshFailure() async throws {
        // MockMemberProfileRepository 기본값은 실패(notStubbed)다.
        let (sut, _) = makeSUT(.success(Fixture.success(Self.editJSON)))

        let saved = try await sut.updateCardContactSettings(CardContactSettings())

        #expect(saved.link(.github).value == "https://github.com/umc")
    }

    @Test("저장 — 서버 검증 실패 본문(requestFailed)을 RepositoryError.serverError로 승격하고 프로필은 다시 읽지 않는다")
    func updateMapsServerErrorWithoutRefresh() async {
        let profileRepository = MockMemberProfileRepository()
        let body = Fixture.failureBody(code: "COMMON-400", message: "이메일 형식이 아닙니다.")
        let (sut, _) = makeSUT(
            .failure(NetworkError.requestFailed(statusCode: 400, data: body)),
            profileRepository: profileRepository
        )

        await #expect(throws: RepositoryError.serverError(
            code: "COMMON-400", message: "이메일 형식이 아닙니다."
        )) {
            _ = try await sut.updateCardContactSettings(CardContactSettings())
        }
        #expect(profileRepository.fetchMyProfileCallCount == 0)
    }
}

// MARK: - Suite: 프로필 이미지 업로드 오케스트레이션

@Suite("MyPageRepository — 프로필 이미지 업로드 오케스트레이션")
struct MyPageRepositoryUpdateImageTests {

    @Test("updateProfileImage — prepare→upload→confirm 순서로 스토리지를 호출한 뒤 member를 PATCH한다")
    func updateImageOrchestratesUploadThenPatch() async throws {
        let storage = FakeStorageRepository()
        let stub = StubMyPageNetwork(.success(Fixture.success(Fixture.profileObject)))
        let sut = MyPageRepository(
            networkRequesting: stub,
            memberProfileRepository: MockMemberProfileRepository(),
            storageRepository: storage
        )
        let imageData = Data([0x01, 0x02, 0x03])

        let result = try await sut.updateProfileImage(
            imageData: imageData,
            fileName: "profile.jpg",
            contentType: "image/jpeg"
        )

        // 스토리지 3단계 순서·인자
        #expect(storage.callOrder == ["prepare", "upload", "confirm"])
        #expect(storage.prepareReceived?.fileName == "profile.jpg")
        #expect(storage.prepareReceived?.contentType == "image/jpeg")
        #expect(storage.prepareReceived?.fileSize == 3)
        #expect(storage.prepareReceived?.category == .profileImage)
        #expect(storage.confirmReceivedFileId == "file-1")   // prepare가 준 fileId로 confirm

        // 업로드 후 회원 프로필 PATCH → ProfileData 매핑
        #expect(stub.lastPath == "/api/v1/member")
        #expect(stub.lastMethod == .patch)
        #expect(result.challengeId == 777)
    }

    @Test("updateProfileImage — 성공 시 정본 프로필 캐시를 PATCH 응답 스냅샷으로 갱신한다")
    func updateImagePrimesMemberProfileCache() async throws {
        let storage = FakeStorageRepository()
        let stub = StubMyPageNetwork(.success(Fixture.success(Fixture.profileObject)))
        let memberProfileRepository = MockMemberProfileRepository()
        let sut = MyPageRepository(
            networkRequesting: stub,
            memberProfileRepository: memberProfileRepository,
            storageRepository: storage
        )

        _ = try await sut.updateProfileImage(
            imageData: Data([0x01, 0x02, 0x03]),
            fileName: "profile.jpg",
            contentType: "image/jpeg"
        )

        #expect(memberProfileRepository.primeCacheCallCount == 1)
        #expect(memberProfileRepository.primedProfiles.first?.memberId == "42")
    }
}
