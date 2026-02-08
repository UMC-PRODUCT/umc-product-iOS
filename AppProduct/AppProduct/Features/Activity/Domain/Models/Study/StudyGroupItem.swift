//
//  StudyGroupItem.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/8/26.
//

import Foundation

struct StudyGroupItem: Identifiable, Equatable, Hashable {
    // MARK: - Property

    let id: UUID
    let serverID: String
    let name: String
    let iconName: String

    // MARK: - Static Property

    static let all = StudyGroupItem(
        id: UUID(),
        serverID: "",
        name: "전체 스터디 그룹",
        iconName: "person.2.fill"
    )

    #if DEBUG
    static let preview: [StudyGroupItem] = [
        .all,
        StudyGroupItem(
            id: UUID(),
            serverID: "group_001",
            name: "iOS 스터디",
            iconName: "apple.logo"
        ),
        StudyGroupItem(
            id: UUID(),
            serverID: "group_002",
            name: "Android 스터디",
            iconName: "inset.filled.applewatch.case"
        ),
        StudyGroupItem(
            id: UUID(),
            serverID: "group_003",
            name: "Web 스터디",
            iconName: "globe"
        ),
        StudyGroupItem(
            id: UUID(),
            serverID: "group_004",
            name: "Spring 스터디",
            iconName: "leaf.fill"
        ),
        StudyGroupItem(
            id: UUID(),
            serverID: "group_005",
            name: "Node.js 스터디",
            iconName: "hexagon.fill"
        ),
        StudyGroupItem(
            id: UUID(),
            serverID: "group_006",
            name: "Design 스터디",
            iconName: "paintpalette.fill"
        ),
        StudyGroupItem(
            id: UUID(),
            serverID: "group_007",
            name: "PM 스터디",
            iconName: "doc.text.fill"
        )
    ]
    #endif
}
