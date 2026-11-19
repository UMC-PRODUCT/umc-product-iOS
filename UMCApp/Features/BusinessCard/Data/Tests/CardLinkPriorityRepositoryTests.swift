//
//  CardLinkPriorityRepositoryTests.swift
//  BusinessCardDataTests
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
import SwiftData
import Testing
import UMCFoundation
import BusinessCardDomain
@testable import BusinessCardData

@MainActor
@Suite("CardLinkPriorityRepository — 기기 저장 링크 우선순위 (#1679)")
struct CardLinkPriorityRepositoryTests {

    private static let owner = "100"
    private static let otherOwner = "200"

    /// 컨테이너를 함께 붙잡지 않으면 인메모리 스토어가 먼저 해제돼 트랩한다 (Home 선례).
    private let container: ModelContainer
    private let defaults: UserDefaults
    private let repository: CardLinkPriorityRepository

    init() throws {
        container = try ModelContainer(
            for: CardLinkPriorityRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let suiteName = "test.businessCard.linkPriority.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(Self.owner, forKey: AppStorageKey.memberId)
        repository = CardLinkPriorityRepository(
            modelContext: container.mainContext,
            defaults: defaults
        )
    }

    @Test("저장한 적 없으면 기본 순서다")
    func defaultsWithoutRecord() async throws {
        #expect(try await repository.fetchLinkPriority() == CardLinkType.allCases)
    }

    @Test("저장한 순서를 그대로 읽고, 다시 저장하면 한 행을 덮어쓴다")
    func savesAndOverwrites() async throws {
        try await repository.saveLinkPriority([.blog, .github])
        try await repository.saveLinkPriority([.personal, .instagram])

        let priority = try await repository.fetchLinkPriority()
        let records = try container.mainContext.fetch(FetchDescriptor<CardLinkPriorityRecord>())

        #expect(priority == [.personal, .instagram, .github, .linkedIn, .blog])
        #expect(records.count == 1)
    }

    @Test("계정마다 순서가 따로 저장된다")
    func isolatesByOwner() async throws {
        try await repository.saveLinkPriority([.blog])
        defaults.set(Self.otherOwner, forKey: AppStorageKey.memberId)

        #expect(try await repository.fetchLinkPriority() == CardLinkType.allCases)
    }

    @Test("모르는 링크 종류가 저장돼 있으면 빼고 읽는다")
    func dropsUnknownStoredTypes() async throws {
        container.mainContext.insert(
            CardLinkPriorityRecord(ownerMemberId: Self.owner, linkTypes: ["X", "BLOG"])
        )

        #expect(try await repository.fetchLinkPriority().first == .blog)
    }

    @Test("로그인 세션이 없으면 기본 순서를 읽고, 저장은 거부한다")
    func requiresSessionToSave() async throws {
        defaults.removeObject(forKey: AppStorageKey.memberId)

        #expect(try await repository.fetchLinkPriority() == CardLinkType.allCases)
        await #expect(throws: AuthError.self) {
            try await repository.saveLinkPriority([.blog])
        }
    }
}
