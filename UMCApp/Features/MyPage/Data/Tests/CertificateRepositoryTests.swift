//
//  CertificateRepositoryTests.swift
//  MyPageDataTests
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import Testing
import Moya
import CoreNetwork
import UMCFoundation
import MyPageDomain
@testable import MyPageData

/// 미리 준 JSON 본문을 200 으로 돌려주고, 마지막으로 받은 라우터를 기록한다.
private final class StubCertificateNetwork: MyPageNetworkRequesting, @unchecked Sendable {

    private let body: Data
    private(set) var lastTarget: CertificateRouter?

    init(_ json: String) {
        body = Data(json.utf8)
    }

    func request<T: TargetType>(_ target: T) async throws -> Response {
        lastTarget = target as? CertificateRouter
        return Response(statusCode: 200, data: body)
    }

    func requestWithoutAuth<T: TargetType>(_ target: T) async throws -> Response {
        try await request(target)
    }
}

@Suite("CertificateRepository")
struct CertificateRepositoryTests {

    @Test("목록 조회는 GET /api/v1/certificates 를 호출하고 도메인으로 매핑한다")
    func fetchCertificates() async throws {
        let network = StubCertificateNetwork(CertificateDTOTests.listJSON)
        let repository = CertificateRepository(networkRequesting: network)

        let certificates = try await repository.fetchCertificates()

        #expect(certificates.map(\.id) == ["12", "13"])
        let target = try #require(network.lastTarget)
        #expect(target.path == "/api/v1/certificates")
        #expect(target.method == .get)
    }

    @Test("발급은 POST 바디에 템플릿과 정수 gisuId 를 싣는다")
    func issueCertificate() async throws {
        let network = StubCertificateNetwork("""
        {
            "success": true, "code": "COMMON200", "message": "성공입니다.",
            "result": { "certificateId": "12", "serialNumber": "S", "status": "ISSUED" }
        }
        """)
        let repository = CertificateRepository(networkRequesting: network)

        try await repository.issueCertificate(
            template: Certificate.selfIssuableTemplate,
            gisuId: "7"
        )

        let target = try #require(network.lastTarget)
        #expect(target.path == "/api/v1/certificates")
        #expect(target.method == .post)
        guard case .requestJSONEncodable(let body) = target.task else {
            Issue.record("Expected .requestJSONEncodable, got \(target.task)")
            return
        }
        #expect(body as? IssueCertificateRequestDTO == IssueCertificateRequestDTO(
            template: "UMC_COURSE_COMPLETION",
            gisuId: 7
        ))
    }

    @Test("발급 실패 응답은 서버 메시지를 담은 serverError 로 던진다")
    func issueFailure() async {
        let network = StubCertificateNetwork("""
        {
            "success": false, "code": "CERTIFICATE-0005",
            "message": "인증서 발급 조건을 만족하지 않아요.", "result": null
        }
        """)
        let repository = CertificateRepository(networkRequesting: network)

        await #expect(throws: RepositoryError.serverError(
            code: "CERTIFICATE-0005",
            message: "인증서 발급 조건을 만족하지 않아요."
        )) {
            try await repository.issueCertificate(
                template: Certificate.selfIssuableTemplate,
                gisuId: "7"
            )
        }
    }

    @Test("다운로드 정보 조회는 GET /api/v1/certificates/{id}/download 를 호출한다")
    func fetchDownloadInfo() async throws {
        let network = StubCertificateNetwork("""
        {
            "success": true, "code": "COMMON200", "message": "성공입니다.",
            "result": {
                "certificateId": 12,
                "serialNumber": "UMC-CMP-20260701-ABCDEFGH",
                "downloadUrl": "https://cdn.umc.it.kr/certificates/12.pdf",
                "expiresAt": "2027-07-01T00:00:00Z"
            }
        }
        """)
        let repository = CertificateRepository(networkRequesting: network)

        let download = try await repository.fetchDownloadInfo(certificateId: "12")

        #expect(download.serialNumber == "UMC-CMP-20260701-ABCDEFGH")
        let target = try #require(network.lastTarget)
        #expect(target.path == "/api/v1/certificates/12/download")
        #expect(target.method == .get)
    }
}
