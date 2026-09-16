//
//  NoticeGenerationDisplayTests.swift
//  NoticePresentationTests
//
//  Created by euijjang97 on 9/16/26.
//

import CoreDI
import CoreDomain
import Foundation
import NoticeDomain
import Testing
import UMCFoundation
@testable import NoticePresentation

// MARK: - Support

/// 기수 값(`gen`)과 기수 ID(`gisuId`)가 다른 실제 형태를 재현하는 스텁.
private struct StubChallengerGenRepository: ChallengerGenRepositoryProtocol {
    var pairs: [(gen: String, gisuId: String)] = [(gen: "11", gisuId: "3")]

    func replaceMappings(_ pairs: [(gen: String, gisuId: String)]) throws {}

    func fetchGenGisuIdPairs() throws -> [(gen: String, gisuId: String)] { pairs }
}

@MainActor
private func makeContainer(
    pairs: [(gen: String, gisuId: String)] = [(gen: "11", gisuId: "3")]
) -> DIContainer {
    let container = DIContainer()
    container.register(ChallengerGenRepositoryProtocol.self) {
        StubChallengerGenRepository(pairs: pairs)
    }
    return container
}

private func makeDetail(generation: String) -> NoticeDetail {
    NoticeDetail(
        id: "N-1",
        generation: generation,
        scope: .central,
        category: .general,
        isMustRead: false,
        title: "공지",
        content: "본문",
        authorID: "1",
        authorName: "홍길동",
        authorImageURL: nil,
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: nil,
        targetAudience: TargetAudience(
            generation: generation,
            scope: .central,
            parts: [],
            branches: [],
            schools: []
        ),
        hasPermission: false,
        images: [],
        links: [],
        vote: nil
    )
}

// MARK: - 공지 상세

@Suite("NoticeDetailViewModel — 기수 표시 (#1356)")
@MainActor
struct NoticeDetailGenerationTests {

    @Test("gisuId가 담긴 기수 필드를 실제 기수 값으로 보정한다")
    func normalizesGisuIdToGeneration() {
        let viewModel = NoticeDetailViewModel(
            container: makeContainer(),
            errorHandler: ErrorHandler(),
            model: makeDetail(generation: "3")
        )

        let normalized = viewModel.normalizeTargetGenerationIfNeeded(
            in: makeDetail(generation: "3")
        )
        #expect(normalized.generation == "11")
        #expect(normalized.targetAudience.generation == "11")
    }

    @Test("이미 기수 값이면 역매핑하지 않고 그대로 둔다")
    func keepsValueThatIsAlreadyGeneration() {
        let viewModel = NoticeDetailViewModel(
            container: makeContainer(pairs: [(gen: "11", gisuId: "3"), (gen: "3", gisuId: "1")]),
            errorHandler: ErrorHandler(),
            model: makeDetail(generation: "3")
        )

        let normalized = viewModel.normalizeTargetGenerationIfNeeded(
            in: makeDetail(generation: "3")
        )
        #expect(normalized.generation == "3")
        #expect(normalized.targetAudience.generation == "3")
    }

    @Test("매핑이 없으면 표시용 기수를 비운다 — gisuId가 기수로 새지 않는다")
    func doesNotLeakGisuIdWhenMappingIsMissing() {
        let viewModel = NoticeDetailViewModel(
            container: makeContainer(pairs: []),
            errorHandler: ErrorHandler(),
            model: makeDetail(generation: "3")
        )

        let normalized = viewModel.normalizeTargetGenerationIfNeeded(
            in: makeDetail(generation: "3")
        )
        #expect(normalized.generation == "")
    }

    @Test("판별에 실패해도 수신 대상 기수는 보존한다 — 열람 권한 판정 입력이다")
    func keepsTargetAudienceGenerationWhenUnresolved() {
        let viewModel = NoticeDetailViewModel(
            container: makeContainer(pairs: []),
            errorHandler: ErrorHandler(),
            model: makeDetail(generation: "3")
        )

        let normalized = viewModel.normalizeTargetGenerationIfNeeded(
            in: makeDetail(generation: "3")
        )
        #expect(normalized.targetAudience.generation == "3")
        #expect(
            NoticeReadStatusPermissionEvaluator.canViewReadStatus(
                roles: [.centralPresident],
                userChapterId: nil,
                userSchoolId: nil,
                targetAudience: normalized.targetAudience
            )
        )
    }

    @Test("기수를 특정하지 못하면 기수 태그를 붙이지 않는다")
    func omitsGenerationTagWhenUnresolved() {
        let item = NoticeItemModel(
            generation: "",
            scope: .central,
            category: .general,
            mustRead: false,
            isAlert: false,
            date: Date(timeIntervalSince1970: 0),
            title: "공지",
            content: "본문",
            writer: "홍길동",
            links: [],
            images: [],
            vote: nil,
            viewCount: "0",
            targetsAllGenerations: false
        )

        #expect(item.generationTag == nil)
        #expect(!item.tags.contains { $0.text.hasSuffix("기") })
    }
}

// MARK: - 공지 편집기

@Suite("NoticeEditorViewModel — 기수 표시 (#1356)")
@MainActor
struct NoticeEditorGenerationTests {

    @Test("선택된 gisuId를 기수 값으로 역매핑해 보여준다")
    func showsMappedGeneration() {
        let viewModel = NoticeEditorViewModel(
            container: makeContainer(),
            selectedGisuId: "3"
        )

        #expect(viewModel.selectedGenerationValue == "11")
        #expect(viewModel.selectedGenerationTitle == "11기")
    }

    @Test("매핑에 없는 gisuId는 기수로 표시하지 않는다")
    func doesNotLeakUnmappedGisuId() {
        let viewModel = NoticeEditorViewModel(
            container: makeContainer(pairs: []),
            selectedGisuId: "3"
        )

        #expect(viewModel.selectedGenerationValue == nil)
        #expect(viewModel.selectedGenerationTitle == nil)
    }
}
