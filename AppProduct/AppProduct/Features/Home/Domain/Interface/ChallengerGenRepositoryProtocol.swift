//
//  ChallengerGenRepositoryProtocol.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation

/// 기수별 패널티 로컬 저장소 Repository Protocol
///
/// SwiftData + CloudKit 기반으로 기수별 패널티 데이터를 저장/조회합니다.
protocol ChallengerGenRepositoryProtocol: Sendable {

    /// 패널티 데이터 저장 (gisuId 기준 upsert)
    /// - Parameter data: 저장할 기수별 패널티 데이터
    func savePenalty(_ data: GenerationData) throws

    /// 전체 기수 패널티 조회
    /// - Returns: 기수 오름차순 정렬된 패널티 데이터 목록
    func fetchAllPenalties() throws -> [GenerationData]

    /// 전체 기수의 (gen, gisuId) 매핑 배열 조회
    /// - Returns: gen 오름차순 정렬된 (gen, gisuId) 튜플 배열
    func fetchGenGisuIdPairs() throws -> [(gen: Int, gisuId: Int)]
}
