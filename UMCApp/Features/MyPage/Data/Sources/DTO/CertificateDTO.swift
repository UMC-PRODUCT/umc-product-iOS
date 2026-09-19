//
//  CertificateDTO.swift
//  MyPageData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import MyPageDomain
import UMCFoundation

// MARK: - Request

/// `POST /api/v1/certificates` 요청 바디.
public struct IssueCertificateRequestDTO: Encodable, Equatable {
    public let template: String
    public let gisuId: Int

    public init(template: String, gisuId: Int) {
        self.template = template
        self.gisuId = gisuId
    }
}

// MARK: - Response

/// `GET /api/v1/certificates` 목록 원소 (서버 `CertificateResponse`).
public struct CertificateResponseDTO: Codable {
    let certificateId: String
    let serialNumber: String
    let template: String
    let status: String
    let recipientName: String
    let gisuId: String
    let gisuGeneration: String
    let meritTitle: String?
    let issuedAt: String?
    let expiresAt: String?

    private enum CodingKeys: String, CodingKey {
        case certificateId
        case serialNumber
        case template
        case status
        case recipientName
        case gisuId
        case gisuGeneration
        case meritTitle
        case issuedAt
        case expiresAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        certificateId = try container.decodeFlexibleString(forKey: .certificateId)
        serialNumber = try container.decode(String.self, forKey: .serialNumber)
        template = try container.decode(String.self, forKey: .template)
        status = try container.decode(String.self, forKey: .status)
        recipientName = try container.decodeIfPresent(String.self, forKey: .recipientName) ?? ""
        gisuId = container.decodeFlexibleStringOrEmpty(forKey: .gisuId)
        gisuGeneration = container.decodeFlexibleStringOrEmpty(forKey: .gisuGeneration)
        meritTitle = try container.decodeIfPresent(String.self, forKey: .meritTitle)
        issuedAt = try container.decodeIfPresent(String.self, forKey: .issuedAt)
        expiresAt = try container.decodeIfPresent(String.self, forKey: .expiresAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(certificateId, forKey: .certificateId)
        try container.encode(serialNumber, forKey: .serialNumber)
        try container.encode(template, forKey: .template)
        try container.encode(status, forKey: .status)
        try container.encode(recipientName, forKey: .recipientName)
        try container.encode(gisuId, forKey: .gisuId)
        try container.encode(gisuGeneration, forKey: .gisuGeneration)
        try container.encodeIfPresent(meritTitle, forKey: .meritTitle)
        try container.encodeIfPresent(issuedAt, forKey: .issuedAt)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
    }

    public func toDomain() -> Certificate {
        Certificate(
            id: certificateId,
            serialNumber: serialNumber,
            template: template,
            // 모르는 상태값은 다운로드를 막는 쪽으로 둔다 — 서버는 유효한 인증서만 내려준다.
            status: CertificateStatus(rawValue: status) ?? .expired,
            recipientName: recipientName,
            gisuId: gisuId,
            gisuGeneration: gisuGeneration,
            meritTitle: meritTitle,
            issuedAt: issuedAt.flatMap(ServerDateTimeConverter.parseUTCDateTime),
            expiresAt: expiresAt.flatMap(ServerDateTimeConverter.parseUTCDateTime)
        )
    }
}

/// `GET /api/v1/certificates/{certificateId}/download` 응답.
///
/// `downloadUrl` 은 60분짜리 CDN 서명 URL 이다. `expiresAt` 은 URL 이 아니라 인증서의 만료
/// 시각이라 쓰지 않는다.
public struct CertificateDownloadResponseDTO: Codable {
    let certificateId: String
    let serialNumber: String
    let downloadUrl: String

    private enum CodingKeys: String, CodingKey {
        case certificateId
        case serialNumber
        case downloadUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        certificateId = try container.decodeFlexibleString(forKey: .certificateId)
        serialNumber = try container.decode(String.self, forKey: .serialNumber)
        downloadUrl = try container.decode(String.self, forKey: .downloadUrl)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(certificateId, forKey: .certificateId)
        try container.encode(serialNumber, forKey: .serialNumber)
        try container.encode(downloadUrl, forKey: .downloadUrl)
    }
}
