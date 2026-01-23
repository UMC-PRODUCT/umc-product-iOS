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

    var totalWeeks: Int {
        fameItems.map { $0.week }.max() ?? 1
    }

    var fameItems: [CommunityFameItemModel] = []

    var groupedByUniversity: [(university: String, items: [CommunityFameItemModel])] {
        let filtered = fameItems.filter { $0.week == selectedWeek }
        let grouped = Dictionary(grouping: filtered, by: { $0.university })
        return grouped.map { (university: $0.key, items: $0.value) }
            .sorted { $0.university < $1.university }
    }

    // MARK: - Function

    func selectWeek(_ week: Int) {
        selectedWeek = week
    }
}
