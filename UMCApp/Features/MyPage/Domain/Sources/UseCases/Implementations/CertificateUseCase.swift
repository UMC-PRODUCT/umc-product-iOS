//
//  CertificateUseCase.swift
//  MyPageDomain
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDomain
import Foundation

public final class CertificateUseCase: CertificateUseCaseProtocol {

    // MARK: - Property

    private let repository: CertificateRepositoryProtocol
    private let memberProfileRepository: MemberProfileRepositoryProtocol

    // MARK: - Init

    public init(
        repository: CertificateRepositoryProtocol,
        memberProfileRepository: MemberProfileRepositoryProtocol
    ) {
        self.repository = repository
        self.memberProfileRepository = memberProfileRepository
    }

    // MARK: - Function

    public func fetchCertificates() async throws -> [Certificate] {
        try await repository.fetchCertificates()
    }

    public func fetchIssuableGisus() async throws -> [ProfileChallengerRecord] {
        let records = try await memberProfileRepository.fetchMyProfile().challengerRecords
        var seenGisuIds = Set<String>()
        return records
            .filter { seenGisuIds.insert($0.gisuId).inserted }
            .sorted { (Int($0.gisu) ?? 0) > (Int($1.gisu) ?? 0) }
    }

    public func issueCompletionCertificate(gisuId: String) async throws {
        try await repository.issueCertificate(
            template: Certificate.selfIssuableTemplate,
            gisuId: gisuId
        )
    }

    public func downloadCertificate(certificateId: String) async throws -> URL {
        try await repository.downloadCertificate(certificateId: certificateId)
    }
}
