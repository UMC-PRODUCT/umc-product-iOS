//
//  AuthenticationPolicyTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 1/10/26.

import XCTest
@testable import AppProduct

final class AuthenticationPolicyTests: XCTestCase {

    private var sut: DefaultAuthenticationPolicy!

    override func setUp() {
        super.setUp()
        sut = DefaultAuthenticationPolicy()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - requireAuthentication Tests

    func test_requireAuthentication_항상_true를_반환한다() {
        let request = URLRequest(url: URL(string: "https://api.블라블라.com/any")!)
        let result = sut.requireAuthentication(request)
        XCTAssertTrue(result)
    }

    func test_requireAuthentication_다양한_URL에서_true를_반환한다() {
        let urls = [
            "https://api.블라블라.com/users",
            "https://api.블라블라.com/posts",
            "https://api.블라블라.com/auth/logout",
            "http://localhost:8080/test"
        ]

        for urlString in urls {
            let request = URLRequest(url: URL(string: urlString)!)
            let result = sut.requireAuthentication(request)
            XCTAssertTrue(result, "URL: \(urlString)")
        }
    }

    // MARK: - isUnauthorizedResponse Tests

    func test_isUnauthorizedResponse_401일때_true를_반환한다() {
        let response = makeHTTPResponse(statusCode: 401)
        let result = sut.isUnauthorizedResponse(response)
        XCTAssertTrue(result)
    }

    func test_isUnauthorizedResponse_200일때_false를_반환한다() {
        let response = makeHTTPResponse(statusCode: 200)
        let result = sut.isUnauthorizedResponse(response)
        XCTAssertFalse(result)
    }

    func test_isUnauthorizedResponse_403일때_false를_반환한다() {
        let response = makeHTTPResponse(statusCode: 403)
        let result = sut.isUnauthorizedResponse(response)
        XCTAssertFalse(result)
    }

    func test_isUnauthorizedResponse_500일때_false를_반환한다() {
        let response = makeHTTPResponse(statusCode: 500)
        let result = sut.isUnauthorizedResponse(response)
        XCTAssertFalse(result)
    }

    func test_isUnauthorizedResponse_다양한_상태코드에서_401만_true를_반환한다() {
        let statusCodes = [200, 201, 204, 301, 400, 401, 403, 404, 500, 502, 503]

        for statusCode in statusCodes {
            let response = makeHTTPResponse(statusCode: statusCode)
            let result = sut.isUnauthorizedResponse(response)

            if statusCode == 401 {
                XCTAssertTrue(result, "Status code \(statusCode) should be unauthorized")
            } else {
                XCTAssertFalse(result, "Status code \(statusCode) should NOT be unauthorized")
            }
        }
    }

    // MARK: - Helpers

    private func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://api.블라블라.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}
