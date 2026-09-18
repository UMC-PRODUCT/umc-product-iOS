//
//  Certificate.swift
//  MyPageDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation

/// 내가 받은 수료증·인증서 한 건 (`GET /api/v1/certificates`).
public struct Certificate: Identifiable, Equatable, Hashable, Sendable {

    // MARK: - Property

    /// 챌린저가 직접 발급할 수 있는 유일한 템플릿. 나머지(공로증·데모데이·해커톤 상장)는
    /// 운영진만 발급한다.
    public static let selfIssuableTemplate = "UMC_COURSE_COMPLETION"

    public let id: String
    public let serialNumber: String
    /// 서버 `CertificateTemplate` 원문 (예: `UMC_COURSE_COMPLETION`)
    public let template: String
    public let status: CertificateStatus
    public let recipientName: String
    public let gisuId: String
    public let gisuGeneration: String
    /// 상장 계열의 수상명 (예: "대상"). 수료증은 `nil`이다.
    public let meritTitle: String?
    public let issuedAt: Date?
    public let expiresAt: Date?

    // MARK: - Init

    public init(
        id: String,
        serialNumber: String,
        template: String,
        status: CertificateStatus,
        recipientName: String,
        gisuId: String,
        gisuGeneration: String,
        meritTitle: String?,
        issuedAt: Date?,
        expiresAt: Date?
    ) {
        self.id = id
        self.serialNumber = serialNumber
        self.template = template
        self.status = status
        self.recipientName = recipientName
        self.gisuId = gisuId
        self.gisuGeneration = gisuGeneration
        self.meritTitle = meritTitle
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
    }

    // MARK: - Computed Property

    /// 서버 PDF 타이틀과 같은 규칙 — 해커톤·데모데이 상장은 행사명을 앞에 붙인다.
    public var title: String {
        let name = meritTitle ?? "수료증"
        if template.contains("HACKATHON") { return "해커톤 \(name)" }
        if template.contains("DEMO_DAY") { return "데모데이 \(name)" }
        return name
    }

    /// 서버는 유효(`ISSUED`)한 인증서만 다운로드를 허용한다.
    public var isDownloadable: Bool {
        status == .issued
    }
}

/// 서버가 조회 시점 기준으로 계산해 내려주는 인증서 상태.
public enum CertificateStatus: String, Sendable {
    case issued = "ISSUED"
    case revoked = "REVOKED"
    case expired = "EXPIRED"
}
