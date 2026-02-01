//
//  MockStudyRepository.swift
//  AppProduct
//
//  Created by jaewon Lee on 02/01/26.
//

import Foundation

// MARK: - MockStudyRepository

/// Study Repository Mock 구현체
///
/// Preview 및 테스트용 Mock 데이터를 제공합니다.
final class MockStudyRepository: StudyRepositoryProtocol {

    // MARK: - Mock Data

    private var missions: [MissionCardModel] = [
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

    // MARK: - StudyRepositoryProtocol

    func fetchCurriculumProgress() async throws -> CurriculumProgressModel {
        // 네트워크 지연 시뮬레이션
        try await Task.sleep(for: .milliseconds(300))

        let completedCount = missions.filter { $0.status == .pass }.count
        return CurriculumProgressModel(
            partName: "iOS PART CURRICULUM",
            curriculumTitle: "Swift 기초 문법",
            completedCount: completedCount,
            totalCount: missions.count
        )
    }

    func fetchMissions() async throws -> [MissionCardModel] {
        // 네트워크 지연 시뮬레이션
        try await Task.sleep(for: .milliseconds(200))
        return missions
    }

    func submitMission(
        missionId: UUID,
        type: MissionSubmissionType,
        link: String?
    ) async throws -> MissionCardModel {
        // 네트워크 지연 시뮬레이션
        try await Task.sleep(for: .milliseconds(500))

        guard let index = missions.firstIndex(where: { $0.id == missionId }) else {
            throw DomainError.missionNotFound
        }

        // 상태를 pendingApproval로 변경
        missions[index].status = .pendingApproval
        return missions[index]
    }
}
