//
//  NoticeListRegressionTests.swift
//  NoticePresentationTests
//
//  Created by euijjang97 on 9/27/26.
//

#if DEBUG
import CoreDI
import CoreDomain
import Foundation
import NoticeDomain
import Testing
import UMCFoundation
@testable import NoticePresentation

private enum StubError: Error { case unused }

private final class ListUseCase: NoticeUseCaseProtocol {
    var handler: (NoticeListRequest, String?) async throws -> NoticePage = { _, _ in
        NoticePage(items: [], hasNext: false, totalElements: "0")
    }
    func uploadNoticeAttachmentImage(imageData: Data, fileName: String?) async throws -> String {
        throw StubError.unused
    }
    func createNotice(
        title: String,
        content: String,
        shouldNotify: Bool,
        targetInfo: NoticeTargetInfo,
        links: [String],
        imageIds: [String]
    ) async throws -> NoticeDetail {
        throw StubError.unused
    }
    func addVote(
        noticeId: String,
        title: String,
        isAnonymous: Bool,
        allowMultipleChoice: Bool,
        startsAt: Date,
        endsAtExclusive: Date,
        options: [String]
    ) async throws -> String {
        throw StubError.unused
    }
    func addLink(noticeId: String, links: [String]) async throws -> NoticeItemModel {
        throw StubError.unused
    }
    func addImage(noticeId: String, imageIds: [String]) async throws -> NoticeItemModel {
        throw StubError.unused
    }
    func readNotice(noticeId: String) async throws { throw StubError.unused }
    func submitVoteResponse(noticeId: String, optionIds: [String]) async throws {
        throw StubError.unused
    }
    func updateVoteResponse(noticeId: String, optionIds: [String]) async throws {
        throw StubError.unused
    }
    func sendReminder(noticeId: String, targetIds: [String]) async throws {
        throw StubError.unused
    }
    func updateNotice(
        noticeId: String,
        title: String,
        content: String
    ) async throws -> NoticeDetail {
        throw StubError.unused
    }
    func updateLinks( noticeId: String, links: [String] ) async throws -> NoticeDetail {
        throw StubError.unused
    }
    func updateImages( noticeId: String, imageIds: [String] ) async throws -> NoticeDetail {
        throw StubError.unused
    }
    func getAllNotices(request: NoticeListRequest) async throws -> NoticePage {
        try await handler(request, nil)
    }
    func getDetailNotice(noticeId: String) async throws -> NoticeDetail { throw StubError.unused }
    func getReadStatics(noticeId: String) async throws -> NoticeReadStatics {
        throw StubError.unused
    }
    func getReadStatusList(
        noticeId: String,
        cursorId: String,
        filterType: String,
        organizationIds: [String],
        status: String
    ) async throws -> NoticeReadStatusPage {
        throw StubError.unused
    }
    func searchNotice( keyword: String, request: NoticeListRequest ) async throws -> NoticePage {
        try await handler(request, keyword)
    }
    func deleteNotice(noticeId: String) async throws { throw StubError.unused }
    func deleteVote(noticeId: String) async throws { throw StubError.unused }
}

private struct ListGenerations: ChallengerGenRepositoryProtocol {
    func replaceMappings(_ pairs: [(gen: String, gisuId: String)]) throws {}
    func fetchGenGisuIdPairs() throws -> [(gen: String, gisuId: String)] { [("11", "3")] }
}

private struct ListReads: NoticeReadRepositoryProtocol {
    func fetchReadNoticeIDs(memberId: String) throws -> Set<String> { [] }
    func markAsRead(noticeId: String, memberId: String) throws {}
}

private struct ListTargets: NoticeEditorTargetUseCaseProtocol {
    func fetchSelectableParts() async throws -> [NoticeSelectablePart] { throw StubError.unused }
    func fetchAllBranches() async throws -> [NoticeTargetOption] { throw StubError.unused }
    func fetchBranches(gisuId: String) async throws -> [NoticeTargetOption] {
        throw StubError.unused
    }
    func fetchBranchName(chapterId: String) async throws -> String { throw StubError.unused }
    func fetchAllSchools() async throws -> [NoticeTargetOption] { throw StubError.unused }
    func fetchSchools(gisuId: String) async throws -> [NoticeTargetOption] {
        throw StubError.unused
    }
    func fetchSchools(
        inChapterId chapterId: String,
        gisuId: String
    ) async throws -> [NoticeTargetOption] {
        throw StubError.unused
    }
}

@MainActor
private func listContainer(_ useCase: ListUseCase) -> DIContainer {
    let container = DIContainer()
    container.register(NoticeUseCaseProtocol.self) { useCase }
    container.register(ChallengerGenRepositoryProtocol.self) { ListGenerations() }
    container.register(NoticeReadRepositoryProtocol.self) { ListReads() }
    container.register(NoticeEditorTargetUseCaseProtocol.self) { ListTargets() }
    return container
}

private func listItem(_ id: String, gisuId: String? = "3") -> NoticeItemModel {
    NoticeItemModel(
        noticeId: id, generation: "0", scope: .campus, category: .general,
        mustRead: false, isAlert: false, date: .distantPast, title: id, content: "본문",
        writer: "작성자", links: [], images: [], vote: nil, viewCount: "0",
        targetsAllGenerations: true, targetGisuId: gisuId
    )
}

private func listPage(_ id: String, hasNext: Bool = true) -> NoticePage {
    NoticePage(items: [listItem(id)], hasNext: hasNext, totalElements: "3")
}

@Suite("공지 조회 범위와 응답 순서 (#1544–#1547)", .timeLimit(.minutes(1)))
@MainActor
struct NoticeListRegressionTests {
    private func model(_ useCase: ListUseCase) throws -> NoticeViewModel {
        let model = NoticeViewModel(container: listContainer(useCase), errorHandler: ErrorHandler())
        model.gisuPairs = [("11", "3")]
        model.isGisuListLoaded = true
        model.selectedGeneration = Generation(value: "11")
        model.chapterId = "current-chapter"
        let data = Data("""
        [{"gen":"11","chapterId":"old-chapter","schoolId":"school"}]
        """.utf8)
        let contexts = try JSONDecoder().decode([GenerationOrganizationContext].self, from: data)
        model.generationOrganizations = Dictionary(uniqueKeysWithValues: contexts.map { ($0.gen, $0) })
        model.currentState = GenerationFilterState(mainFilter: .school("학교"))
        return model
    }

    @Test("선택 기수의 지부를 사용하고 소속이 없으면 요청하지 않는다")
    func pastGenerationScope() async throws {
        let useCase = ListUseCase()
        var requests = [NoticeListRequest]()
        useCase.handler = { request, _ in requests.append(request); return listPage("notice") }
        let model = try model(useCase)
        model.currentState = GenerationFilterState(mainFilter: .branch("과거 지부"))
        await model.fetchNotices()
        await model.searchNotices(keyword: "검색")
        #expect(requests.count == 2)
        #expect(requests.allSatisfy { $0.chapterId == "old-chapter" && $0.gisuId == "3" })
        model.generationOrganizations = [:]
        await model.fetchNotices()
        #expect(requests.count == 2)
        guard case .failed(let error) = model.noticeItems else {
            Issue.record("소속이 없으면 안내 상태여야 합니다")
            return
        }
        #expect(error.userMessage.contains("소속 정보"))
    }

    @Test("회장단과 파트장이 중앙·교내 범위를 목록과 검색에 동일하게 적용한다",
          arguments: [ManagementTeam.schoolPresident, .schoolPartLeader])
    func staffScopes(role: ManagementTeam) async {
        let useCase = ListUseCase()
        var requests = [(NoticeListRequest, String?)]()
        useCase.handler = { request, keyword in
            requests.append((request, keyword)); return listPage("notice")
        }
        let model = StaffNoticeViewModel(container: listContainer(useCase), errorHandler: ErrorHandler())
        model.applyUserContext(memberRoleRawValue: role.rawValue, schoolId: "5", gisuId: "3")
        await model.fetchNotices()
        await model.searchNotices(keyword: "중앙")
        #expect(requests.count == 2)
        #expect(requests.allSatisfy { $0.0.schoolId == nil })
        model.selectScope(.school)
        await Task.yield()
        await model.searchNotices(keyword: "교내")
        #expect(requests.last?.0.schoolId == "5")
        #expect(requests.last?.1 == "교내")
        await model.loadNextPageIfNeeded(currentItem: model.noticeItems.value!.last!)
        #expect(requests.last?.0.page == 1)
        #expect(requests.last?.0.schoolId == "5")
        #expect(requests.last?.1 == "교내")
    }

    @Test("운영진 특정 기수는 역매핑하며 전체·알 수 없는 기수를 구분한다")
    func staffGenerations() async {
        let useCase = ListUseCase()
        useCase.handler = { _, _ in NoticePage(
            items: [listItem("specific"), listItem("all", gisuId: "0"),
                    listItem("unknown", gisuId: "999")], hasNext: false, totalElements: "3"
        ) }
        let model = StaffNoticeViewModel(container: listContainer(useCase), errorHandler: ErrorHandler())
        model.applyUserContext(memberRoleRawValue: ManagementTeam.schoolPresident.rawValue,
                               schoolId: "5", gisuId: "3")
        await model.fetchNotices()
        let items = model.noticeItems.value ?? []
        #expect(items.map(\.generation) == ["11", "0", ""])
        #expect(items.map(\.targetsAllGenerations) == [false, true, false])
        #expect(items.first?.targetGisuId == "3")
    }

    @Test("이전 첫 페이지와 다음 페이지의 늦은 응답이 최신 검색을 덮어쓰지 않는다",
          arguments: [0, 1], [false, true])
    func staleResponses(page: Int, fails: Bool) async throws {
        let useCase = ListUseCase()
        var pending: CheckedContinuation<NoticePage, Error>?
        var requests = [(NoticeListRequest, String?)]()
        useCase.handler = { request, keyword in
            requests.append((request, keyword))
            if keyword == nil {
                return try await withCheckedThrowingContinuation { pending = $0 }
            }
            return listPage("fresh-\(request.page)", hasNext: request.page == 0)
        }
        let model = try model(useCase)
        model.pagingState.applySuccess(page: 0, hasNextPage: true)
        model.noticeItems = .loaded([listItem("initial")])
        let oldTask = Task { await model.fetchNotices(page: page) }
        while pending == nil { await Task.yield() }
        model.currentState = GenerationFilterState(mainFilter: .branch("과거 지부"))
        await model.searchNotices(keyword: "최신")
        if fails {
            pending?.resume(throwing: StubError.unused)
        } else {
            pending?.resume(returning: listPage("stale", hasNext: false))
        }
        await oldTask.value
        #expect(model.noticeItems.value?.map(\.noticeId) == ["fresh-0"])
        #expect(model.pagingState.hasNextPage)
        await model.loadNextPageIfNeeded(currentItem: model.noticeItems.value!.last!)
        #expect(model.noticeItems.value?.map(\.noticeId) == ["fresh-0", "fresh-1"])
        #expect(requests.last?.0.page == 1)
        #expect(requests.last?.1 == "최신")
        #expect(requests.last?.0.chapterId == "old-chapter")
    }

    @Test("운영진 첫 조회 중 교내 범위로 전환해도 중앙 응답은 반영하지 않는다")
    func staleStaffScope() async {
        let useCase = ListUseCase()
        var pending: CheckedContinuation<NoticePage, Error>?
        useCase.handler = { request, _ in
            if request.schoolId == nil {
                return try await withCheckedThrowingContinuation { pending = $0 }
            }
            return listPage("school", hasNext: false)
        }
        let model = StaffNoticeViewModel(container: listContainer(useCase), errorHandler: ErrorHandler())
        model.applyUserContext(memberRoleRawValue: ManagementTeam.schoolPresident.rawValue,
                               schoolId: "5", gisuId: "3")
        let oldTask = Task { await model.fetchNotices() }
        while pending == nil { await Task.yield() }
        model.selectScope(.school)
        while model.noticeItems.value?.first?.noticeId != "school" { await Task.yield() }
        pending?.resume(returning: listPage("central", hasNext: true))
        await oldTask.value
        #expect(model.noticeItems.value?.map(\.noticeId) == ["school"])
        #expect(!model.pagingState.hasNextPage)
    }

}
#endif
