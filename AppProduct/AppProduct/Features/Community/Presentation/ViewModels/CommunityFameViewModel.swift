//
//  CommunityFameViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/23/26.
//

import Foundation

@Observable
class CommunityFameViewModel {
    // MARK: - Property

    var selectedWeek: Int = 1

    var fameItems: Loadable<[CommunityFameItemModel]> = .loaded(mockFameItems)

    var availableWeeks: [Int] {
        guard case .loaded(let items) = fameItems else { return [1] }
        let weeks = Set(items.map { $0.week })
        return weeks.sorted()
    }

    var groupedByUniversity: [(university: String, items: [CommunityFameItemModel])] {
        guard case .loaded(let items) = fameItems else { return [] }
        let filtered = items.filter { $0.week == selectedWeek }
        let grouped = Dictionary(grouping: filtered, by: { $0.university })
        return grouped.map { (university: $0.key, items: $0.value) }
            .sorted { $0.university < $1.university }
    }

    // MARK: - Function

    func selectWeek(_ week: Int) {
        selectedWeek = week
    }
}

// MARK: - Mock

private let mockFameItems: [CommunityFameItemModel] = [
    // 1주차
    .init(week: 1, university: "중앙대학교", profileImage: nil, userName: "김멋사", part: "Web", workbookTitle: "Web 1주차", content: "컴포넌트 분리가 매우 잘 되어있고, 상태 관리가 깔끔합니다."),
    .init(week: 1, university: "명지대학교", profileImage: nil, userName: "이서버", part: "Server", workbookTitle: "Server 1주차", content: "RESTful 원칙을 잘 준수하였으며 예외 처리가 훌륭합니다."),
    // 2주차
    .init(week: 2, university: "중앙대학교", profileImage: nil, userName: "이서버", part: "Server", workbookTitle: "Server 2주차", content: "의존성 주입 패턴을 잘 활용했습니다."),
    .init(week: 2, university: "덕성여자대학교", profileImage: nil, userName: "최코딩", part: "Web", workbookTitle: "Web 2주차", content: "타입 정의가 명확하고 코드가 깔끔합니다."),
    // 3주차
    .init(week: 3, university: "중앙대학교", profileImage: nil, userName: "김애플", part: "iOS", workbookTitle: "iOS 3주차", content: "MVVM 패턴을 잘 적용했습니다."),
    .init(week: 3, university: "명지대학교", profileImage: nil, userName: "박서버", part: "Android", workbookTitle: "Android 3주차", content: "Compose 활용이 인상적입니다."),
    // 4주차
    .init(week: 4, university: "중앙대학교", profileImage: nil, userName: "김멋사", part: "Web", workbookTitle: "Web 1주차", content: "컴포넌트 분리가 매우 잘 되어있고, 상태 관리가 깔끔합니다."),
]
