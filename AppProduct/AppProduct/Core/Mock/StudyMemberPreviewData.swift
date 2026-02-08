//
//  StudyMemberPreviewData.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/8/26.
//

#if DEBUG
import Foundation

extension StudyMemberItem {
    static let preview: [StudyMemberItem] = [
        StudyMemberItem(
            id: UUID(),
            serverID: "member_001",
            name: "김철수",
            nickname: "iOS Developer",
            part: "iOS",
            university: "서울대학교",
            studyTopic: "SwiftUI 심화",
            profileImageURL: nil
        ),
        StudyMemberItem(
            id: UUID(),
            serverID: "member_002",
            name: "이영희",
            nickname: "Android Enthusiast",
            part: "Android",
            university: "연세대학교",
            studyTopic: "Compose UI 패턴",
            profileImageURL: nil
        ),
        StudyMemberItem(
            id: UUID(),
            serverID: "member_003",
            name: "박민준",
            nickname: "Backend Engineer",
            part: "Spring Boot",
            university: "고려대학교",
            studyTopic: "MSA 아키텍처",
            profileImageURL: nil
        ),
        StudyMemberItem(
            id: UUID(),
            serverID: "member_004",
            name: "최지은",
            nickname: "Frontend Dev",
            part: "Web",
            university: "이화여대",
            studyTopic: "React 성능 최적화",
            profileImageURL: nil
        ),
        StudyMemberItem(
            id: UUID(),
            serverID: "member_005",
            name: "정우성",
            nickname: "Node.js Developer",
            part: "Node.js",
            university: "성균관대학교",
            studyTopic: "Express vs Nest.js",
            profileImageURL: nil
        ),
        StudyMemberItem(
            id: UUID(),
            serverID: "member_006",
            name: "강민서",
            nickname: "Product Manager",
            part: "PM",
            university: "한양대학교",
            studyTopic: "애자일 방법론",
            profileImageURL: nil
        ),
        StudyMemberItem(
            id: UUID(),
            serverID: "member_007",
            name: "윤하늘",
            nickname: "UI/UX Designer",
            part: "Design",
            university: "홍익대학교",
            studyTopic: "디자인 시스템 구축",
            profileImageURL: nil
        )
    ]
}
#endif
