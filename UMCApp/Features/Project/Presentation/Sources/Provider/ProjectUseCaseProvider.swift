//
//  ProjectUseCaseProvider.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import ProjectDomain

/// Project Presentation 레이어의 UseCase Bundle Protocol.
/// ViewModel이 개별 UseCase 대신 Provider 한 개로 묶어 받는다 (MyPage 패턴).
public protocol ProjectUseCaseProviding {
    /// 프로젝트 조회·관리·권한·통계.
    var projectUseCase: ProjectUseCaseProtocol { get }
    /// 지원 폼·지원서·심사.
    var applicationUseCase: ProjectApplicationUseCaseProtocol { get }
    /// 매칭 차수 (운영진).
    var matchingRoundUseCase: ProjectMatchingRoundUseCaseProtocol { get }
}

public final class ProjectUseCaseProvider: ProjectUseCaseProviding {

    // MARK: - Property

    public let projectUseCase: ProjectUseCaseProtocol
    public let applicationUseCase: ProjectApplicationUseCaseProtocol
    public let matchingRoundUseCase: ProjectMatchingRoundUseCaseProtocol

    // MARK: - Init

    public init(
        projectRepository: ProjectRepositoryProtocol,
        applicationRepository: ProjectApplicationRepositoryProtocol,
        matchingRoundRepository: ProjectMatchingRoundRepositoryProtocol
    ) {
        self.projectUseCase = ProjectUseCase(repository: projectRepository)
        self.applicationUseCase = ProjectApplicationUseCase(repository: applicationRepository)
        self.matchingRoundUseCase = ProjectMatchingRoundUseCase(
            repository: matchingRoundRepository
        )
    }
}
