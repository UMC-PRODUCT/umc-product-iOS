import CoreDI
import CoreDomain
import Foundation
import NoticeDomain
import Testing
import UIKit
import UMCFoundation

@testable import NoticePresentation

private enum Failure: Error { case injected }
private struct GenerationRepository: ChallengerGenRepositoryProtocol {
    func replaceMappings(_ pairs: [(gen: String, gisuId: String)]) throws {}
    func fetchGenGisuIdPairs() throws -> [(gen: String, gisuId: String)] { [] }
}
private final class WriteUseCase: NoticeUseCaseProtocol {
    var createCount = 0
    var voteCount = 0
    var failLinks = false
    var failVote = false
    var persistVoteBeforeFailure = false
    var storedVote: NoticeVote?
    var failImages = false
    var imageUpdates: [[String]] = []
    var detail: NoticeDetail {
        NoticeDetail(
            id: "42", generation: "1", scope: .central, category: .general,
            isMustRead: true, title: "title", content: "body", authorID: "1",
            authorName: "writer", authorImageURL: nil, createdAt: .now, updatedAt: nil,
            targetAudience: .all(generation: "1", scope: .central), hasPermission: true,
            images: [], links: [], vote: storedVote
        )
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
        createCount += 1
        return detail
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
        voteCount += 1
        if persistVoteBeforeFailure {
            storedVote = NoticeVote(
                id: "vote", question: title,
                options: options.enumerated().map {
                    VoteOption(id: String($0.offset), title: $0.element, voteCount: "0")
                }, startDate: startsAt,
                endDate: endsAtExclusive, allowMultipleChoices: allowMultipleChoice,
                isAnonymous: isAnonymous, userVotedOptionIds: []
            )
        }
        if failVote {
            failVote = false
            throw Failure.injected
        }
        return "vote"
    }
    func addLink(noticeId: String, links: [String]) async throws -> NoticeItemModel {
        fatalError("Unexpected call")
    }
    func addImage(noticeId: String, imageIds: [String]) async throws -> NoticeItemModel {
        fatalError("Unexpected call")
    }
    func readNotice(noticeId: String) async throws { fatalError("Unexpected call") }
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
    ) async throws -> NoticeDetail { return detail }
    func updateLinks(
        noticeId: String,
        links: [String]
    ) async throws -> NoticeDetail {
        if failLinks {
            failLinks = false
            throw Failure.injected
        }
        return detail
    }
    func updateImages(
        noticeId: String,
        imageIds: [String]
    ) async throws -> NoticeDetail {
        imageUpdates.append(imageIds)
        if failImages {
            failImages = false
            throw Failure.injected
        }
        return detail
    }
    func getAllNotices(request: NoticeListRequest) async throws -> NoticePage {
        fatalError("Unexpected call")
    }
    func getDetailNotice(noticeId: String) async throws -> NoticeDetail { return detail }
    func getReadStatics(noticeId: String) async throws -> NoticeReadStatics {
        fatalError("Unexpected call")
    }
    func getReadStatusList(
        noticeId: String,
        cursorId: String,
        filterType: String,
        organizationIds: [String],
        status: String
    ) async throws -> NoticeReadStatusPage { fatalError("Unexpected call") }
    func searchNotice(
        keyword: String,
        request: NoticeListRequest
    ) async throws -> NoticePage { fatalError("Unexpected call") }
    func deleteNotice(noticeId: String) async throws { fatalError("Unexpected call") }
    func deleteVote(noticeId: String) async throws { fatalError("Unexpected call") }
}

@Suite("Notice editor write recovery")
@MainActor
struct NoticeEditorWriteTests {
    private func makeEditor(_ useCase: WriteUseCase) -> NoticeEditorViewModel {
        let container = DIContainer()
        container.register(ChallengerGenRepositoryProtocol.self) { GenerationRepository() }
        container.register(NoticeUseCaseProtocol.self) { useCase }
        let editor = NoticeEditorViewModel(container: container)
        editor.title = "title"
        editor.content = "body"
        return editor
    }

    @Test func linkFailureRetriesSameNoticeAndRetainsDraft() async {
        let useCase = WriteUseCase()
        useCase.failLinks = true
        let editor = makeEditor(useCase)
        editor.noticeLinks = [NoticeLinkItem(link: "https://example.com")]
        await editor.createNewNotice()
        #expect(editor.pendingCreatedNotice?.id == "42")
        #expect(editor.title == "title")
        await editor.createNewNotice()
        #expect(useCase.createCount == 1)
        #expect(editor.createState.value?.id == "42")
    }

    @Test func voteFailureRetriesSameNotice() async {
        let useCase = WriteUseCase()
        useCase.failVote = true
        let editor = makeEditor(useCase)
        editor.isVoteConfirmed = true
        editor.voteFormData.title = "vote"
        editor.voteFormData.options = [VoteOptionItem(text: "A"), VoteOptionItem(text: "B")]
        await editor.createNewNotice()
        #expect(editor.pendingCreatedNotice?.id == "42")
        #expect(!editor.isVoteReadOnly)
        await editor.createNewNotice()
        #expect(useCase.createCount == 1)
        #expect(useCase.voteCount == 2)
        #expect(!editor.isEditMode)
    }

    @Test func imageFailureRetriesSameNotice() async {
        let useCase = WriteUseCase()
        useCase.failImages = true
        let editor = makeEditor(useCase)
        let fileId = UUID().uuidString
        editor.noticeImages = [NoticeImageItem(isLoading: false, fileId: fileId)]
        await editor.createNewNotice()
        #expect(editor.pendingCreatedNotice?.id == "42")
        #expect(editor.isTargetLocked)
        #expect(!editor.isEditMode)
        await editor.createNewNotice()
        #expect(useCase.createCount == 1)
        #expect(useCase.imageUpdates == [[fileId], [fileId]])
    }

    @Test func acknowledgedVoteOnServerIsNotCreatedAgain() async {
        let useCase = WriteUseCase()
        useCase.failVote = true
        useCase.persistVoteBeforeFailure = true
        let editor = makeEditor(useCase)
        editor.isVoteConfirmed = true
        editor.voteFormData.title = "vote"
        editor.voteFormData.options = [VoteOptionItem(text: "A"), VoteOptionItem(text: "B")]
        await editor.createNewNotice()
        await editor.createNewNotice()
        #expect(useCase.createCount == 1)
        #expect(useCase.voteCount == 1)
        #expect(editor.createState.value?.id == "42")
    }

    @Test func changedDraftDoesNotSilentlyReplacePublishedVote() async {
        let useCase = WriteUseCase()
        useCase.failVote = true
        useCase.persistVoteBeforeFailure = true
        let editor = makeEditor(useCase)
        editor.isVoteConfirmed = true
        editor.voteFormData.title = "vote"
        editor.voteFormData.options = [VoteOptionItem(text: "A"), VoteOptionItem(text: "B")]
        await editor.createNewNotice()
        editor.voteFormData.title = "changed"
        await editor.createNewNotice()
        #expect(useCase.createCount == 1)
        #expect(useCase.voteCount == 1)
        #expect(editor.createState.value == nil)
        #expect(editor.isVoteReadOnly)
        #expect(editor.voteFormData.title == "changed")
    }

    @Test func repeatedPhotoSelectionStopsAtTen() async {
        let editor = makeEditor(WriteUseCase())
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }
        await editor.didLoadImages(images: Array(repeating: image, count: 9))
        await editor.didLoadImages(images: Array(repeating: image, count: 3))
        #expect(editor.noticeImages.count == 10)
    }

    @Test func replacementKeepsFileUUIDOrder() async throws {
        let editor = makeEditor(WriteUseCase())
        let ids = [UUID().uuidString, UUID().uuidString]
        editor.noticeImages = ids.map { NoticeImageItem(isLoading: false, fileId: $0) }
        let resolved = try await editor.resolveImageIdsForUpdate(noticeId: "42")
        #expect(resolved == ids)
    }

    @Test func rejectsExcessImagesBeforeCreatingNotice() async {
        let useCase = WriteUseCase()
        let editor = makeEditor(useCase)
        editor.noticeImages = (0..<11).map { _ in
            NoticeImageItem(isLoading: false, fileId: UUID().uuidString)
        }
        await editor.createNewNotice()
        #expect(useCase.createCount == 0)
        #expect(editor.noticeImages.count == 11)
    }

    @Test func unresolvedRemoteImageStopsReplacement() async {
        let useCase = WriteUseCase()
        let editor = makeEditor(useCase)
        editor.noticeImages = [
            NoticeImageItem(imageURL: "https://example.com/a", isLoading: false)
        ]
        do {
            _ = try await editor.resolveImageIdsForUpdate(noticeId: "42")
            Issue.record("Expected unresolved image to fail")
        } catch {
            #expect(useCase.imageUpdates.isEmpty)
        }
    }
}
