//
//  ProjectAdminViewModelTests.swift
//  ProjectPresentationTests
//
//  Created by euijjang97 on 9/20/26.
//

import ProjectData
import ProjectDomain
import Testing
import UMCFoundation
@testable import ProjectPresentation

#if DEBUG
@Suite("ProjectAdminViewModel")
@MainActor
struct ProjectAdminViewModelTests {

    @Test("운영진은 관리 프로젝트 권한과 지부 통계를 함께 조회한다")
    func operatorLoadsDashboard() async throws {
        let viewModel = makeViewModel(role: .chapterPresident)

        await viewModel.fetch()

        let dashboard = try #require(viewModel.dashboard.value)
        #expect(dashboard.projects.map(\.id) == ["101"])
        #expect(dashboard.permission(for: "101") != nil)
        #expect(dashboard.statistics?.chapterId == "5")
        #expect(viewModel.matchingRounds.value?.map(\.id) == ["11"])
        #expect(viewModel.matchingStatistics.value?.chapterId == "5")
    }

    @Test("챌린저는 운영 API 대신 빈 대시보드를 받는다")
    func challengerReceivesEmptyDashboard() async throws {
        let viewModel = makeViewModel(role: .challenger)

        await viewModel.fetch()

        let dashboard = try #require(viewModel.dashboard.value)
        #expect(viewModel.canAccess == false)
        #expect(dashboard.projects.isEmpty)
        #expect(viewModel.matchingRounds.value?.isEmpty == true)
    }

    @Test(
        "매칭 차수 폼은 이름과 시간 순서가 모두 유효해야 저장할 수 있다"
    )
    func validatesMatchingRoundForm() {
        var form = ProjectMatchingRoundForm()
        #expect(form.isValid == false)

        form.name = "1차 매칭"
        #expect(form.isValid)

        form.decisionDeadline = form.endsAt.addingTimeInterval(-1)
        #expect(form.isValid == false)
    }

    private func makeViewModel(role: ManagementTeam) -> ProjectAdminViewModel {
        let repository = MockProjectRepository()
        return ProjectAdminViewModel(
            projectUseCase: ProjectUseCase(repository: repository),
            matchingRoundUseCase: ProjectMatchingRoundUseCase(repository: repository),
            role: role,
            gisuId: "9",
            chapterId: "5"
        )
    }
}
#endif
