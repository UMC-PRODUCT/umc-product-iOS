//
//  MemberReportRepositoryTests.swift
//  CoreNetworkTests
//
//  Created by euijjang97 on 11/1/26.
//

import CoreDomain
import Foundation
import Testing
import UMCFoundation
@testable import CoreNetwork

// 공유 URLProtocol 핸들러를 쓰는 기존 직렬 suite에 포함해 다른 네트워크 테스트와 겹치지 않는다.
extension NetworkClientTests {
    @Test("사용자 신고는 인증 POST와 복수 reasons·ETC·detail 계약을 사용한다")
    func memberReportContract() async throws {
        let draft = MemberReportDraft(reasons: [.harassment, .impersonation, .spam, .other],
                                      detail: "  원문 상세 내용  ")
        let body = MemberReportBody(draft: draft)
        let json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(body))
            as? [String: Any])
        #expect(json["reasons"] as? [String] == ["HARASSMENT", "IMPERSONATION", "SPAM", "ETC"])
        #expect(json["detail"] as? String == draft.detail)
        #expect(json["reason"] == nil)
        let repository = makeReportRepository()
        StubURLProtocol.handler = { _ in
            (Data(#"{"success":true,"result":{"reportId":"700","memberId":"12","reasons":["ETC"]}}"#.utf8),
             201, nil)
        }
        try await repository.report(memberId: "12", draft: draft)
        let request = try #require(StubURLProtocol.capturedRequests.first)
        #expect(request.url?.host == "example.test")
        #expect(request.url?.path == "/api/v1/reports/members/12")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-access")
    }

    @Test("중복·자기 신고 응답은 구체적인 도메인 오류로 전달한다")
    func memberReportServerErrors() async {
        for (code, expected) in [("COMMUNITY-0016", MemberReportError.alreadyReported),
                                 ("REPORT-0005", MemberReportError.invalidTarget)] {
            let repository = makeReportRepository()
            StubURLProtocol.handler = { _ in
                (Data("{\"success\":false,\"code\":\"\(code)\",\"message\":\"거절\"}".utf8), 403, nil)
            }
            await #expect(throws: expected) {
                try await repository.report(memberId: "12", draft: MemberReportDraft(
                    reasons: [.other], detail: "내용"
                ))
            }
        }
    }

    @Test("잘못된 접수 대상과 실패 envelope를 성공으로 처리하지 않는다")
    func memberReportRejectsInvalidReceipt() async {
        for response in [
            #"{"success":true,"result":{"reportId":"700","memberId":"13"}}"#,
            #"{"success":false,"code":"ERROR","message":"접수 실패"}"#,
            #"{"success":true,"result":null}"#
        ] {
            let repository = makeReportRepository()
            StubURLProtocol.handler = { _ in (Data(response.utf8), 201, nil) }
            await #expect(throws: (any Error).self) {
                try await repository.report(memberId: "12", draft: MemberReportDraft(
                    reasons: [.spam], detail: "내용"
                ))
            }
        }
    }

    @Test("접수 식별자는 문자열과 숫자 응답을 모두 읽는다")
    func memberReportFlexibleReceipt() throws {
        let receipt = try JSONDecoder().decode(MemberReportReceiptDTO.self,
            from: Data(#"{"reportId":700,"memberId":12}"#.utf8))
        #expect(receipt.reportId == "700")
        #expect(receipt.memberId == "12")
    }

    private func makeReportRepository() -> MemberReportRepository {
        StubURLProtocol.reset()
        let client = NetworkClient(
            session: makeStubSession(),
            tokenStore: MockTokenStore(accessToken: "test-access", refreshToken: "test-refresh"),
            refreshService: MockTokenRefreshService(behavior: .success(TokenPair(
                accessToken: "test-access", refreshToken: "test-refresh"
            ))),
            authPolicy: DefaultAuthenticationPolicy(), maxRetryCount: 0
        )
        return MemberReportRepository(adapter: MoyaNetworkAdapter(
            networkClient: client, baseURL: URL(string: "https://example.test")!
        ), baseURL: URL(string: "https://example.test")!)
    }
}
