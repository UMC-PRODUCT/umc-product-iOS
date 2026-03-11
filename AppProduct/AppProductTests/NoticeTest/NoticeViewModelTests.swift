//
//  NoticeViewModelTests.swift
//  AppProductTests
//
//  Created by Codex on 3/11/26.
//

@testable import AppProduct
import Foundation
import Testing

struct NoticeViewModelTests {

    @Test("기수 변경 시 상단 필터 라벨을 새 기수 기준으로 갱신하고 기존 선택을 초기화한 뒤 재조회한다")
    func refreshGenerationScopedFiltersWhenGenerationChanges() async {
        let targetUseCase = MockNoticeListTargetUseCase(
            branchesByGisu: [
                2: [NoticeTargetOption(id: 21, name: "Ain")]
            ],
            schoolsByGisu: [
                2: [NoticeTargetOption(id: 2, name: "가천대학교")]
            ]
        )
        let noticeUseCase = MockNoticeUseCase()

        let viewModel = await MainActor.run {
            makeSUT(
                noticeUseCase: noticeUseCase,
                targetUseCase: targetUseCase
            )
        }

        await MainActor.run {
            viewModel.applyUserContext(
                schoolName: "중앙대학교",
                chapterName: "Xenon",
                responsiblePart: "IOS",
                organizationTypeRawValue: "CENTRAL",
                chapterId: 14,
                schoolId: 1,
                memberRoleRawValue: "CHALLENGER",
                generationOrganizationsJSON: "[]"
            )
            viewModel.gisuPairs = [(gen: 9, gisuId: 3), (gen: 8, gisuId: 2)]
            viewModel.generations = [Generation(value: 9), Generation(value: 8)]
            viewModel.isGisuListLoaded = true
            viewModel.selectedGeneration = Generation(value: 9)
            viewModel.generationStates[9] = GenerationFilterState(mainFilter: .part(.ios))
        }

        await MainActor.run {
            viewModel.selectGeneration(Generation(value: 8))
        }

        await waitUntil {
            let targetCalls = await targetUseCase.fetchBranchesCalls()
            let hasNoticeRequest = await noticeUseCase.hasRequest(gisuId: 2)
            return targetCalls.contains(2) && hasNoticeRequest
        }

        let labels = await MainActor.run {
            viewModel.mainFilterItems.map(\.labelText)
        }
        let selectedMainFilterLabel = await MainActor.run {
            viewModel.selectedMainFilter.labelText
        }
        let searchState = await MainActor.run {
            (viewModel.isSearchMode, viewModel.searchQuery)
        }
        let latestRequest = await noticeUseCase.latestRequestSummary()

        #expect(labels == ["UMC 공지", "지부", "학교"])
        #expect(selectedMainFilterLabel == "UMC 공지")
        #expect(searchState.0 == false)
        #expect(searchState.1.isEmpty)
        #expect(latestRequest?.gisuId == 2)
        #expect(latestRequest?.chapterId == nil)
        #expect(latestRequest?.schoolId == nil)
        #expect(latestRequest?.part == nil)
    }

    @Test("기수별 조직 정보가 저장돼 있으면 상단 라벨과 필터 요청이 선택 기수 기준으로 바뀐다")
    func useGenerationScopedOrganizationWhenGenerationChanges() async throws {
        let targetUseCase = MockNoticeListTargetUseCase(
            branchesByGisu: [
                2: [NoticeTargetOption(id: 21, name: "Ain")]
            ],
            schoolsByGisu: [
                2: [NoticeTargetOption(id: 7, name: "중앙대학교")]
            ]
        )
        let noticeUseCase = MockNoticeUseCase()
        let contexts = [
            GenerationOrganizationContext(
                gen: 8,
                chapterId: 21,
                chapterName: "Ain",
                schoolId: 7,
                schoolName: "중앙대학교"
            )
        ]
        let contextsData = try JSONEncoder().encode(contexts)
        let contextsJSON = String(decoding: contextsData, as: UTF8.self)

        let viewModel = await MainActor.run {
            makeSUT(
                noticeUseCase: noticeUseCase,
                targetUseCase: targetUseCase
            )
        }

        await MainActor.run {
            viewModel.applyUserContext(
                schoolName: "가천대학교",
                chapterName: "Xenon",
                responsiblePart: "IOS",
                organizationTypeRawValue: "CENTRAL",
                chapterId: 14,
                schoolId: 1,
                memberRoleRawValue: "CHALLENGER",
                generationOrganizationsJSON: contextsJSON
            )
            viewModel.gisuPairs = [(gen: 9, gisuId: 3), (gen: 8, gisuId: 2)]
            viewModel.generations = [Generation(value: 9), Generation(value: 8)]
            viewModel.isGisuListLoaded = true
            viewModel.selectedGeneration = Generation(value: 8)
            viewModel.generationStates[8] = GenerationFilterState(mainFilter: .branch("지부"))
        }

        await MainActor.run {
            viewModel.selectMainFilter(.branch("지부"))
        }

        await waitUntil {
            let latestRequest = await noticeUseCase.latestRequestSummary()
            return latestRequest?.gisuId == 2 && latestRequest?.chapterId == 21
        }

        let labels = await MainActor.run {
            viewModel.mainFilterItems.map(\.labelText)
        }
        let latestRequest = await noticeUseCase.latestRequestSummary()

        #expect(labels == ["UMC 공지", "Ain", "중앙대학교"])
        #expect(latestRequest?.gisuId == 2)
        #expect(latestRequest?.chapterId == 21)
        #expect(latestRequest?.schoolId == nil)
    }

    @MainActor
    private func makeSUT(
        noticeUseCase: MockNoticeUseCase,
        targetUseCase: MockNoticeListTargetUseCase
    ) -> NoticeViewModel {
        let container = DIContainer()
        container.register(NoticeUseCaseProtocol.self) { noticeUseCase }
        container.register(NoticeEditorTargetUseCaseProtocol.self) { targetUseCase }
        container.register(ChallengerGenRepositoryProtocol.self) {
            MockNoticeGenRepository()
        }

        return NoticeViewModel(container: container)
    }

    private func waitUntil(
        maxAttempts: Int = 100,
        condition: @escaping () async -> Bool
    ) async {
        for _ in 0..<maxAttempts {
            if await condition() {
                return
            }
            await Task.yield()
        }
    }
}

private actor MockNoticeListTargetUseCase: NoticeEditorTargetUseCaseProtocol {
    private let branchesByGisu: [Int: [NoticeTargetOption]]
    private let schoolsByGisu: [Int: [NoticeTargetOption]]
    private var recordedFetchBranchesCalls: [Int] = []

    init(
        branchesByGisu: [Int: [NoticeTargetOption]] = [:],
        schoolsByGisu: [Int: [NoticeTargetOption]] = [:]
    ) {
        self.branchesByGisu = branchesByGisu
        self.schoolsByGisu = schoolsByGisu
    }

    func fetchAllBranches() async throws -> [NoticeTargetOption] {
        []
    }

    func fetchBranches(gisuId: Int) async throws -> [NoticeTargetOption] {
        recordedFetchBranchesCalls.append(gisuId)
        return branchesByGisu[gisuId] ?? []
    }

    func fetchBranchName(chapterId: Int) async throws -> String {
        branchesByGisu.values
            .flatMap { $0 }
            .first(where: { $0.id == chapterId })?
            .name ?? ""
    }

    func fetchAllSchools() async throws -> [NoticeTargetOption] {
        []
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

private actor MockNoticeUseCase: NoticeUseCaseProtocol {
    private var requests: [NoticeListRequestDTO] = []

    func uploadNoticeAttachmentImage(imageData: Data, fileName: String?) async throws -> String {
        fatalError("Not used in NoticeViewModelTests")
    }

    func createNotice(
        title: String,
        content: String,
        shouldNotify: Bool,
        targetInfo: TargetInfoDTO,
        links: [String],
        imageIds: [String]
    ) async throws -> NoticeDetail {
        fatalError("Not used in NoticeViewModelTests")
    }

    func addVote(
        noticeId: Int,
        title: String,
        isAnonymous: Bool,
        allowMultipleChoice: Bool,
        startsAt: Date,
        endsAtExclusive: Date,
        options: [String]
    ) async throws -> AddVoteResponseDTO {
        fatalError("Not used in NoticeViewModelTests")
    }

    func addLink(noticeId: Int, links: [String]) async throws -> NoticeItemModel {
        fatalError("Not used in NoticeViewModelTests")
    }

    func addImage(noticeId: Int, imageIds: [String]) async throws -> NoticeItemModel {
        fatalError("Not used in NoticeViewModelTests")
    }

    func readNotice(noticeId: Int) async throws {}

    func submitVoteResponse(voteId: Int, optionIds: [Int]) async throws {}

    func sendReminder(noticeId: Int, targetIds: [Int]) async throws {}

    func updateNotice(
        noticeId: Int,
        title: String,
        content: String
    ) async throws -> NoticeDetail {
        fatalError("Not used in NoticeViewModelTests")
    }

    func updateLinks(
        noticeId: Int,
        links: [String]
    ) async throws -> NoticeDetail {
        fatalError("Not used in NoticeViewModelTests")
    }

    func updateImages(
        noticeId: Int,
        imageIds: [String]
    ) async throws -> NoticeDetail {
        fatalError("Not used in NoticeViewModelTests")
    }

    func getAllNotices(request: NoticeListRequestDTO) async throws -> NoticePageDTO<NoticeDTO> {
        requests.append(request)
        return NoticePageDTO(
            content: [],
            page: "0",
            size: "20",
            totalElements: "0",
            totalPages: "0",
            hasNext: false,
            hasPrevious: false
        )
    }

    func getDetailNotice(noticeId: Int) async throws -> NoticeDetail {
        fatalError("Not used in NoticeViewModelTests")
    }

    func getReadStatics(noticeId: Int) async throws -> NoticeReadStaticsDTO {
        fatalError("Not used in NoticeViewModelTests")
    }

    func getReadStatusList(
        noticeId: Int,
        cursorId: Int,
        filterType: String,
        organizationIds: [Int],
        status: String
    ) async throws -> NoticeReadStatusResponseDTO {
        fatalError("Not used in NoticeViewModelTests")
    }

    func searchNotice(
        keyword: String,
        request: NoticeListRequestDTO
    ) async throws -> NoticePageDTO<NoticeDTO> {
        requests.append(request)
        return NoticePageDTO(
            content: [],
            page: "0",
            size: "20",
            totalElements: "0",
            totalPages: "0",
            hasNext: false,
            hasPrevious: false
        )
    }

    func deleteNotice(noticeId: Int) async throws {}

    func deleteVote(noticeId: Int) async throws {}

    func recordedRequests() -> [NoticeListRequestDTO] {
        requests
    }

    func hasRequest(gisuId: Int) -> Bool {
        requests.contains { $0.gisuId == gisuId }
    }

    func latestRequestSummary() -> (gisuId: Int, chapterId: Int?, schoolId: Int?, part: String?)? {
        guard let latest = requests.last else { return nil }
        return (
            gisuId: latest.gisuId,
            chapterId: latest.chapterId,
            schoolId: latest.schoolId,
            part: latest.part?.apiValue
        )
    }
}

private struct MockNoticeGenRepository: ChallengerGenRepositoryProtocol {
    func replaceMappings(_ pairs: [(gen: Int, gisuId: Int)]) throws {
        _ = pairs
    }

    func fetchGenGisuIdPairs() throws -> [(gen: Int, gisuId: Int)] {
        []
    }
}
