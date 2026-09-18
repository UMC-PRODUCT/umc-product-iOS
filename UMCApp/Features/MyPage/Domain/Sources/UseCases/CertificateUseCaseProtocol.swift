//
//  CertificateUseCaseProtocol.swift
//  MyPageDomain
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDomain
import Foundation

/// 마이페이지 「수료증 ・인증서」 화면 UseCase.
public protocol CertificateUseCaseProtocol: Sendable {
    func fetchCertificates() async throws -> [Certificate]

    /// 수료증 발급 대상 기수 — 내 챌린저 기록의 기수(최신순, 기수당 1건).
    ///
    /// 수료(`GRADUATED`) 여부는 클라이언트가 알 수 없어 서버가 발급 시점에 검증한다.
    func fetchIssuableGisus() async throws -> [ProfileChallengerRecord]

    func issueCompletionCertificate(gisuId: String) async throws

    func downloadCertificate(certificateId: String) async throws -> URL
}
