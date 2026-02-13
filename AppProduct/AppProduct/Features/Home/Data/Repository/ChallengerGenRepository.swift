//
//  ChallengerGenRepository.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation
import SwiftData

/// SwiftData 기반 기수별 패널티 로컬 저장소 구현체
///
/// `ModelContext`를 주입받아 기수별 패널티 데이터를 upsert/조회합니다.
/// CloudKit Sync 활성화 시 `@Attribute(.unique)` 사용 불가하므로,
/// `gisuId` 기준 fetch 후 upsert 방식으로 처리합니다.
final class ChallengerGenRepository:
    ChallengerGenRepositoryProtocol, @unchecked Sendable
{

    // MARK: - Property

    private let modelContext: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Function

    func savePenalty(_ data: GenerationData) throws {
        let logsData = try encoder.encode(data.penaltyLogs)

        let targetGisuId = data.gisuId
        let descriptor = FetchDescriptor<PenaltyRecord>(
            predicate: #Predicate { $0.gisuId == targetGisuId }
        )
        let existing = try modelContext.fetch(descriptor)

        if let record = existing.first {
            record.penaltyPoint = data.penaltyPoint
            record.logsData = logsData
            record.updatedAt = .now

            // CloudKit 동기화로 인한 중복 레코드 제거
            for duplicate in existing.dropFirst() {
                modelContext.delete(duplicate)
            }
        } else {
            let record = PenaltyRecord(
                gisuId: data.gisuId,
                gen: data.gen,
                penaltyPoint: data.penaltyPoint,
                logsData: logsData
            )
            modelContext.insert(record)
        }

        try modelContext.save()
    }

    func fetchAllPenalties() throws -> [GenerationData] {
        let descriptor = FetchDescriptor<PenaltyRecord>(
            sortBy: [SortDescriptor(\.gen, order: .forward)]
        )
        let records = try modelContext.fetch(descriptor)

        return records.compactMap { record in
            guard let logs = try? decoder.decode(
                [PenaltyInfoItem].self,
                from: record.logsData
            ) else {
                return nil
            }
            return GenerationData(
                gisuId: record.gisuId,
                gen: record.gen,
                penaltyPoint: record.penaltyPoint,
                penaltyLogs: logs
            )
        }
    }

    func fetchGenGisuIdPairs() throws -> [(gen: Int, gisuId: Int)] {
        let descriptor = FetchDescriptor<PenaltyRecord>(
            sortBy: [SortDescriptor(\.gen, order: .forward)]
        )
        let records = try modelContext.fetch(descriptor)

        return records.map { (gen: $0.gen, gisuId: $0.gisuId) }
    }
}
