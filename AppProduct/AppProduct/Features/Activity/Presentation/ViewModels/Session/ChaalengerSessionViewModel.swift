//
//  ChaalengerSessionViewModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/16/26.
//

import Foundation

@Observable
final class ChallengerSessionViewModel {
    private var container: DIContainer
    private var errorHandler: ErrorHandler
    private var sessionState: Loadable<[Session]> = .idle
    private var sessionRespository: SessionRepositoryProtocol
        
    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        sessionRepository: SessionRepositoryProtocol
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.sessionRespository = sessionRepository
    }
    
    func fetchSessionList() async {
        sessionState = .loading
        do {
            let sessions = try await sessionRespository.fetchSessionList()
            sessionState = .loaded(sessions)
        } catch {
            errorHandler.handle(error, context: .init(feature: "Activity", action: "fetchSessionList"))
        }
    }
    
}
