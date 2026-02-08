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

    /// iOS 파트 실제 커리큘럼 (7기 기준)
    private var missions: [MissionCardModel] = [
        .init(
            week: 1,
            platform: "iOS",
            title: "SwiftUI 화면 구성 및 상태 관리",
            missionTitle: "@State, @Binding을 활용한 화면 구성 예제를 제출하세요",
            status: .pass
        ),
        .init(
            week: 2,
            platform: "iOS",
            title: "SwiftUI 데이터 바인딩 및 MVVM 패턴",
            missionTitle: "MVVM 패턴을 적용한 간단한 앱을 구현하세요",
            status: .pass
        ),
        .init(
            week: 3,
            platform: "iOS",
            title: "SwiftUI 리스트와 스크롤뷰, 그리고 네비게이션까지!",
            missionTitle: "List와 NavigationStack을 활용한 화면을 구현하세요",
            status: .pass
        ),
        .init(
            week: 4,
            platform: "iOS",
            title: "순간 반응하는 앱 만들기 – Swift 비동기와 Combine",
            missionTitle: "async/await와 Combine을 활용한 비동기 처리 예제를 제출하세요",
            status: .fail
        ),
        .init(
            week: 5,
            platform: "iOS",
            title: "API 없이도 앱이 동작하게 – 모델 설계와 JSON 파싱",
            missionTitle: "Codable을 활용한 JSON 파싱 예제를 제출하세요",
            status: .pass
        ),
        .init(
            week: 6,
            platform: "iOS",
            title: "진짜 서버랑 대화하기 – Alamofire API 연동 1",
            missionTitle: "Alamofire를 활용한 API 호출 예제를 제출하세요",
            status: .pass
        ),
        .init(
            week: 7,
            platform: "iOS",
            title: "Moya로 깔끔하게 통신하기 - API 연동 실전 2",
            missionTitle: "Moya를 활용한 네트워크 레이어 구현 예제를 제출하세요",
            status: .pass
        ),
        .init(
            week: 8,
            platform: "iOS",
            title: "좋은 컴포넌트 설계란 무엇일까",
            missionTitle: "함수형 프로그래밍을 적용한 컴포넌트 설계 예제를 제출하세요",
            status: .inProgress
        ),
        .init(
            week: 9,
            platform: "iOS",
            title: "UIKit을 SwiftUI에 녹이는 방법 – UIViewControllerRepresentable",
            missionTitle: "UIViewControllerRepresentable을 활용한 UIKit 연동 예제를 제출하세요",
            status: .locked
        ),
        .init(
            week: 10,
            platform: "iOS",
            title: "혼자 말고 함께 – iOS 개발 협업 가이드라인",
            missionTitle: "협업 도구와 Git Flow를 활용한 프로젝트 관리 방법을 정리하세요",
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
            curriculumTitle: "좋은 컴포넌트 설계란 무엇일까",
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

    // MARK: - 운영진 스터디 관리

    func fetchStudyMembers() async throws -> [StudyMemberItem] {
        try await Task.sleep(for: .milliseconds(500))
        return StudyMemberItem.preview
    }

    func fetchStudyGroups() async throws -> [StudyGroupItem] {
        try await Task.sleep(for: .milliseconds(300))
        return StudyGroupItem.preview
    }

    func fetchWeeks() async throws -> [Int] {
        try await Task.sleep(for: .milliseconds(200))
        return Array(1...10)
    }
}
