//
//  ChallengerStudyViewModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 02/01/26.
//

import Foundation

// MARK: - CurriculumData

/// 커리큘럼 화면에 필요한 데이터 모델
struct CurriculumData: Equatable {
    let progress: CurriculumProgressModel
    let missions: [MissionCardModel]
}

// MARK: - ChallengerStudyViewModel

/// Challenger 모드의 스터디/활동 섹션 ViewModel
///
/// - Note: 현재 Mock 데이터 사용. UseCase/Repository 연동 시 리팩토링 필요.
@Observable
final class ChallengerStudyViewModel {

    // MARK: - State

    private(set) var curriculumState: Loadable<CurriculumData> = .idle

    // MARK: - Action

    /// 커리큘럼 데이터 로드
    @MainActor
    func fetchCurriculum() async {
        curriculumState = .loading

        // Mock: 네트워크 지연 시뮬레이션
        try? await Task.sleep(for: .milliseconds(500))

        // Mock 데이터 로드
        let data = CurriculumData(
            progress: CurriculumProgressModel(
                partName: "iOS PART CURRICULUM",
                curriculumTitle: "Swift 기초 문법",
                completedCount: 2,
                totalCount: 5
            ),
            missions: Self.mockMissions
        )

        curriculumState = .loaded(data)
    }

    /// 미션 제출 처리
    func submitMission(
        _ mission: MissionCardModel,
        type: MissionSubmissionType,
        link: String?
    ) {
        // TODO: UseCase 연동 시 구현
        print("제출: \(mission.title) - \(type) - \(link ?? "없음")")
    }

    // MARK: - Mock Data

    private static let mockMissions: [MissionCardModel] = [
        .init(
            week: 1,
            platform: "iOS",
            title: "Swift 기초 문법",
            missionTitle: "Swift 기본 문법을 학습하고 정리한 글 링크를 제출하세요",
            status: .pass
        ),
        .init(
            week: 2,
            platform: "iOS",
            title: "SwiftUI 레이아웃",
            missionTitle: "VStack, HStack, ZStack을 활용한 레이아웃 예제를 제출하세요",
            status: .pass
        ),
        .init(
            week: 3,
            platform: "iOS",
            title: "MVVM 아키텍처",
            missionTitle: "MVVM 패턴을 적용한 간단한 앱을 구현하세요",
            status: .inProgress
        ),
        .init(
            week: 4,
            platform: "iOS",
            title: "네트워킹 기초",
            missionTitle: "URLSession을 활용한 API 호출 예제를 제출하세요",
            status: .locked
        ),
        .init(
            week: 5,
            platform: "iOS",
            title: "Combine 입문",
            missionTitle: "Combine을 활용한 데이터 바인딩 예제를 제출하세요",
            status: .locked
        )
    ]
}
