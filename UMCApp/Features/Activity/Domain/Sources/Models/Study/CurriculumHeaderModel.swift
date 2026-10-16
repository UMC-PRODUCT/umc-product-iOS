//
//  CurriculumHeaderModel.swift
//  ActivityDomain
//
//  Created by jaewon Lee on 5/11/26.
//

import Foundation
import UMCFoundation

public struct CurriculumHeaderModel: Equatable, Identifiable {

    // MARK: - Property

    public let id: UUID
    public let partType: UMCPartType?
    public let partName: String
    public let curriculumTitle: String

    // MARK: - Initializer

    public init(
        id: UUID = UUID(),
        partType: UMCPartType? = nil,
        partName: String,
        curriculumTitle: String
    ) {
        self.id = id
        self.partType = partType
        self.partName = partName
        self.curriculumTitle = curriculumTitle
    }
}
