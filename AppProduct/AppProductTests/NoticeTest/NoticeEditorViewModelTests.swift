//
//  NoticeEditorViewModelTests.swift
//  AppProductTests
//
//  Created by Codex on 3/10/26.
//

@testable import AppProduct
import Foundation
import Testing

struct NoticeEditorViewModelTests {

    @Test("공지 에디터는 선택된 gisuId를 실제 기수 표시값으로 보정한다")
    func mapSelectedGisuIdToGenerationTitle() async {
        let viewModel = await MainActor.run {
            makeSUT(
                selectedGisuId: 3,
                targetUseCase: MockNoticeEditorTargetUseCase(),
                genPairs: [(gen: 9, gisuId: 3)]
            )
        }

        let generationTitle = await MainActor.run { viewModel.selectedGenerationTitle }

        #expect(generationTitle == "9기")
    }

    @Test("특정 기수 공지 작성 시 지부 목록은 선택된 기수 기준으로 조회한다")
    func loadFilteredBranchesForSelectedGisu() async throws {
        let targetUseCase = MockNoticeEditorTargetUseCase(
            branchesByGisu: [
                3: [NoticeTargetOption(id: 14, name: "Ain")],
                4: [NoticeTargetOption(id: 17, name: "Betelgeuse")]
            ],
            schoolsByGisu: [
                3: [NoticeTargetOption(id: 1, name: "가천대학교")]
            ]
        )
        let viewModel = await MainActor.run {
            makeSUT(
                selectedGisuId: 3,
                initialCategory: .central,
                targetUseCase: targetUseCase,
                genPairs: [(gen: 9, gisuId: 3)]
            )
        }

        await viewModel.loadTargetOptions()

        let branchOptions = await MainActor.run { viewModel.branchOptions }
        let fetchBranchesCalls = await targetUseCase.fetchBranchesCalls()

        #expect(branchOptions == [NoticeTargetOption(id: 14, name: "Ain")])
        #expect(fetchBranchesCalls == [3])
    }

    @Test("중앙 공지 작성 화면은 지부와 학교 동시 선택 불가 안내를 노출한다")
    func showTargetExclusivityHintForCentralCategory() async {
        let viewModel = await MainActor.run {
            makeSUT(
                selectedGisuId: 3,
                initialCategory: .central,
                targetUseCase: MockNoticeEditorTargetUseCase(),
                genPairs: [(gen: 9, gisuId: 3)]
            )
        }

        let shouldShowHint = await MainActor.run { viewModel.shouldShowTargetExclusivityHint }

        #expect(shouldShowHint == true)
    }

    @Test("공지 생성 권한 오류는 서버 message를 그대로 Alert에 표시한다")
    func showServerMessageForForbiddenCreateError() async {
        let viewModel = await MainActor.run {
            makeSUT(
                selectedGisuId: 3,
                targetUseCase: MockNoticeEditorTargetUseCase(),
                genPairs: [(gen: 9, gisuId: 3)]
            )
        }
        let errorData = #"{"success":false,"code":"NOTICE-0403","message":"공지 작성 권한이 없습니다.","result":null}"#
            .data(using: .utf8)

        let didPresentAlert = await MainActor.run {
            viewModel.presentNoticeRequestErrorAlert(for: .requestFailed(statusCode: 403, data: errorData))
        }
        let alertMessage = await MainActor.run { viewModel.alertPrompt?.message }
        let alertTitle = await MainActor.run { viewModel.alertPrompt?.title }

        #expect(didPresentAlert == true)
        #expect(alertTitle == "권한 없음")
        #expect(alertMessage == "공지 작성 권한이 없습니다.")
    }

    @MainActor
    private func makeSUT(
        selectedGisuId: Int,
        initialCategory: EditorMainCategory = .all,
        targetUseCase: MockNoticeEditorTargetUseCase,
        genPairs: [(gen: Int, gisuId: Int)]
    ) -> NoticeEditorViewModel {
        let container = DIContainer()
        container.register(NoticeEditorTargetUseCaseProtocol.self) { targetUseCase }
        container.register(ChallengerGenRepositoryProtocol.self) {
            MockChallengerGenRepository(genPairs: genPairs)
        }

        return NoticeEditorViewModel(
            container: container,
            mode: .create,
            selectedGisuId: selectedGisuId,
            initialCategory: initialCategory
        )
    }
}

private actor MockNoticeEditorTargetUseCase: NoticeEditorTargetUseCaseProtocol {
    private let allBranches: [NoticeTargetOption]
    private let branchesByGisu: [Int: [NoticeTargetOption]]
    private let allSchools: [NoticeTargetOption]
    private let schoolsByGisu: [Int: [NoticeTargetOption]]
    private var recordedFetchBranchesCalls: [Int] = []

    init(
        allBranches: [NoticeTargetOption] = [],
        branchesByGisu: [Int: [NoticeTargetOption]] = [:],
        allSchools: [NoticeTargetOption] = [],
        schoolsByGisu: [Int: [NoticeTargetOption]] = [:]
    ) {
        self.allBranches = allBranches
        self.branchesByGisu = branchesByGisu
        self.allSchools = allSchools
        self.schoolsByGisu = schoolsByGisu
    }

    func fetchAllBranches() async throws -> [NoticeTargetOption] {
        allBranches
    }

    func fetchBranches(gisuId: Int) async throws -> [NoticeTargetOption] {
        recordedFetchBranchesCalls.append(gisuId)
        return branchesByGisu[gisuId] ?? []
    }

    func fetchBranchName(chapterId: Int) async throws -> String {
        allBranches.first(where: { $0.id == chapterId })?.name ?? ""
    }

    func fetchAllSchools() async throws -> [NoticeTargetOption] {
        allSchools
    }

    func fetchSchools(gisuId: Int) async throws -> [NoticeTargetOption] {
        schoolsByGisu[gisuId] ?? []
    }

    func fetchSchools(inChapterId chapterId: Int, gisuId: Int) async throws -> [NoticeTargetOption] {
        schoolsByGisu[gisuId] ?? []
    }

    func fetchBranchesCalls() -> [Int] {
        recordedFetchBranchesCalls
    }
}

private struct MockChallengerGenRepository: ChallengerGenRepositoryProtocol {
    let genPairs: [(gen: Int, gisuId: Int)]

    func replaceMappings(_ pairs: [(gen: Int, gisuId: Int)]) throws {
        _ = pairs
    }

    func fetchGenGisuIdPairs() throws -> [(gen: Int, gisuId: Int)] {
        genPairs
    }
}
