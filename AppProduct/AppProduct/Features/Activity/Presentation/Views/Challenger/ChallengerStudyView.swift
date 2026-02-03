//
//  ChallengerStudyView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/23/26.
//

import SwiftUI

/// Challenger 모드의 스터디/활동 섹션
///
/// 참여 중인 스터디와 활동 목록을 표시합니다.
struct ChallengerStudyView: View {

    // MARK: - Property

    @State private var viewModel: ChallengerStudyViewModel
    
    // MARK: - Init
    
    init(
        container: DIContainer,
        errorHandler: ErrorHandler
    ) {
        let useCaseProvider = container.resolve(UsecaseProviding.self)
        self._viewModel = .init(wrappedValue: .init(
            fetchCurriculumUseCase: useCaseProvider.activity.fetchCurriculumUseCase,
            submitMissionUseCase: useCaseProvider.activity.submitMissionUseCase,
            errorHandler: errorHandler
        ))
    }

    // MARK: - Body

    var body: some View {
        Group {
            contentView(viewModel: viewModel)
        }
        .task {
            await viewModel.fetchCurriculum()
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private func contentView(viewModel: ChallengerStudyViewModel) -> some View {
        switch viewModel.curriculumState {
        case .idle, .loading:
            loadingView

        case .loaded(let data):
            CurriculumView(
                curriculumModel: data.progress,
                missions: data.missions
            ) { mission, type, link in
                Task {
                    await viewModel.submitMission(mission, type: type, link: link)
                }
            }

        case .failed(let error):
            errorView(error: error, viewModel: viewModel)
        }
    }

    private var loadingView: some View {
        VStack(spacing: DefaultSpacing.spacing16) {
            ProgressView()

            Text("커리큘럼 불러오는 중...")
                .appFont(.subheadline, color: .grey500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(error: AppError, viewModel: ChallengerStudyViewModel) -> some View {
        ContentUnavailableView {
            Label("로딩 실패", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.errorDescription ?? "알 수 없는 오류가 발생했습니다.")
        } actions: {
            Button("다시 시도") {
                Task {
                    await viewModel.fetchCurriculum()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Preview

#Preview {
    ChallengerStudyView(
        container: MissionPreviewData.container,
        errorHandler: MissionPreviewData.errorHandler)
}
