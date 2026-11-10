//
//  AuthRepositoryTests.swift
//  AuthDataTests
//
//  Created by euijjang97 on 7/11/26.
//

//  진짜 `AuthRepository`를 대상으로, 그 아래 네트워크 계층만 가짜(`StubAuthNetwork`)로 주입해
//  `registerByEmail`/`loginByEmail`의 디코딩·도메인 매핑·토큰 저장·에러 매핑 계약을 검증한다.
//  (엔드포인트 path/method/task 계약은 `AuthRouterTests`에서 별도 검증)
//

import Foundation
import Testing
import Moya
import CoreNetwork
import UMCFoundation
import AuthDomain
@testable import AuthData

// MARK: - Test Doubles

/// ``AuthNetworkRequesting`` 가짜 구현.
///
/// 미리 설정한 결과(성공 본문 / 던질 에러)를 반환하고, 호출된 라우터의 경로·메서드·타깃을
/// 기록해 엔드포인트 계약과 전송 페이로드를 검증할 수 있게 한다.
/// `target.path`/`target.method`만 읽어 `NetworkConfig.baseURL`(테스트 번들 `fatalError`)을
/// 건드리지 않는다.
private final class StubAuthNetwork: AuthNetworkRequesting, @unchecked Sendable {

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
    private(set) var lastTarget: AuthRouter?

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
        lastTarget = target as? AuthRouter
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

/// ``TokenStore`` 가짜 구현. `save(accessToken:refreshToken:)` 호출 인자를 기록한다.
private actor FakeTokenStore: TokenStore {
    private(set) var savedAccessToken: String?
    private(set) var savedRefreshToken: String?
    private(set) var saveCallCount = 0

    func getAccessToken() async -> String? { savedAccessToken }
    func getRefreshToken() async -> String? { savedRefreshToken }

    func save(accessToken: String, refreshToken: String) async throws {
        saveCallCount += 1
        savedAccessToken = accessToken
        savedRefreshToken = refreshToken
    }

    func clear() async throws {
        savedAccessToken = nil
        savedRefreshToken = nil
    }
}

/// ``TokenRefreshService`` 가짜 구현. 이메일 가입/로그인은 갱신 경로를 타지 않으므로 항상 실패한다.
private struct FakeTokenRefreshService: TokenRefreshService {
    func refresh(_ refreshToken: String) async throws -> TokenPair {
        throw NetworkError.timeout
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

    /// isSuccess:false 실패 봉투
    static func failureBody(code: String?, message: String?) -> Data {
        var fields: [String] = ["\"success\": false"]
        if let code { fields.append("\"code\": \"\(code)\"") }
        if let message { fields.append("\"message\": \"\(message)\"") }
        fields.append("\"result\": null")
        return Data("{ \(fields.joined(separator: ", ")) }".utf8)
    }

    /// 이메일 회원가입 result 본문
    static func registerByEmailObject(
        memberId: String = "42",
        accessToken: String = "access-token-1",
        refreshToken: String = "refresh-token-1"
    ) -> String {
        """
        {
            "memberId": "\(memberId)",
            "accessToken": "\(accessToken)",
            "refreshToken": "\(refreshToken)"
        }
        """
    }

    /// 이메일 로그인 result 본문
    static func loginByEmailObject(
        memberId: String = "42",
        accessToken: String = "login-access-token",
        refreshToken: String = "login-refresh-token"
    ) -> String {
        """
        {
            "memberId": "\(memberId)",
            "accessToken": "\(accessToken)",
            "refreshToken": "\(refreshToken)"
        }
        """
    }

    /// 비-2xx 응답 본문 (서버 에러 코드 매핑 검증용)
    static func networkRequestFailed(
        statusCode: Int = 401,
        code: String,
        message: String
    ) -> NetworkError {
        let body = Data("{ \"code\": \"\(code)\", \"message\": \"\(message)\" }".utf8)
        return NetworkError.requestFailed(statusCode: statusCode, data: body)
    }
}

// MARK: - Helper

@MainActor
private func makeRepository(
    _ outcome: StubAuthNetwork.Outcome,
    tokenStore: FakeTokenStore = FakeTokenStore()
) -> (AuthRepository, StubAuthNetwork, FakeTokenStore) {
    let stub = StubAuthNetwork(outcome)
    let networkClient = AuthSystemFactory.makeTestNetworkClient(
        tokenStore: tokenStore,
        refreshService: FakeTokenRefreshService()
    )
    let repository = AuthRepository(
        networkRequesting: stub,
        networkClient: networkClient,
        tokenStore: tokenStore
    )
    return (repository, stub, tokenStore)
}

private func makeTermsAgreements() -> [TermsAgreement] {
    [TermsAgreement(termsId: "terms-1", isAgreed: true)]
}

// MARK: - Suite: 이메일(ID/PW) 회원가입

@MainActor
@Suite("AuthRepository — registerByEmail")
struct AuthRepositoryRegisterByEmailTests {

    @Test("닉네임 확인은 학교·닉네임 쿼리를 인증 없이 보내고 사용 가능 여부를 읽는다",
          arguments: [true, false])
    func nicknameAvailability(_ available: Bool) async throws {
        let (sut, network, _) = makeRepository(
            .success(Fixture.success(#"{ "available": \#(available) }"#))
        )

        let result = try await sut.checkNicknameAvailability(schoolId: "23", nickname: "하늘")
        #expect(result == available)
        #expect(network.requestWithoutAuthCount == 1)
        #expect(network.lastMethod == .get)
        #expect(network.lastPath == "/api/v1/member/nicknames/availability")
        guard case .requestParameters(let parameters, _) = network.lastTarget?.task else {
            Issue.record("닉네임 확인 쿼리가 없습니다")
            return
        }
        #expect(parameters as? [String: String] == ["schoolId": "23", "nickname": "하늘"])
    }

    @Test("가입 요청의 409 MEMBER-0020을 닉네임 충돌로 전달한다", arguments: [true, false])
    func mapsNicknameConflict(emailRegistration: Bool) async {
        let (sut, _, tokenStore) = makeRepository(.failure(Fixture.networkRequestFailed(
            statusCode: 409, code: "MEMBER-0020", message: "중복 닉네임"
        )))
        await #expect(throws: RegistrationError.nicknameAlreadyUsed) {
            if emailRegistration {
                _ = try await sut.registerByEmail(
                    rawPassword: "password1234", name: "홍길동", nickname: "하늘",
                    emailVerificationToken: "verified", schoolId: "1", termsAgreements: []
                )
            } else {
                _ = try await sut.register(
                    oAuthVerificationToken: "oauth", name: "홍길동", nickname: "하늘",
                    emailVerificationToken: "verified", schoolId: "1",
                    profileImageId: nil, termsAgreements: []
                )
            }
        }
        #expect(await tokenStore.saveCallCount == 0)
    }

    @Test("성공 응답이면 토큰을 저장하고 RegisterByIdPwResult를 반환하며 /member/register/email(POST, 비인증)을 호출한다")
    func registerByEmailSucceeds() async throws {
        let (sut, stub, tokenStore) = makeRepository(
            .success(Fixture.success(Fixture.registerByEmailObject()))
        )

        let result = try await sut.registerByEmail(
            rawPassword: "password1234",
            name: "홍길동",
            nickname: "길동이",
            emailVerificationToken: "verify-token-1",
            schoolId: "1",
            termsAgreements: makeTermsAgreements()
        )

        #expect(result.memberId == "42")
        #expect(stub.requestWithoutAuthCount == 1)
        #expect(stub.requestCount == 0)
        #expect(stub.lastPath == "/api/v1/member/register/email")
        #expect(stub.lastMethod == .post)
        #expect(await tokenStore.saveCallCount == 1)
        #expect(await tokenStore.savedAccessToken == "access-token-1")
        #expect(await tokenStore.savedRefreshToken == "refresh-token-1")
    }

    @Test("응답에 토큰이 비어 있으면 RepositoryError.invalidResponse를 던지고 토큰을 저장하지 않는다")
    func registerByEmailThrowsInvalidResponseWhenTokensMissing() async throws {
        let (sut, _, tokenStore) = makeRepository(
            .success(Fixture.success(
                Fixture.registerByEmailObject(accessToken: "", refreshToken: "")
            ))
        )

        await #expect(throws: RepositoryError.invalidResponse(
            detail: "registerByEmail: 서버 응답에 accessToken/refreshToken이 없습니다"
        )) {
            _ = try await sut.registerByEmail(
                rawPassword: "password1234",
                name: "홍길동",
                nickname: "길동이",
                emailVerificationToken: "verify-token-1",
                schoolId: "1",
                termsAgreements: makeTermsAgreements()
            )
        }

        #expect(await tokenStore.saveCallCount == 0)
    }

    @Test("isSuccess:false면 RepositoryError.serverError를 던진다")
    func registerByEmailThrowsServerErrorWhenUnsuccessful() async {
        let (sut, _, _) = makeRepository(
            .success(Fixture.failureBody(code: "AUTH409", message: "이미 가입된 이메일입니다."))
        )

        await #expect(throws: RepositoryError.serverError(
            code: "AUTH409", message: "이미 가입된 이메일입니다."
        )) {
            _ = try await sut.registerByEmail(
                rawPassword: "password1234",
                name: "홍길동",
                nickname: "길동이",
                emailVerificationToken: "verify-token-1",
                schoolId: "1",
                termsAgreements: makeTermsAgreements()
            )
        }
    }

    @Test("응답 본문을 파싱할 수 없으면 RepositoryError.decodingError를 던진다")
    func registerByEmailThrowsDecodingErrorForMalformedBody() async {
        let (sut, _, _) = makeRepository(.success(Data("not-json".utf8)))

        await #expect(throws: RepositoryError.self) {
            _ = try await sut.registerByEmail(
                rawPassword: "password1234",
                name: "홍길동",
                nickname: "길동이",
                emailVerificationToken: "verify-token-1",
                schoolId: "1",
                termsAgreements: makeTermsAgreements()
            )
        }
    }

    @Test("파싱 불가한 NetworkError는 원본 그대로 전파한다")
    func registerByEmailPropagatesNonMappableError() async {
        let (sut, _, _) = makeRepository(.failure(NetworkError.timeout))

        await #expect(throws: NetworkError.timeout) {
            _ = try await sut.registerByEmail(
                rawPassword: "password1234",
                name: "홍길동",
                nickname: "길동이",
                emailVerificationToken: "verify-token-1",
                schoolId: "1",
                termsAgreements: makeTermsAgreements()
            )
        }
    }
}

// MARK: - Suite: 이메일(ID/PW) 로그인

@MainActor
@Suite("AuthRepository — loginByEmail")
struct AuthRepositoryLoginByEmailTests {

    @Test("성공 응답이면 토큰을 저장하고 LoginByIdPwResult를 반환하며 /auth/login/email(POST, 비인증)을 호출한다")
    func loginByEmailSucceeds() async throws {
        let (sut, stub, tokenStore) = makeRepository(
            .success(Fixture.success(Fixture.loginByEmailObject()))
        )

        let result = try await sut.loginByEmail(email: "a@umc.kr", password: "password1234")

        #expect(result.memberId == "42")
        #expect(stub.requestWithoutAuthCount == 1)
        #expect(stub.requestCount == 0)
        #expect(stub.lastPath == "/api/v1/auth/login/email")
        #expect(stub.lastMethod == .post)
        #expect(await tokenStore.saveCallCount == 1)
        #expect(await tokenStore.savedAccessToken == "login-access-token")
        #expect(await tokenStore.savedRefreshToken == "login-refresh-token")
    }

    @Test("응답에 토큰이 비어 있으면 RepositoryError.invalidResponse를 던지고 토큰을 저장하지 않는다")
    func loginByEmailThrowsInvalidResponseWhenTokensMissing() async throws {
        let (sut, _, tokenStore) = makeRepository(
            .success(Fixture.success(
                Fixture.loginByEmailObject(accessToken: "", refreshToken: "")
            ))
        )

        await #expect(throws: RepositoryError.invalidResponse(
            detail: "loginByEmail: 서버 응답에 accessToken/refreshToken이 없습니다"
        )) {
            _ = try await sut.loginByEmail(email: "a@umc.kr", password: "password1234")
        }

        #expect(await tokenStore.saveCallCount == 0)
    }

    @Test("accessToken만 비어 있어도 RepositoryError.invalidResponse를 던진다")
    func loginByEmailThrowsInvalidResponseWhenAccessTokenMissing() async throws {
        let (sut, _, tokenStore) = makeRepository(
            .success(Fixture.success(Fixture.loginByEmailObject(accessToken: "")))
        )

        await #expect(throws: RepositoryError.invalidResponse(
            detail: "loginByEmail: 서버 응답에 accessToken/refreshToken이 없습니다"
        )) {
            _ = try await sut.loginByEmail(email: "a@umc.kr", password: "password1234")
        }

        #expect(await tokenStore.saveCallCount == 0)
    }

    @Test("isSuccess:false면 RepositoryError.serverError를 던진다")
    func loginByEmailThrowsServerErrorWhenUnsuccessful() async {
        let (sut, _, _) = makeRepository(
            .success(Fixture.failureBody(
                code: "AUTHENTICATION-0022",
                message: "이메일 또는 비밀번호가 올바르지 않습니다."
            ))
        )

        await #expect(throws: RepositoryError.serverError(
            code: "AUTHENTICATION-0022", message: "이메일 또는 비밀번호가 올바르지 않습니다."
        )) {
            _ = try await sut.loginByEmail(email: "a@umc.kr", password: "wrong-password")
        }
    }

    @Test("비-2xx NetworkError는 본문을 파싱해 RepositoryError.serverError로 정규화한다")
    func loginByEmailMapsNetworkErrorToServerError() async {
        let (sut, _, _) = makeRepository(.failure(Fixture.networkRequestFailed(
            code: "AUTHENTICATION-0022",
            message: "이메일 또는 비밀번호가 올바르지 않습니다."
        )))

        await #expect(throws: RepositoryError.serverError(
            code: "AUTHENTICATION-0022", message: "이메일 또는 비밀번호가 올바르지 않습니다."
        )) {
            _ = try await sut.loginByEmail(email: "a@umc.kr", password: "wrong-password")
        }
    }

    @Test("응답 본문을 파싱할 수 없으면 RepositoryError.decodingError를 던진다")
    func loginByEmailThrowsDecodingErrorForMalformedBody() async {
        let (sut, _, _) = makeRepository(.success(Data("not-json".utf8)))

        await #expect(throws: RepositoryError.self) {
            _ = try await sut.loginByEmail(email: "a@umc.kr", password: "password1234")
        }
    }

    @Test("파싱 불가한 NetworkError는 원본 그대로 전파한다")
    func loginByEmailPropagatesNonMappableError() async {
        let (sut, _, _) = makeRepository(.failure(NetworkError.timeout))

        await #expect(throws: NetworkError.timeout) {
            _ = try await sut.loginByEmail(email: "a@umc.kr", password: "password1234")
        }
    }
}

// MARK: - Suite: 로컬 비밀번호 등록/보유 여부

@MainActor
@Suite("AuthRepository — local credential")
struct AuthRepositoryLocalCredentialTests {

    @Test("v2 /member/me(GET, 인증)의 hasLocalCredential을 그대로 반환한다")
    func fetchHasLocalCredentialReadsSummary() async throws {
        let (sut, stub, _) = makeRepository(.success(Fixture.success("""
        { "id": "42", "name": "제옹", "hasLocalCredential": false }
        """)))

        let hasLocalCredential = try await sut.fetchHasLocalCredential()

        #expect(hasLocalCredential == false)
        #expect(stub.requestCount == 1)
        #expect(stub.lastPath == "/api/v2/member/me")
        #expect(stub.lastMethod == .get)
    }

    @Test("hasLocalCredential 키가 없으면 true(기존 「비밀번호 변경」 동작)로 본다")
    func fetchHasLocalCredentialDefaultsToTrueWhenMissing() async throws {
        let (sut, _, _) = makeRepository(.success(Fixture.success("{ \"id\": \"42\" }")))

        #expect(try await sut.fetchHasLocalCredential() == true)
    }

    @Test("registerCredential의 비-2xx NetworkError는 RepositoryError.serverError로 정규화한다")
    func registerCredentialMapsNetworkErrorToServerError() async {
        let (sut, _, _) = makeRepository(.failure(Fixture.networkRequestFailed(
            statusCode: 400,
            code: "CREDENTIAL_ALREADY_REGISTERED",
            message: "이미 비밀번호가 등록되어 있습니다."
        )))

        await #expect(throws: RepositoryError.serverError(
            code: "CREDENTIAL_ALREADY_REGISTERED", message: "이미 비밀번호가 등록되어 있습니다."
        )) {
            try await sut.registerCredential(rawPassword: "password1234")
        }
    }
}

// MARK: - Suite: OAuth 로그인 분기

@MainActor
@Suite("AuthRepository — Google OAuth 로그인 분기")
struct AuthRepositoryGoogleLoginTests {

    @Test("LOGIN_SUCCESS는 세션 토큰을 저장하고 기존 회원을 반환한다")
    func loginSuccessReturnsExistingMember() async throws {
        let (sut, network, tokenStore) = makeRepository(.success(oauthResponse("""
        {
            "success": true,
            "code": "LOGIN_SUCCESS",
            "accessToken": "google-access",
            "refreshToken": "google-refresh",
            "oAuthVerificationToken": null
        }
        """)))

        let result = try await sut.loginGoogle(accessToken: "provider-token")

        guard case .existingMember = result else {
            Issue.record("로그인 성공한 기존 회원을 신규 회원으로 분류했습니다")
            return
        }
        #expect(network.requestWithoutAuthCount == 1)
        #expect(await tokenStore.saveCallCount == 1)
        #expect(await tokenStore.savedAccessToken == "google-access")
        #expect(await tokenStore.savedRefreshToken == "google-refresh")
    }

    @Test("REGISTER_REQUIRED는 가입 인증 토큰을 반환하고 세션을 저장하지 않는다")
    func registrationRequiredReturnsNewMember() async throws {
        let (sut, _, tokenStore) = makeRepository(.success(oauthResponse("""
        {
            "success": true,
            "code": "REGISTER_REQUIRED",
            "accessToken": null,
            "refreshToken": null,
            "oAuthVerificationToken": "google-verification"
        }
        """)))

        let result = try await sut.loginGoogle(accessToken: "provider-token")

        guard case .newMember(let verificationToken) = result else {
            Issue.record("가입이 필요한 회원을 기존 회원으로 분류했습니다")
            return
        }
        #expect(verificationToken == "google-verification")
        #expect(await tokenStore.saveCallCount == 0)
    }

    @Test("결과 코드나 성공 상태가 없거나 잘못되면 토큰이 있어도 실패한다", arguments: [
        #""success": true, "code": "UNKNOWN""#,
        #""success": true, "code": "COMMON200""#,
        #""success": true, "code": """#,
        #""success": true, "code": null"#,
        #""success": true"#,
        #""success": false, "code": "LOGIN_SUCCESS""#,
        #""code": "LOGIN_SUCCESS""#,
        #""success": false, "code": "REGISTER_REQUIRED""#,
        #""code": "REGISTER_REQUIRED""#
    ])
    func invalidResultStatusDoesNotCreateSession(_ statusFields: String) async {
        await expectRejectedResponse("""
        {
            \(statusFields),
            "accessToken": "google-access",
            "refreshToken": "google-refresh",
            "oAuthVerificationToken": "google-verification"
        }
        """)
    }

    @Test("LOGIN_SUCCESS는 토큰 하나라도 누락되거나 비어 있으면 가입으로 우회하지 않는다",
          arguments: [
            #""refreshToken": "google-refresh""#,
            #""accessToken": "google-access""#,
            #""accessToken": null, "refreshToken": "google-refresh""#,
            #""accessToken": "google-access", "refreshToken": null"#,
            #""accessToken": "", "refreshToken": "google-refresh""#,
            #""accessToken": "google-access", "refreshToken": """#,
            #""accessToken": " \n\t", "refreshToken": "google-refresh""#,
            #""accessToken": "google-access", "refreshToken": " \n\t""#,
            #""accessToken": null, "refreshToken": null"#
          ])
    func incompleteLoginTokensDoNotFallBackToRegistration(_ tokenFields: String) async {
        await expectRejectedResponse("""
        {
            "success": true,
            "code": "LOGIN_SUCCESS",
            \(tokenFields),
            "oAuthVerificationToken": "google-verification"
        }
        """)
    }

    @Test("REGISTER_REQUIRED는 인증 토큰이 누락되거나 비어 있으면 기존 회원으로 우회하지 않는다",
          arguments: [
            "",
            #", "oAuthVerificationToken": null"#,
            #", "oAuthVerificationToken": """#,
            #", "oAuthVerificationToken": " \n\t""#
          ])
    func incompleteRegistrationTokenDoesNotCreateSession(_ verificationField: String) async {
        await expectRejectedResponse("""
        {
            "success": true,
            "code": "REGISTER_REQUIRED",
            "accessToken": "google-access",
            "refreshToken": "google-refresh"
            \(verificationField)
        }
        """)
    }

    // MARK: - Helper

    /// 바깥 봉투의 공통 성공 코드를 회원 분기 코드로 잘못 사용하지 않도록 실제 스키마를 쓴다.
    private func oauthResponse(_ resultJSON: String) -> Data {
        Data("""
        { "success": true, "code": "COMMON200", "message": "성공", "result": \(resultJSON) }
        """.utf8)
    }

    /// 잘못된 응답은 회원 분류를 반환하거나 세션 토큰을 저장하지 않아야 한다.
    private func expectRejectedResponse(_ resultJSON: String) async {
        let (sut, _, tokenStore) = makeRepository(.success(oauthResponse(resultJSON)))

        do {
            _ = try await sut.loginGoogle(accessToken: "provider-token")
            Issue.record("잘못된 OAuth 응답에서 회원 분류를 반환했습니다")
        } catch let error as RepositoryError {
            guard case .invalidResponse = error else {
                Issue.record("응답 계약 위반 대신 다른 저장소 오류를 반환했습니다: \(error)")
                return
            }
        } catch {
            Issue.record("응답 계약 위반 대신 다른 오류를 반환했습니다: \(error)")
        }

        #expect(await tokenStore.saveCallCount == 0)
        #expect(await tokenStore.savedAccessToken == nil)
        #expect(await tokenStore.savedRefreshToken == nil)
    }
}
