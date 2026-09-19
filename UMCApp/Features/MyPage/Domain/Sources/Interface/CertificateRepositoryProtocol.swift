//
//  CertificateRepositoryProtocol.swift
//  MyPageDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation

/// 수료증·인증서 발급·조회·다운로드 Repository (`/api/v1/certificates`).
public protocol CertificateRepositoryProtocol: Sendable {
    func fetchCertificates() async throws -> [Certificate]

    /// 서버는 같은 범위의 유효한 인증서가 이미 있으면 새로 만들지 않고 그것을 돌려준다.
    func issueCertificate(template: String, gisuId: String) async throws

    /// 인증서 PDF 를 받아 기기 임시 폴더에 저장하고 그 파일 URL 을 돌려준다.
    func downloadCertificate(certificateId: String) async throws -> URL
}
