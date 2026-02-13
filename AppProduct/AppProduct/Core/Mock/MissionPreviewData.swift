//
//  MissionPreviewData.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/29/26.
//

import Foundation
import SwiftUI
import SwiftData

#if DEBUG
struct MissionPreviewData {
    
    static let errorHandler = ErrorHandler()
    static let container: DIContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try! ModelContainer(
            for: PenaltyRecord.self, NoticeHistoryData.self,
            configurations: config
        )
        return DIContainer.configured(
            modelContext: modelContainer.mainContext
        )
    }()

    // MARK: - Single Mission

    static let singleMission = MissionCardModel(
        week: 7,
        platform: "iOS",
        title: "Moya로 깔끔하게 통신하기 - API 연동 실전 2",
        missionTitle: "Moya를 활용한 네트워크 레이어 구현 예제를 제출하세요",
        status: .inProgress
    )

    // MARK: - Platform-specific Missions

    /// iOS 파트 실제 커리큘럼 (7기 기준)
    static let iosMissions: [MissionCardModel] = [
        .init(
            week: 0,
            platform: "iOS",
            title: "SwiftUI 기본 개념",
            missionTitle: "SwiftUI 기본 개념을 학습하고 정리한 글 링크를 제출하세요",
            status: .pass
        ),
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
            status: .pass
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
            status: .inProgress
        ),
        .init(
            week: 8,
            platform: "iOS",
            title: "좋은 컴포넌트 설계란 무엇일까",
            missionTitle: "함수형 프로그래밍을 적용한 컴포넌트 설계 예제를 제출하세요",
            status: .locked
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

    static let androidMissions: [MissionCardModel] = [
        .init(
            week: 1,
            platform: "Android",
            title: "Kotlin 기초 문법",
            missionTitle: "Kotlin 기본 문법을 학습하고 정리한 글 링크를 제출하세요",
            status: .pass
        ),
        .init(
            week: 2,
            platform: "Android",
            title: "Jetpack Compose",
            missionTitle: "Compose를 활용한 UI 예제를 제출하세요",
            status: .inProgress
        ),
        .init(
            week: 3,
            platform: "Android",
            title: "ViewModel 패턴",
            missionTitle: "ViewModel을 적용한 화면을 구현하세요",
            status: .notStarted
        )
    ]

    static let webMissions: [MissionCardModel] = [
        .init(
            week: 1,
            platform: "Web",
            title: "React 기초",
            missionTitle: "React 컴포넌트를 활용한 예제를 제출하세요",
            status: .pass
        ),
        .init(
            week: 2,
            platform: "Web",
            title: "상태 관리",
            missionTitle: "Redux 또는 Zustand를 활용한 상태 관리 예제를 제출하세요",
            status: .inProgress
        )
    ]

    static let serverMissions: [MissionCardModel] = [
        .init(
            week: 1,
            platform: "Server",
            title: "Spring Boot 기초",
            missionTitle: "Spring Boot로 간단한 REST API를 구현하세요",
            status: .pass
        ),
        .init(
            week: 2,
            platform: "Server",
            title: "JPA 활용",
            missionTitle: "JPA를 활용한 CRUD API를 구현하세요",
            status: .notStarted
        )
    ]

    // MARK: - Status-specific Missions

    /// 모든 상태를 포함하는 미션 목록 (테스트용)
    static let allStatusMissions: [MissionCardModel] = [
        .init(
            week: 0,
            platform: "iOS",
            title: "SwiftUI 기본 개념",
            missionTitle: "SwiftUI 기본 개념을 학습하고 정리한 글 링크를 제출하세요",
            status: .pass
        ),
        .init(
            week: 1,
            platform: "iOS",
            title: "SwiftUI 화면 구성 및 상태 관리",
            missionTitle: "@State, @Binding을 활용한 화면 구성 예제를 제출하세요",
            status: .fail
        ),
        .init(
            week: 2,
            platform: "iOS",
            title: "SwiftUI 데이터 바인딩 및 MVVM 패턴",
            missionTitle: "MVVM 패턴을 적용한 간단한 앱을 구현하세요",
            status: .pendingApproval
        ),
        .init(
            week: 3,
            platform: "iOS",
            title: "SwiftUI 리스트와 스크롤뷰, 그리고 네비게이션까지!",
            missionTitle: "List와 NavigationStack을 활용한 화면을 구현하세요",
            status: .inProgress
        ),
        .init(
            week: 4,
            platform: "iOS",
            title: "순간 반응하는 앱 만들기 – Swift 비동기와 Combine",
            missionTitle: "async/await와 Combine을 활용한 비동기 처리 예제를 제출하세요",
            status: .notStarted
        ),
        .init(
            week: 5,
            platform: "iOS",
            title: "API 없이도 앱이 동작하게 – 모델 설계와 JSON 파싱",
            missionTitle: "Codable을 활용한 JSON 파싱 예제를 제출하세요",
            status: .locked
        )
    ]

    // MARK: - CurriculumView용 데이터

    /// 웹 파트 커리큘럼 상세 (이미지 25번 기준)
    static let webCurriculumMissions: [MissionCardModel] = [
        .init(
            week: 1,
            platform: "Web",
            title: "HTML/CSS 기초",
            missionTitle: "HTML과 CSS를 활용한 정적 페이지를 제출하세요",
            status: .pass
        ),
        .init(
            week: 2,
            platform: "Web",
            title: "HTML/CSS 기초",
            missionTitle: "반응형 레이아웃 예제를 제출하세요",
            status: .fail
        ),
        .init(
            week: 3,
            platform: "Web",
            title: "HTML/CSS 기초",
            missionTitle: "컴포넌트 생명주기와 Hooks의 이해",
            status: .inProgress
        ),
        .init(
            week: 4,
            platform: "Web",
            title: "HTML/CSS 기초",
            missionTitle: "상태 관리 라이브러리 활용",
            status: .locked
        ),
        .init(
            week: 5,
            platform: "Web",
            title: "HTML/CSS 기초",
            missionTitle: "API 연동 및 비동기 처리",
            status: .locked
        )
    ]

    // MARK: - Combined Missions

    /// 전체 미션 목록
    static let allMissions: [MissionCardModel] = {
        var missions: [MissionCardModel] = []
        missions.append(contentsOf: iosMissions)
        missions.append(contentsOf: androidMissions)
        missions.append(contentsOf: webMissions)
        missions.append(contentsOf: serverMissions)
        return missions
    }()

    /// 주차별 정렬된 미션 목록
    static var missionsByWeek: [MissionCardModel] {
        allMissions.sorted { $0.week < $1.week }
    }

    /// 플랫폼별 그룹화된 미션
    static var missionsByPlatform: [String: [MissionCardModel]] {
        Dictionary(grouping: allMissions, by: { $0.platform })
    }
}

// MARK: - Preview Helpers

extension MissionPreviewData {

    /// 미션 상태 프리뷰
    static func missionStatusPreview() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("미션 상태별 테스트")
                    .appFont(.title2Emphasis, color: .grey900)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(MissionStatus.allCases, id: \.self) { status in
                    HStack {
                        Text(status.displayText)
                            .appFont(.body, color: status.foregroundColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(status.backgroundColor, in: Capsule())

                        Spacer()

                        Text(status.rawValue)
                            .appFont(.caption1, color: .grey600)
                    }
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color.grey100)
    }
}
#endif
