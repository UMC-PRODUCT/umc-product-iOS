//
//  MoyaNetworkAdapterRequestEncodingTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 3/9/26.
//

import Foundation
internal import Alamofire
import Moya
import XCTest
@testable import AppProduct

@MainActor
final class MoyaNetworkAdapterRequestEncodingTests: XCTestCase {

    private let baseURL = URL(string: "https://example.com")!

    override func tearDown() {
        RequestCapturingURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func test_requestJSONEncodable가_JSON_Body를_안전하게_인코딩한다() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RequestCapturingURLProtocol.self]
        let session = URLSession(configuration: configuration)

        let networkClient = NetworkClient(
            session: session,
            tokenStore: StubTokenStore(),
            refreshService: StubTokenRefreshService(),
            authPolicy: NonAuthenticatedPolicy()
        )
        let sut = MoyaNetworkAdapter(networkClient: networkClient, baseURL: baseURL)

        RequestCapturingURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/schedules/12/location")
            XCTAssertEqual(request.httpMethod, "PATCH")
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Content-Type"),
                "application/json"
            )

            let body = try XCTUnwrap(request.httpBody)
            let payload = try XCTUnwrap(
                JSONSerialization.jsonObject(with: body) as? [String: Any]
            )

            XCTAssertEqual(payload["locationName"] as? String, "UMC Lounge")
            XCTAssertEqual(payload["latitude"] as? Double, 37.1234)
            XCTAssertEqual(payload["longitude"] as? Double, 127.5678)

            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            let responseBody = """
            {
              "isSuccess": true,
              "code": "200",
              "message": "성공",
              "result": null
            }
            """.data(using: .utf8) ?? Data()

            return (response, responseBody)
        }

        _ = try await sut.request(
            TestTarget.patchScheduleLocation(
                scheduleId: 12,
                body: TestScheduleLocationUpdateRequestDTO(
                    locationName: "UMC Lounge",
                    latitude: 37.1234,
                    longitude: 127.5678
                )
            )
        )
    }
}

private enum TestTarget: TargetType {
    case patchScheduleLocation(scheduleId: Int, body: TestScheduleLocationUpdateRequestDTO)

    var baseURL: URL {
        URL(string: "https://example.com")!
    }

    var path: String {
        switch self {
        case .patchScheduleLocation(let scheduleId, _):
            return "/api/v1/schedules/\(scheduleId)/location"
        }
    }

    var method: Moya.Method {
        .patch
    }

    var sampleData: Data {
        Data()
    }

    var task: Moya.Task {
        switch self {
        case .patchScheduleLocation(_, let body):
            return .requestJSONEncodable(body)
        }
    }

    var validationType: ValidationType {
        .none
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
}

private struct TestScheduleLocationUpdateRequestDTO: Encodable, Sendable, Equatable {
    let locationName: String
    let latitude: Double
    let longitude: Double
}

private actor StubTokenStore: TokenStore {
    func getAccessToken() async -> String? { nil }
    func getRefreshToken() async -> String? { nil }
    func save(accessToken: String, refreshToken: String) async throws {}
    func clear() async throws {}
}

private struct StubTokenRefreshService: TokenRefreshService {
    func refresh(_ refreshToken: String) async throws -> TokenPair {
        throw NetworkError.tokenRefreshFailed(reason: nil)
    }
}

private struct NonAuthenticatedPolicy: AuthenticationPolicy {
    nonisolated func requireAuthentication(_ request: URLRequest) -> Bool {
        false
    }

    nonisolated func isUnauthorizedResponse(_ response: HTTPURLResponse) -> Bool {
        false
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
