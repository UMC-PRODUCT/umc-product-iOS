//
//  ChallengerGenRepositoryGenerationDisplayTests.swift
//  CoreDomainTests
//
//  Created by euijjang97 on 9/16/26.
//

import Testing
@testable import CoreDomain

/// `ChallengerGenRepositoryProtocol` 기수 표시값 역매핑 회귀 테스트 (#1356)
///
/// 화면에 노출되는 세 경로(스터디 그룹 생성 「기수」 행 · 공지 편집기 · 공지 상세)가
/// 모두 이 두 헬퍼를 거치므로, gisuId 누수 차단을 여기서 한 번에 못 박는다.
@Suite("기수 표시값 역매핑")
struct ChallengerGenRepositoryGenerationDisplayTests {

    // MARK: - Stub

    private struct StubRepository: ChallengerGenRepositoryProtocol {
        var pairs: [(gen: String, gisuId: String)] = [(gen: "11", gisuId: "3")]
        var throwsOnFetch = false

        func replaceMappings(_ pairs: [(gen: String, gisuId: String)]) throws {}

        func fetchGenGisuIdPairs() throws -> [(gen: String, gisuId: String)] {
            if throwsOnFetch { throw StubError.fetchFailed }
            return pairs
        }
    }

    private enum StubError: Error {
        case fetchFailed
    }

    // MARK: - gen(forGisuId:)

    @Test("gisuId를 기수 값으로 역매핑한다")
    func mapsGisuIdToGeneration() {
        #expect(StubRepository().gen(forGisuId: "3") == "11")
    }

    @Test("매핑에 없는 gisuId는 nil — 기수로 새지 않는다")
    func doesNotLeakUnmappedGisuId() {
        #expect(StubRepository().gen(forGisuId: "7") == nil)
    }

    @Test("매핑 조회가 실패해도 gisuId를 기수로 돌려주지 않는다")
    func doesNotLeakGisuIdOnFetchFailure() {
        #expect(StubRepository(throwsOnFetch: true).gen(forGisuId: "3") == nil)
    }

    @Test("매핑이 비어 있으면(홈 진입 전) nil")
    func returnsNilWhenMappingIsEmpty() {
        #expect(StubRepository(pairs: []).gen(forGisuId: "3") == nil)
    }

    @Test("빈 값과 0은 nil")
    func returnsNilForEmptyAndZero() {
        #expect(StubRepository().gen(forGisuId: "") == nil)
        #expect(StubRepository().gen(forGisuId: "0") == nil)
    }

    // MARK: - normalizedGen(forAmbiguousValue:)

    @Test("이미 기수 값이면 그대로 둔다 — 엉뚱한 기수로 바꾸지 않는다")
    func keepsValueThatIsAlreadyGeneration() {
        let repository = StubRepository(pairs: [(gen: "11", gisuId: "3"), (gen: "3", gisuId: "1")])
        #expect(repository.normalizedGen(forAmbiguousValue: "3") == "3")
    }

    @Test("기수 값이 아니면 gisuId로 보고 역매핑한다")
    func mapsAmbiguousGisuIdToGeneration() {
        #expect(StubRepository().normalizedGen(forAmbiguousValue: "3") == "11")
    }

    @Test("어느 쪽에도 없는 값은 nil — gisuId를 기수로 노출하지 않는다")
    func doesNotLeakUnknownAmbiguousValue() {
        #expect(StubRepository().normalizedGen(forAmbiguousValue: "9") == nil)
    }

    @Test("매핑이 비어 있으면 원본 값을 그대로 돌려주지 않는다")
    func doesNotLeakAmbiguousValueWhenMappingIsEmpty() {
        #expect(StubRepository(pairs: []).normalizedGen(forAmbiguousValue: "3") == nil)
    }
}
