//
//  ChallengerGenRepository.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation
import SwiftData

/// SwiftData 기반 기수-기수ID 매핑 로컬 저장소 구현체
///
/// `ModelContext`를 주입받아 (gen, gisuId) 매핑을 upsert/조회합니다.
/// CloudKit Sync 활성화 시 `@Attribute(.unique)` 사용 불가하므로,
/// `gen` 기준 fetch 후 upsert 방식으로 처리합니다.
final class ChallengerGenRepository:
    ChallengerGenRepositoryProtocol, @unchecked Sendable
{

    // MARK: - Property

    private let modelContext: ModelContext

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Function

    /// 전체 매핑을 교체 저장합니다 (upsert + 미사용 레코드 삭제).
    ///
    /// - Note: CloudKit Sync에서 `@Attribute(.unique)` 사용 불가하므로
    ///   gen 기준 fetch 후 수동 upsert 방식으로 처리합니다.
    func replaceMappings(_ pairs: [(gen: Int, gisuId: Int)]) throws {
        let incomingGens = Set(pairs.map(\.gen))
        let existingDescriptor = FetchDescriptor<GenerationMappingRecord>()
        let existing = try modelContext.fetch(existingDescriptor)
        let existingByGen = Dictionary(uniqueKeysWithValues: existing.map { ($0.gen, $0) })

        for pair in pairs {
            if let record = existingByGen[pair.gen] {
                record.gisuId = pair.gisuId
                record.updatedAt = .now
            } else {
                let record = GenerationMappingRecord(
                    gisuId: pair.gisuId,
                    gen: pair.gen
                )
                modelContext.insert(record)
            }
        }

        for record in existing where !incomingGens.contains(record.gen) {
            modelContext.delete(record)
        }

        try modelContext.save()
    }

    /// 전체 기수의 (gen, gisuId) 매핑을 gen 오름차순으로 조회합니다.
    ///
    /// - Note: CloudKit Sync로 인한 중복 레코드를 `seenGens` 집합으로 필터링합니다.
    func fetchGenGisuIdPairs() throws -> [(gen: Int, gisuId: Int)] {
        let descriptor = FetchDescriptor<GenerationMappingRecord>(
            sortBy: [SortDescriptor(\.gen, order: .forward)]
        )
        let records = try modelContext.fetch(descriptor)
        var seenGens = Set<Int>()

        return records.compactMap {
            guard seenGens.insert($0.gen).inserted else {
                return nil
            }
            return (gen: $0.gen, gisuId: $0.gisuId)
        }
    }
}
