//
//  CardLinkPriorityRepository.swift
//  BusinessCardData
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
import SwiftData
import UMCFoundation
import BusinessCardDomain

/// 명함 뒷면 링크 우선순위 저장소 (#1679).
///
/// 서버는 링크 값만 갖고 순서는 앱이 정한다. 계정은 ``ReceivedCardRepository`` 처럼 호출부가
/// 넘기지 않고 저장소가 현재 로그인 계정을 직접 읽는다. `modelContext` 는 앱의 `mainContext`
/// 라 접근은 모두 메인 액터에서 한다 (같은 저장소의 문서 참고).
public final class CardLinkPriorityRepository:
    CardLinkPriorityRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    private let modelContext: ModelContext
    private let defaults: UserDefaults

    // MARK: - Init

    /// - Parameter defaults: 현재 로그인 계정을 읽을 저장소. 테스트는 격리된 suite를 넣는다.
    public init(modelContext: ModelContext, defaults: UserDefaults = .standard) {
        self.modelContext = modelContext
        self.defaults = defaults
    }

    // MARK: - Computed Property

    /// 지금 로그인한 계정. 호출마다 다시 읽는다 — DI가 인스턴스를 캐싱해 계정을 바꿔도 남는다.
    private var currentOwnerMemberId: String? {
        AppStorageKey.memberIdString(in: defaults)
    }

    // MARK: - Function

    /// 로그인 세션이 없거나 저장한 적 없으면 기본 순서다.
    public func fetchLinkPriority() async throws -> [CardLinkType] {
        guard let owner = currentOwnerMemberId else { return CardLinkType.allCases }
        let stored = try await MainActor.run { try record(owner: owner)?.linkTypes } ?? []
        return CardLinkType.normalizedPriority(stored.compactMap(CardLinkType.init(rawValue:)))
    }

    public func saveLinkPriority(_ priority: [CardLinkType]) async throws {
        guard let owner = currentOwnerMemberId else { throw AuthError.notLoggedIn }
        let linkTypes = CardLinkType.normalizedPriority(priority).map(\.rawValue)
        try await MainActor.run {
            if let existing = try record(owner: owner) {
                existing.linkTypes = linkTypes
            } else {
                modelContext.insert(
                    CardLinkPriorityRecord(ownerMemberId: owner, linkTypes: linkTypes)
                )
            }
            try modelContext.save()
        }
    }

    // MARK: - Private Function

    @MainActor
    private func record(owner: String) throws -> CardLinkPriorityRecord? {
        var descriptor = FetchDescriptor<CardLinkPriorityRecord>(
            predicate: #Predicate { $0.ownerMemberId == owner }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
