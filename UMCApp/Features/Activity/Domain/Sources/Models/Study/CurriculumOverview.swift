//
//  CurriculumOverview.swift
//  ActivityDomain
//
//  Created by jaewon Lee on 7/29/26.
//

import Foundation

public struct CurriculumOverview: Equatable {

    // MARK: - Property

    public let header: CurriculumHeaderModel
    public let missions: [MissionCardModel]

    // MARK: - Initializer

    public init(
        header: CurriculumHeaderModel,
        missions: [MissionCardModel]
    ) {
        self.header = header
        self.missions = missions
    }
}
