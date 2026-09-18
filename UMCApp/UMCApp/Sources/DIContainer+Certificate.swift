//
//  DIContainer+Certificate.swift
//  UMCApp
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDI
import CoreDomain
import CoreNetwork
import MyPageData
import MyPageDomain

extension DIContainer {
    func registerCertificateDependencies() {
        register(CertificateRepositoryProtocol.self) {
            CertificateRepository(adapter: self.resolve(MoyaNetworkAdapter.self))
        }
        register(CertificateUseCaseProtocol.self) {
            CertificateUseCase(
                repository: self.resolve(CertificateRepositoryProtocol.self),
                memberProfileRepository: self.resolve(MemberProfileRepositoryProtocol.self)
            )
        }
    }
}
