//
//  MissionCardModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/29/26.
//

import SwiftUI

// MARK: - MissionCardModel

/// 미션 카드 데이터 모델
struct MissionCardModel: Equatable, Identifiable {

    // MARK: - Property

    let id: UUID
    let originalWorkbookId: Int?
    let challengerWorkbookId: Int?
    let week: Int
    let platform: String
    let title: String
    let missionTitle: String
    let missionType: MissionType
    var status: MissionStatus

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        originalWorkbookId: Int? = nil,
        challengerWorkbookId: Int? = nil,
        week: Int,
        platform: String,
        title: String,
        missionTitle: String,
        missionType: MissionType = .link,
        status: MissionStatus
    ) {
        self.id = id
        self.originalWorkbookId = originalWorkbookId
        self.challengerWorkbookId = challengerWorkbookId
        self.week = week
        self.platform = platform
        self.title = title
        self.missionTitle = missionTitle
        self.missionType = missionType
        self.status = status
    }
}
