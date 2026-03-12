//
//  ScheduleRegistrationViewModelTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 3/13/26.
//

@testable import AppProduct
import Testing

@MainActor
struct ScheduleRegistrationViewModelTests {

    @Test("제목 입력 시 자동 추천 태그를 반영한다")
    func appliesSuggestedTagWhenTitleChanges() async {
        let viewModel = makeViewModel(suggestedTag: .project)

        await viewModel.titleDidChange(to: "UMC 앱 프로젝트 발표")

        #expect(viewModel.tag == [.project])
    }

    @Test("사용자가 태그를 직접 변경한 뒤에는 자동 추천이 덮어쓰지 않는다")
    func preservesManualOverrideAfterUserSelection() async {
        let viewModel = makeViewModel(suggestedTag: .project)

        await viewModel.titleDidChange(to: "UMC 앱 프로젝트 발표")
        viewModel.updateTagsFromUser([.meeting])
        await viewModel.titleDidChange(to: "운영진 회의")

        #expect(viewModel.tag == [.meeting])
    }

    @Test("사용자가 태그를 모두 비우면 자동 추천을 다시 허용한다")
    func reEnablesSuggestionAfterClearingManualTags() async {
        let viewModel = makeViewModel(suggestedTag: .study)

        viewModel.updateTagsFromUser([.meeting])
        viewModel.updateTagsFromUser([])
        await viewModel.titleDidChange(to: "알고리즘 스터디")

        #expect(viewModel.tag == [.study])
    }

    private func makeViewModel(
        suggestedTag: ScheduleIconCategory
    ) -> ScheduleRegistrationViewModel {
        ScheduleRegistrationViewModel(
            generateScheduleUseCase: MockGenerateScheduleUseCase(),
            updateScheduleUseCase: MockUpdateScheduleUseCase(),
            classifyScheduleUseCase: MockClassifyScheduleUseCase(
                suggestedTag: suggestedTag
            ),
            errorHandler: ErrorHandler()
        )
    }
}

private struct MockGenerateScheduleUseCase: GenerateScheduleUseCaseProtocol {
    func execute(schedule: GenerateScheduleRequetDTO) async throws { }
}

private struct MockUpdateScheduleUseCase: UpdateScheduleUseCaseProtocol {
    func execute(scheduleId: Int, schedule: UpdateScheduleRequestDTO) async throws { }
}

private struct MockClassifyScheduleUseCase: ClassifyScheduleUseCase {
    let suggestedTag: ScheduleIconCategory

    func execute(title: String) async -> ScheduleIconCategory {
        suggestedTag
    }
}
