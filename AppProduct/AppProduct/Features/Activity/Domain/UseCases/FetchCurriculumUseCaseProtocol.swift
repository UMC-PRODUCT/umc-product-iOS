//
//  FetchCurriculumUseCaseProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 02/01/26.
//

import Foundation

// MARK: - Protocol

protocol FetchCurriculumUseCaseProtocol {
    /// 커리큘럼 데이터 조회 (진행률 + 미션 목록)
    func execute() async throws -> CurriculumData
}
