//
//  SignUpFlowTests.swift
//  AppProductTests
//
//  Created by jaewon Lee on 2/10/26.
//

import Testing
@testable import AppProduct
import Foundation
internal import Moya

// MARK: - TestConfig

/// `.test-config.json`에서 읽어오는 테스트 설정(gitignore)
private struct TestConfig: Codable {
    let kakaoAccessToken: String
    let kakaoEmail: String
    let testEmail: String
    /// 테스트 2번 실행 후 콘솔에서 복사
    let emailVerificationId: String
    let emailVerificationCode: String
    let testName: String
    let testNickname: String
}

// MARK: - SignUpFlowTests

/// 회원가입 통합 테스트
///
/// AuthRepository를 사용하여 실제 앱과 동일한 경로로 API 호출.
///
/// 사용법:
/// 1. iOS/.test-config.json에 카카오 토큰, 이메일 등 입력
/// 2. `sendEmailVerification` 테스트 실행 → 콘솔에서 emailVerificationId 복사
/// 3. .test-config.json에 emailVerificationId + 이메일로 받은 인증코드 입력
/// 4. `verifyEmailCode` 테스트 실행 → 인증코드 검증
/// 5. `fullSignUpFlow` 테스트 실행 → 전체 플로우 검증
@Suite("이메일 인증 테스트")
@MainActor
struct EmailVelificationTests {

    // MARK: - Property

    private let repository: AuthRepository

    // MARK: - Init

    init() {
        let baseURL = URL(string: Config.baseURL)!
        let networkClient = AuthSystemFactory.makeNetworkClient(
            baseURL: baseURL
        )
        let adapter = MoyaNetworkAdapter(
            networkClient: networkClient,
            baseURL: baseURL
        )
        self.repository = AuthRepository(adapter: adapter)
    }

    // MARK: - Config 로딩

    /// `.test-config.json` 파일에서 테스트 설정을 로딩합니다.
    private func loadConfig() throws -> TestConfig {
        let testFilePath = URL(fileURLWithPath: #filePath)
        let projectRoot = testFilePath
            .deletingLastPathComponent()  // AppProductTests/
            .deletingLastPathComponent()  // AppProduct/
            .deletingLastPathComponent()  // iOS/
        let configURL = projectRoot
            .appendingPathComponent(".test-config.json")
        let data = try Data(contentsOf: configURL)
        return try JSONDecoder().decode(TestConfig.self, from: data)
    }

    /// 통합 테스트 실행 조건을 확인합니다.
    private func isIntegrationReady() -> Bool {
        guard ProcessInfo.processInfo.environment["RUN_INTEGRATION_TESTS"] == "1" else {
            return false
        }
        return (try? loadConfig()) != nil
    }

    @Test("이메일 인증 발송")
    func sendEmailVerification() async throws {
        guard isIntegrationReady() else { return }
        let config = try loadConfig()

        let emailVerificationId = try await repository.sendEmailVerification(
            email: config.testEmail
        )

        print("[Test] emailVerificationId: \(emailVerificationId)")
        #expect(!emailVerificationId.isEmpty)
    }

    @Test("3. 이메일 인증코드 검증")
    func verifyEmailCode() async throws {
        guard isIntegrationReady() else { return }
        let config = try loadConfig()

        let emailVerificationToken = try await repository.verifyEmailCode(
            emailVerificationId: config.emailVerificationId,
            verificationCode: config.emailVerificationCode
        )

        print("[Test] emailVerificationToken: \(emailVerificationToken)")
        #expect(!emailVerificationToken.isEmpty)
    }

    @Test("4. 학교 목록 조회")
    func fetchSchools() async throws {
        guard isIntegrationReady() else { return }
        let schools = try await repository.getSchools()

        print("[Test] 학교 수: \(schools.count)")
        for school in schools {
            print("  - \(school.id): \(school.name)")
        }
        #expect(!schools.isEmpty)
    }

    @Test("5. 약관 조회")
    func fetchTerms() async throws {
        guard isIntegrationReady() else { return }
        for type in TermsType.allCases {
            let terms = try await repository.getTerms(
                termsType: type.rawValue
            )

            print(
                "[Test] \(type.rawValue) - id:\(terms.id), " +
                "title:\(terms.title), mandatory:\(terms.isMandatory)"
            )
            #expect(!terms.title.isEmpty)
        }
    }
}
