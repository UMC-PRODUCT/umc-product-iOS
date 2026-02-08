//
//  StudyMemberPreviewData.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/8/26.
//

#if DEBUG
import Foundation

extension StudyMemberItem {
    /// 기본 멤버 정보 (주차 없이)
    private static let baseMembers: [(
        serverID: String, name: String, nickname: String,
        part: StudyPart, university: String,
        studyTopic: String, submissionURL: String?
    )] = [
        (
            "member_001", "정의찬", "제옹",
            .ios, "중앙대학교",
            "SwiftUI 심화",
            "https://github.com/jeong-ios/swiftui-deep-dive"
        ),
        (
            "member_002", "이재원", "리버",
            .ios, "한성대학교",
            "UIKit to SwiftUI 마이그레이션",
            "https://velog.io/@river/uikit-migration"
        ),
        (
            "member_003", "김연진", "코튼",
            .web, "상명대학교",
            "Next.js App Router",
            "https://github.com/cotton-web/nextjs-app-router"
        ),
        (
            "member_004", "박경운", "하늘",
            .spring, "중앙대학교",
            "Spring Boot JPA",
            nil
        ),
        (
            "member_005", "박유수", "어헛차",
            .android, "숭실대학교",
            "Jetpack Compose",
            "https://github.com/sky-android/compose-study"
        ),
        (
            "member_006", "이희원", "삼이",
            .design, "성신여자대학교",
            "디자인 시스템 구축",
            nil
        ),
        (
            "member_007", "김미주", "마티",
            .ios, "덕성여자대학교",
            "Combine & 비동기 처리",
            "https://velog.io/@mati/combine-async"
        ),
        (
            "member_008", "이예지", "소피",
            .ios, "가천대학교",
            "iOS 클린 아키텍처",
            "https://github.com/sophie-ios/clean-architecture"
        ),
        (
            "member_009", "양지애", "나루",
            .android, "서울여자대학교",
            "Kotlin Coroutines",
            nil
        ),
        (
            "member_010", "조경석", "조나단",
            .android, "명지대학교",
            "MVVM 아키텍처 패턴",
            "https://github.com/jonathan-android/mvvm-pattern"
        ),
        (
            "member_011", "김도연", "도리",
            .android, "서울여자대학교",
            "Hilt 의존성 주입",
            nil
        ),
        (
            "member_012", "박지현", "박박지현",
            .nodejs, "동국대학교",
            "REST API 설계",
            "https://github.com/park-nodejs/rest-api"
        ),
        (
            "member_013", "강하나", "와나",
            .spring, "한양대학교 ERICA",
            "Spring Security",
            nil
        ),
        (
            "member_014", "박세은", "세니",
            .nodejs, "동덕여자대학교",
            "Docker & CI/CD",
            "https://velog.io/@seni/docker-cicd"
        ),
        (
            "member_015", "이예은", "스읍",
            .spring, "중앙대학교",
            "MySQL 쿼리 최적화",
            nil
        ),
        (
            "member_016", "김민서", "갈래",
            .nodejs, "동국대학교",
            "Node.js Express",
            "https://github.com/kim-nodejs/express-study"
        )
    ]

    /// 주차별 mock 데이터 (약 75% 출석률 시뮬레이션)
    static let preview: [StudyMemberItem] = {
        var items: [StudyMemberItem] = []
        for (index, base) in baseMembers.enumerated() {
            let memberNumber = index + 1
            for week in 1...10 {
                guard week == 1
                    || (memberNumber + week) % 4 != 0
                else {
                    continue
                }
                items.append(
                    StudyMemberItem(
                        serverID: base.serverID,
                        name: base.name,
                        nickname: base.nickname,
                        part: base.part,
                        university: base.university,
                        studyTopic: base.studyTopic,
                        week: week,
                        submissionURL: base.submissionURL
                    )
                )
            }
        }
        return items
    }()
}
#endif
