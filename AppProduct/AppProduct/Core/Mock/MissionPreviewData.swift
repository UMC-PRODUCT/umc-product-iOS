//
//  MissionPreviewData.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/29/26.
//

import Foundation
import SwiftUI

#if DEBUG
struct MissionPreviewData {

    // MARK: - Single Mission

    static let singleMission = MissionCardModel(
        week: 1,
        platform: "iOS",
        title: "SwiftUI 기초 학습",
        missionTitle: "SwiftUI를 이용해 로그인 화면을 구현하세요",
        status: .inProgress
    )

    // MARK: - Platform-specific Missions

    static let iosMissions: [MissionCardModel] = [
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
            status: .notStarted
        ),
        .init(
            week: 5,
            platform: "iOS",
            title: "Combine 입문",
            missionTitle: "Combine을 활용한 데이터 바인딩 예제를 제출하세요",
            status: .notStarted
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
            status: .fail
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
