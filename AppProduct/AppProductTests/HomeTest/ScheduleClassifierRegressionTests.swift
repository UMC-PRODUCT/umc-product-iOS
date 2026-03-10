//
//  ScheduleClassifierRegressionTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 3/10/26.
//

@testable import AppProduct
import Testing

struct ScheduleClassifierRegressionTests {

    @Test("일정 등록 태그 목록에서 테스트 태그를 숨긴다")
    func registrationTagsExcludeTestingCategory() {
        #expect(!ScheduleIconCategory.selectableCases.contains(.testing))
    }

    @Test("테스트 관련 제목은 더 이상 테스트 태그로 분류하지 않는다")
    func classifierDoesNotReturnTestingForLegacyTitles() async {
        let useCase = ClassifyScheduleUseCaseImpl(
            repository: MockScheduleClassifierRepository(
                keywordResult: .general
            )
        )

        let result = await useCase.execute(title: "11기 QA 테스트")

        #expect(result == .general)
    }

    @Test("키워드 분류도 테스트 태그를 반환하지 않는다")
    func keywordClassifierFallsBackToGeneralForLegacyTestingWords() {
        let repository = ScheduleClassifierRepositoryImpl()

        let result = repository.classifyWithKeywords(title: "11기 QA 테스트")

        #expect(result == .general)
    }
}

private struct MockScheduleClassifierRepository: ScheduleClassifierRepository {
    let keywordResult: ScheduleIconCategory

    var isModelLoaded: Bool { false }

    func loadModel() throws { }

    func classifyWithML(title: String) -> ScheduleIconCategory? {
        nil
    }

    func classifyWithKeywords(title: String) -> ScheduleIconCategory {
        keywordResult
    }

    func getCachedCategory(for title: String) -> ScheduleIconCategory? {
        nil
    }

    func cacheCategory(_ category: ScheduleIconCategory, for title: String) { }
}
