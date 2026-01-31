//
//  CurriculumProgressModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 02/01/26.
//

import SwiftUI

// MARK: - CurriculumProgressModel

/// 커리큘럼 진행률 데이터 모델
struct CurriculumProgressModel: Equatable, Identifiable {

    // MARK: - Property

    let id: UUID
    let partName: String
    let curriculumTitle: String
    let completedCount: Int
    let totalCount: Int

    // MARK: - Computed Property

    /// 달성률 (0.0 ~ 1.0)
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    /// 달성률 퍼센트 (0 ~ 100)
    var progressPercentage: Int {
        Int(progress * 100)
    }

    /// 완료 텍스트 (예: "2/8 완료")
    var completionText: String {
        "\(completedCount)/\(totalCount) 완료"
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        partName: String,
        curriculumTitle: String,
        completedCount: Int,
        totalCount: Int
    ) {
        self.id = id
        self.partName = partName
        self.curriculumTitle = curriculumTitle
        self.completedCount = completedCount
        self.totalCount = totalCount
    }
}
