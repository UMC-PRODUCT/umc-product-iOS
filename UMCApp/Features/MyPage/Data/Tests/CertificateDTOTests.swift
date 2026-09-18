//
//  CertificateDTOTests.swift
//  MyPageDataTests
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import Testing
import CoreNetwork
import UMCFoundation
@testable import MyPageData
@testable import MyPageDomain

/// 서버 `CertificateController` 실제 응답 형태 — Jackson `WRITE_NUMBERS_AS_STRINGS` 라 Long 이
/// 문자열로, `Instant` 는 ISO-8601 로 온다.
@Suite("CertificateDTO")
struct CertificateDTOTests {

    static let listJSON = """
    {
        "success": true,
        "code": "COMMON200",
        "message": "성공입니다.",
        "result": [
            {
                "certificateId": "12",
                "serialNumber": "UMC-CMP-20260701-ABCDEFGH",
                "template": "UMC_COURSE_COMPLETION",
                "issuer": "UNIVERSITY_MAKEUS_CHALLENGE",
                "status": "ISSUED",
                "recipientName": "홍길동",
                "gisuId": "7",
                "gisuGeneration": "9",
                "meritTitle": null,
                "issuedAt": "2026-07-01T00:00:00Z",
                "expiresAt": "2027-07-01T00:00:00Z"
            },
            {
                "certificateId": 13,
                "serialNumber": "UMC-MRT-20260801-HGFEDCBA",
                "template": "UMC_HACKATHON_GRAND_PRIZE",
                "issuer": "UNIVERSITY_MAKEUS_CHALLENGE",
                "status": "REVOKED",
                "recipientName": "홍길동",
                "gisuId": 7,
                "gisuGeneration": 9,
                "meritTitle": "대상",
                "issuedAt": "2026-08-01T09:30:00.123Z",
                "expiresAt": "2027-08-01T09:30:00.123Z"
            }
        ]
    }
    """

    @Test("목록 응답의 문자열·숫자 정수를 모두 String 으로 디코딩한다")
    func decodesList() throws {
        let response = try JSONDecoder().decode(
            APIResponse<[CertificateResponseDTO]>.self,
            from: Data(Self.listJSON.utf8)
        )
        let certificates = try response.unwrap().map { $0.toDomain() }

        #expect(certificates.count == 2)
        let completion = certificates[0]
        #expect(completion.id == "12")
        #expect(completion.serialNumber == "UMC-CMP-20260701-ABCDEFGH")
        #expect(completion.status == .issued)
        #expect(completion.gisuId == "7")
        #expect(completion.gisuGeneration == "9")
        #expect(completion.meritTitle == nil)
        #expect(completion.title == "수료증")
        #expect(completion.isDownloadable)
        #expect(completion.issuedAt == ServerDateTimeConverter.parseUTCDateTime(
            "2026-07-01T00:00:00Z"
        ))

        let prize = certificates[1]
        #expect(prize.id == "13")
        #expect(prize.gisuId == "7")
        #expect(prize.status == .revoked)
        #expect(prize.title == "해커톤 대상")
        #expect(!prize.isDownloadable)
        #expect(prize.issuedAt != nil)
    }

    @Test("모르는 상태값은 다운로드할 수 없는 상태로 매핑한다")
    func unknownStatusIsNotDownloadable() throws {
        let json = """
        {
            "certificateId": "1", "serialNumber": "S", "template": "UMC_COURSE_COMPLETION",
            "status": "SUSPENDED", "gisuId": "1", "gisuGeneration": "1"
        }
        """
        let certificate = try JSONDecoder()
            .decode(CertificateResponseDTO.self, from: Data(json.utf8))
            .toDomain()

        #expect(!certificate.isDownloadable)
        #expect(certificate.recipientName == "")
        #expect(certificate.issuedAt == nil)
    }

    @Test("필수 필드(serialNumber) 누락 시 throw 한다")
    func throwsOnMissingSerialNumber() {
        let json = """
        { "certificateId": "1", "template": "UMC_COURSE_COMPLETION", "status": "ISSUED" }
        """
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(CertificateResponseDTO.self, from: Data(json.utf8))
        }
    }

    @Test("다운로드 응답을 디코딩한다")
    func decodesDownload() throws {
        let json = """
        {
            "success": true,
            "code": "COMMON200",
            "message": "성공입니다.",
            "result": {
                "certificateId": "12",
                "serialNumber": "UMC-CMP-20260701-ABCDEFGH",
                "downloadUrl": "https://cdn.umc.it.kr/certificates/12.pdf?Signature=abc",
                "expiresAt": "2027-07-01T00:00:00Z"
            }
        }
        """
        let dto = try JSONDecoder()
            .decode(APIResponse<CertificateDownloadResponseDTO>.self, from: Data(json.utf8))
            .unwrap()

        #expect(dto.certificateId == "12")
        #expect(dto.serialNumber == "UMC-CMP-20260701-ABCDEFGH")
        #expect(dto.downloadUrl == "https://cdn.umc.it.kr/certificates/12.pdf?Signature=abc")
    }
}
