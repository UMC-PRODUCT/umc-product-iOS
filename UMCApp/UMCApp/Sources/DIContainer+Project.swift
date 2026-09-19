//
//  DIContainer+Project.swift
//  UMCApp
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDI
import CoreNetwork
import ProjectData
import ProjectDomain
import ProjectPresentation

// Project(프로젝트 매칭) 의존성 등록 — Repository 3종 + UseCase Provider.
extension DIContainer {
    func registerProjectDependencies() {
        register(ProjectRepositoryProtocol.self) {
            ProjectRepository(adapter: self.resolve(MoyaNetworkAdapter.self))
        }
        register(ProjectApplicationRepositoryProtocol.self) {
            ProjectApplicationRepository(adapter: self.resolve(MoyaNetworkAdapter.self))
        }
        register(ProjectMatchingRoundRepositoryProtocol.self) {
            ProjectMatchingRoundRepository(adapter: self.resolve(MoyaNetworkAdapter.self))
        }

        // ViewModel이 resolve하는 단일 진입점 (MyPage 패턴).
        register(ProjectUseCaseProviding.self) {
            ProjectUseCaseProvider(
                projectRepository: self.resolve(ProjectRepositoryProtocol.self),
                applicationRepository: self.resolve(ProjectApplicationRepositoryProtocol.self),
                matchingRoundRepository: self.resolve(ProjectMatchingRoundRepositoryProtocol.self)
            )
        }
    }
}
