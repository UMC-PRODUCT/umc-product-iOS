//
//  ChallengerStudyViewModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 02/01/26.
//

import Foundation
import SwiftUI

// MARK: - CurriculumData

/// 커리큘럼 화면에 필요한 데이터 모델
struct CurriculumData: Equatable {
    var progress: CurriculumProgressModel
    var missions: [MissionCardModel]
}

// MARK: - ChallengerStudyViewModel

/// Challenger 모드의 스터디/활동 섹션 ViewModel
///
/// UseCase를 통해 커리큘럼 데이터를 조회하고 미션을 제출합니다.
@Observable
final class ChallengerStudyViewModel {

    // MARK: - Dependency

    private let fetchCurriculumUseCase: FetchCurriculumUseCaseProtocol
    private let submitMissionUseCase: SubmitMissionUseCaseProtocol
    private let errorHandler: ErrorHandler

    // MARK: - State

    private(set) var curriculumState: Loadable<CurriculumData> = .idle

    // MARK: - Init

    init(
        fetchCurriculumUseCase: FetchCurriculumUseCaseProtocol,
        submitMissionUseCase: SubmitMissionUseCaseProtocol,
        errorHandler: ErrorHandler
    ) {
        self.fetchCurriculumUseCase = fetchCurriculumUseCase
        self.submitMissionUseCase = submitMissionUseCase
        self.errorHandler = errorHandler
    }

    // MARK: - Action

    /// 커리큘럼 데이터 로드
    @MainActor
    func fetchCurriculum() async {
        curriculumState = .loading

        do {
            let data = try await fetchCurriculumUseCase.execute()
            curriculumState = .loaded(data)
        } catch let error as DomainError {
            curriculumState = .failed(.domain(error))
        } catch {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Study",
                    action: "fetchCurriculum"
                )
            )
            curriculumState = .idle
        }
    }

    /// 미션 제출 처리
    /// - Parameters:
    ///   - mission: 제출할 미션
    ///   - type: 제출 타입 (링크 또는 완료만)
    ///   - link: 링크 URL (링크 타입일 경우)
    @MainActor
    func submitMission(
        _ mission: MissionCardModel,
        type: MissionSubmissionType,
        link: String?
    ) async {
        do {
            guard let challengerWorkbookId = mission.challengerWorkbookId else {
                throw DomainError.missionNotFound
            }

            try await submitMissionUseCase.execute(
                missionId: challengerWorkbookId,
                type: type,
                link: link
            )

            // 로컬 상태 업데이트
            if case .loaded(var data) = curriculumState {
                if let index = data.missions.firstIndex(where: { $0.id == mission.id }) {
                    data.missions[index].status = .pendingApproval
                    withAnimation(.easeInOut(duration: DefaultConstant.animationTime)) {
                        curriculumState = .loaded(data)
                    }
                }
            }
        } catch let error as DomainError {
            curriculumState = .failed(.domain(error))
        } catch {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Study",
                    action: "submitMission"
                )
            )
        }
    }
}
