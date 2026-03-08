//
//  TokenRefreshServiceRequestTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 3/9/26.
//

import Foundation
import XCTest
@testable import AppProduct

final class TokenRefreshServiceRequestTests: XCTestCase {

    private let baseURL = URL(string: "https://example.com")!

    override func tearDown() {
        RequestCapturingURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func test_refreshToken을_JSON_Body로_전송한다() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RequestCapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)

        RequestCapturingURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/token/renew")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Content-Type"),
                "application/json"
            )
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))

            let body = try XCTUnwrap(request.httpBody)
            let payload = try JSONSerialization.jsonObject(with: body) as? [String: String]
            XCTAssertEqual(payload?["refreshToken"], "refresh-token-value")

            let responseBody = """
            {
              "isSuccess": true,
              "code": "200",
              "message": "성공",
              "result": {
                "accessToken": "new_access_token",
                "refreshToken": "new_refresh_token"
              }
            }
            """.data(using: .utf8) ?? Data()

            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            return (response, responseBody)
        }

        let sut = TokenRefreshServiceImpl(baseURL: baseURL, session: session)

        let tokenPair = try await sut.refresh("refresh-token-value")

        XCTAssertEqual(tokenPair.accessToken, "new_access_token")
        XCTAssertEqual(tokenPair.refreshToken, "new_refresh_token")
    }
}

private final class RequestCapturingURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(
                self,
                didFailWithError: URLError(.badServerResponse)
            )
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(
                self,
                didReceive: response,
                cacheStoragePolicy: .notAllowed
            )
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
