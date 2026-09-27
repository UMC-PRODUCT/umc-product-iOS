//
//  NoticeDetailContractTests.swift
//  NoticePresentationTests
//
//  Created by euijjang97 on 9/27/26.
//

import CoreDI
import CoreDomain
import Foundation
import NoticeDomain
import Testing
import UMCFoundation
@testable import NoticePresentation

private struct DetailGenerationRepository: ChallengerGenRepositoryProtocol {
    func replaceMappings(_ pairs: [(gen: String, gisuId: String)]) throws {}
    func fetchGenGisuIdPairs() throws -> [(gen: String, gisuId: String)] { [] }
}

private struct DetailAuthorization: AuthorizationUseCaseProtocol {
    var permissions: Set<AuthorizationPermissionType>
    var fails: Bool
    func getResourcePermission(
        resourceType: AuthorizationResourceType, resourceId: String
    ) async throws -> ResourcePermission {
        if fails { throw URLError(.notConnectedToInternet) }
        return ResourcePermission(
            resourceType: resourceType, resourceId: resourceId,
            grantedPermissions: permissions
        )
    }
}

@MainActor
struct NoticeDetailContractTests {
    private func makeViewModel(
        permissions: Set<AuthorizationPermissionType> = [],
        authorizationFails: Bool = false,
        useCase: NoticeUseCaseProtocol? = nil
    ) -> NoticeDetailViewModel {
        let container = DIContainer()
        container.register(ChallengerGenRepositoryProtocol.self) { DetailGenerationRepository() }
        container.register(AuthorizationUseCaseProtocol.self) {
            DetailAuthorization(permissions: permissions, fails: authorizationFails)
        }
        if let useCase { container.register(NoticeUseCaseProtocol.self) { useCase } }
        return NoticeDetailViewModel(
            container: container, errorHandler: ErrorHandler(),
            model: NoticeDetail(
                id: "1", generation: "0", scope: .central, category: .general,
                isMustRead: false, title: "공지", content: "본문", authorID: "1",
                authorName: "작성자", authorImageURL: nil, createdAt: Date(), updatedAt: nil,
                targetAudience: TargetAudience(
                    generation: "0", scope: .central, parts: [], branches: [], schools: []
                ), hasPermission: true, images: [], links: [], vote: nil
            )
        )
    }

    @Test(arguments: [0.0, 0.5, 1, 50, 100])
    func percentageRate(_ percentage: Double) {
        let model = makeViewModel()
        model.readStatics = NoticeReadStatics(
            totalCount: "200", readCount: "1", unreadCount: "199",
            readRate: String(percentage)
        )
        #expect(model.readRate == percentage / 100)
        let button = NoticeReadStatusButton(
            confirmedCount: 1, totalCount: 200, readRate: model.readRate, action: {}
        )
        let text = percentage.formatted(.number.precision(.fractionLength(0...2)))
        #expect(button.progressText.contains("(\(text)%)"))
        model.applyOptimisticReadStatics()
        #expect(model.readRate == 0.01)
    }

    @Test
    func separateEditDeleteFromManage() async {
        let manager = makeViewModel(permissions: [.write, .manage])
        await manager.fetchNoticePermission()
        #expect(!manager.canEditNotice && !manager.canDeleteNotice)
        let author = makeViewModel(permissions: [.edit, .delete])
        await author.fetchNoticePermission()
        #expect(author.canEditNotice && author.canDeleteNotice)
        let failed = makeViewModel(authorizationFails: true)
        await failed.fetchNoticePermission()
        #expect(!failed.canEditNotice && !failed.canDeleteNotice)
    }

    @Test(arguments: ["0", "11"])
    func centralManagementDoesNotRequireSpecificGeneration(_ generation: String) {
        let audience = TargetAudience(
            generation: generation, scope: .central, parts: [], branches: [], schools: []
        )
        for role in [ManagementTeam.centralOperatingTeamMember, .centralEducationTeamMember] {
            #expect(NoticeReadStatusPermissionEvaluator.canViewReadStatus(
                roles: [role], userChapterId: nil, userSchoolId: nil, targetAudience: audience
            ))
        }
        #expect(!NoticeReadStatusPermissionEvaluator.canViewReadStatus(
            roles: [.challenger], userChapterId: nil, userSchoolId: nil, targetAudience: audience
        ))
    }

    @Test
    func bothTabsCanPaginateWithReversedResponses() async {
        let useCase = DelayedDetailUseCase()
        let model = makeViewModel(useCase: useCase)
        let user = ReadStatusUser(
            id: "1", name: "이름", nickName: "별명", part: "IOS", branch: "", campus: "",
            profileImageURL: nil, isRead: true
        )
        model.readStatusState = .loaded(NoticeReadStatus(
            noticeId: "1", confirmedUsers: [user], unconfirmedUsers: [user]
        ))
        model.hasNextReadPage = true
        model.hasNextUnreadPage = true
        model.readNextCursor = 1
        model.unreadNextCursor = 99
        let readTask = Task { await model.loadMoreReadStatusIfNeeded(currentItem: user) }
        while useCase.continuations["READ"] == nil { await Task.yield() }
        model.switchReadTab(to: .unconfirmed)
        let unreadTask = Task { await model.loadMoreReadStatusIfNeeded(currentItem: user) }
        while useCase.continuations["UNREAD"] == nil { await Task.yield() }
        useCase.continuations["UNREAD"]?.resume(returning: NoticeReadStatusPage(
            users: [user], nextCursor: "100", hasNext: true
        ))
        await unreadTask.value
        useCase.continuations["READ"]?.resume(returning: NoticeReadStatusPage(
            users: [user], nextCursor: "2", hasNext: true
        ))
        await readTask.value
        #expect(model.readStatusState.value?.confirmedUsers.count == 2)
        #expect(model.readStatusState.value?.unconfirmedUsers.count == 2)
        #expect(model.readNextCursor == 2)
        #expect(model.unreadNextCursor == 100)
    }

    @Test(arguments: [false, true], [false, true])
    func delayedPageKeepsItsTabAndIgnoresRefresh(_ reset: Bool, _ reverse: Bool) async {
        let useCase = DelayedDetailUseCase()
        let model = makeViewModel(useCase: useCase)
        let user = ReadStatusUser(
            id: "1", name: "이름", nickName: "별명", part: "IOS", branch: "", campus: "",
            profileImageURL: nil, isRead: true
        )
        model.readStatusState = .loaded(NoticeReadStatus(
            noticeId: "1", confirmedUsers: reverse ? [] : [user],
            unconfirmedUsers: reverse ? [user] : []
        ))
        model.selectedReadTab = reverse ? .unconfirmed : .confirmed
        model.hasNextReadPage = true
        model.hasNextUnreadPage = true
        model.readNextCursor = 1
        model.unreadNextCursor = 99
        let task = Task { await model.loadMoreReadStatusIfNeeded(currentItem: user) }
        while useCase.continuation == nil { await Task.yield() }
        model.switchReadTab(to: reverse ? .confirmed : .unconfirmed)
        if reset { model.resetReadStatusPagination() }
        useCase.continuation?.resume(returning: NoticeReadStatusPage(
            users: [user], nextCursor: "2", hasNext: true
        ))
        await task.value
        let status = model.readStatusState.value
        #expect((reverse ? status?.unconfirmedUsers : status?.confirmedUsers)?.count
            == (reset ? 1 : 2))
        #expect((reverse ? status?.confirmedUsers : status?.unconfirmedUsers)?.isEmpty == true)
        #expect(model.readNextCursor == (reset ? nil : (reverse ? 1 : 2)))
        #expect(model.unreadNextCursor == (reset ? nil : (reverse ? 2 : 99)))
    }
}

private final class DelayedDetailUseCase: NoticeUseCaseProtocol {
    var continuations: [String: CheckedContinuation<NoticeReadStatusPage, Never>] = [:]
    var continuation: CheckedContinuation<NoticeReadStatusPage, Never>? {
        continuations.values.first
    }
    func uploadNoticeAttachmentImage(imageData: Data, fileName: String?) async throws -> String {
        fatalError("Unexpected call")
    }

    func createNotice(
        title: String,
        content: String,
        shouldNotify: Bool,
        targetInfo: NoticeTargetInfo,
        links: [String],
        imageIds: [String]
    ) async throws -> NoticeDetail {
        fatalError("Unexpected call")
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
        fatalError("Unexpected call")
    }

    func addLink(noticeId: String, links: [String]) async throws -> NoticeItemModel {
        fatalError("Unexpected call")
    }

    func addImage(noticeId: String, imageIds: [String]) async throws -> NoticeItemModel {
        fatalError("Unexpected call")
    }

    func readNotice(noticeId: String) async throws {
        fatalError("Unexpected call")
    }

    func submitVoteResponse(noticeId: String, optionIds: [String]) async throws {
        fatalError("Unexpected call")
    }

    func updateVoteResponse(noticeId: String, optionIds: [String]) async throws {
        fatalError("Unexpected call")
    }

    func sendReminder(noticeId: String, targetIds: [String]) async throws {
        fatalError("Unexpected call")
    }

    func updateNotice(
        noticeId: String,
        title: String,
        content: String
    ) async throws -> NoticeDetail {
        fatalError("Unexpected call")
    }

    func updateLinks(
        noticeId: String,
        links: [String]
    ) async throws -> NoticeDetail {
        fatalError("Unexpected call")
    }

    func updateImages(
        noticeId: String,
        imageIds: [String]
    ) async throws -> NoticeDetail {
        fatalError("Unexpected call")
    }

    func getAllNotices(request: NoticeListRequest) async throws -> NoticePage {
        fatalError("Unexpected call")
    }

    func getDetailNotice(noticeId: String) async throws -> NoticeDetail {
        fatalError("Unexpected call")
    }

    func getReadStatics(noticeId: String) async throws -> NoticeReadStatics {
        fatalError("Unexpected call")
    }

    func getReadStatusList(
        noticeId: String,
        cursorId: String,
        filterType: String,
        organizationIds: [String],
        status: String
    ) async throws -> NoticeReadStatusPage {
        await withCheckedContinuation { continuations[status] = $0 }
    }

    func searchNotice(
        keyword: String,
        request: NoticeListRequest
    ) async throws -> NoticePage {
        fatalError("Unexpected call")
    }

    func deleteNotice(noticeId: String) async throws {
        fatalError("Unexpected call")
    }

    func deleteVote(noticeId: String) async throws {
        fatalError("Unexpected call")
    }
}
