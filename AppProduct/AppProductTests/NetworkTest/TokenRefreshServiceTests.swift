//
//  TokenRefreshServiceTests.swift
//
//  Auth.swift
//  AppProductTests
//
//  Created by euijjang97 on 1/10/26.
//
//  로컬 서버(localhost:8080)를 사용한 TokenRefreshService 통합 테스트
//  테스트 전 AppProductTestServer를 실행해야 합니다:
//  cd AppProductTestServer && swift run
//

import XCTest
@testable import AppProduct

final class TokenRefreshServiceTests: XCTestCase {

    private let baseURL = URL(string: "http://localhost:8080")!
    private var sut: TokenRefreshServiceImpl!

    override func setUp() async throws {
        try await super.setUp()
        guard ProcessInfo.processInfo.environment["RUN_INTEGRATION_TESTS"] == "1" else {
            throw XCTSkip("Integration tests are disabled. Set RUN_INTEGRATION_TESTS=1 to run.")
        }
        guard await isServerReachable() else {
            throw XCTSkip("AppProductTestServer(localhost:8080) is not running.")
        }
        sut = TokenRefreshServiceImpl(baseURL: baseURL)
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Success Tests

    func test_유효한_리프레시_토큰으로_갱신_성공() async throws {
        let validRefreshToken = "valid_refresh_token"

        let tokenPair = try await sut.refresh(validRefreshToken)

        let accessToken = tokenPair.accessToken
        let refreshToken = tokenPair.refreshToken

        XCTAssertFalse(accessToken.isEmpty)
        XCTAssertFalse(refreshToken.isEmpty)
        XCTAssertTrue(accessToken.hasPrefix("new_access_token_"))
        XCTAssertTrue(refreshToken.hasPrefix("new_refresh_token_"))
    }

    func test_갱신된_토큰으로_다시_갱신_가능() async throws {
        let firstRefreshToken = "valid_refresh_token"

        let firstTokenPair = try await sut.refresh(firstRefreshToken)

        let secondTokenPair = try await sut.refresh(firstTokenPair.refreshToken)

        let firstAccess = firstTokenPair.accessToken
        let firstRefresh = firstTokenPair.refreshToken
        let secondAccess = secondTokenPair.accessToken
        let secondRefresh = secondTokenPair.refreshToken

        XCTAssertNotEqual(firstAccess, secondAccess)
        XCTAssertNotEqual(firstRefresh, secondRefresh)
    }

    // MARK: - Error Tests

    func test_만료된_리프레시_토큰으로_갱신시_에러() async throws {
        let expiredToken = "expired_token"

        do {
            _ = try await sut.refresh(expiredToken)
            XCTFail("에러가 발생해야 합니다")
        } catch let error as TokenRefreshError {
            if case .serverError(let statusCode) = error {
                XCTAssertEqual(statusCode, 401)
            } else {
                XCTFail("serverError(401)이 발생해야 합니다: \(error)")
            }
        }
    }

    func test_유효하지_않은_리프레시_토큰으로_갱신시_에러() async throws {
        let invalidToken = "invalid_token"

        do {
            _ = try await sut.refresh(invalidToken)
            XCTFail("에러가 발생해야 합니다")
        } catch let error as TokenRefreshError {
            if case .serverError(let statusCode) = error {
                XCTAssertEqual(statusCode, 401)
            } else {
                XCTFail("serverError(401)이 발생해야 합니다: \(error)")
            }
        }
    }

    func test_서버_에러_발생시_에러() async throws {
        let serverErrorToken = "server_error"

        do {
            _ = try await sut.refresh(serverErrorToken)
            XCTFail("에러가 발생해야 합니다")
        } catch let error as TokenRefreshError {
            if case .serverError(let statusCode) = error {
                XCTAssertEqual(statusCode, 500)
            } else {
                XCTFail("serverError(500)이 발생해야 합니다: \(error)")
            }
        }
    }

    func test_빈_리프레시_토큰으로_갱신시_에러() async throws {
        let emptyToken = ""

        do {
            _ = try await sut.refresh(emptyToken)
            XCTFail("에러가 발생해야 합니다")
        } catch let error as TokenRefreshError {
            if case .serverError(let statusCode) = error {
                XCTAssertEqual(statusCode, 401)
            } else {
                XCTFail("serverError(401)이 발생해야 합니다: \(error)")
            }
        }
    }

    // MARK: - Request Format Tests

    func test_올바른_엔드포인트로_요청() async throws {
        let validToken = "valid_refresh_token"

        let tokenPair = try await sut.refresh(validToken)

        XCTAssertNotNil(tokenPair)
    }

    private func isServerReachable() async -> Bool {
        var request = URLRequest(url: baseURL)
        request.timeoutInterval = 1
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}
