//
//  CommunityDetailViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/20/26.
//

import Foundation

@Observable
class CommunityDetailViewModel {
    // MARK: - Property
    
    private let useCaseProvider: CommunityUseCaseProviding
    private let errorHandler: ErrorHandler

    private(set) var postItem: CommunityItemModel
    private(set) var comments: Loadable<[CommunityCommentModel]> = .idle
    private(set) var deletePostState: Loadable<Bool> = .idle
    private(set) var deleteCommentState: Loadable<Bool> = .idle
    private(set) var scrapState: Loadable<Bool> = .idle
    private(set) var likeState: Loadable<Bool> = .idle
    private(set) var postCommentState: Loadable<Bool> = .idle

    // MARK: - Init

    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        postItem: CommunityItemModel
    ) {
        self.useCaseProvider = container.resolve(CommunityUseCaseProviding.self)
        self.errorHandler = errorHandler
        self.postItem = postItem
    }

    // MARK: - Function

    /// 댓글 목록 조회
    @MainActor
    func fetchComments() async {
        comments = .loading

        do {
            let fetchedComments = try await useCaseProvider.fetchCommentUseCase.execute(postId: postItem.postId)
            comments = .loaded(fetchedComments)
        } catch let error as DomainError {
            comments = .failed(.domain(error))
        } catch {
            comments = .failed(.unknown(message: error.localizedDescription))
        }
    }

    /// 게시글 삭제
    @MainActor
    func deletePost() async {
        deletePostState = .loading

        do {
            try await useCaseProvider.deletePostUseCase.execute(postId: postItem.postId)
            deletePostState = .loaded(true)
        } catch {
            deletePostState = .idle
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "deletePost",
                retryAction: { [weak self] in
                    await self?.deletePost()
                }
            ))
        }
    }

    /// 댓글 삭제
    @MainActor
    func deleteComment(commentId: Int) async {
        deleteCommentState = .loading

        do {
            try await useCaseProvider.deleteCommentUseCase.execute(
                postId: postItem.postId,
                commentId: commentId
            )
            deleteCommentState = .loaded(true)
            // 댓글 삭제 후 목록 새로고침
            await fetchComments()
        } catch {
            deleteCommentState = .idle
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "deleteComment",
                retryAction: { [weak self] in
                    await self?.deleteComment(commentId: commentId)
                }
            ))
        }
    }

    /// 게시글 스크랩
    @MainActor
    func toggleScrap() async {
        scrapState = .loading

        do {
            try await useCaseProvider.postScrapUseCase.execute(postId: postItem.postId)
            scrapState = .loaded(true)
            // TODO: postItem의 스크랩 상태 업데이트
        } catch {
            scrapState = .idle
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "toggleScrap",
                retryAction: { [weak self] in
                    await self?.toggleScrap()
                }
            ))
        }
    }

    /// 게시글 좋아요
    @MainActor
    func toggleLike() async {
        likeState = .loading

        do {
            try await useCaseProvider.postLikeUseCase.execute(postId: postItem.postId)
            likeState = .loaded(true)
            // TODO: postItem의 좋아요 상태 업데이트
        } catch {
            likeState = .idle
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "toggleLike",
                retryAction: { [weak self] in
                    await self?.toggleLike()
                }
            ))
        }
    }

    /// 댓글 작성
    @MainActor
    func postComment(content: String, parentId: Int) async {
        postCommentState = .loading

        let request = PostCommentRequest(content: content, parentId: parentId)

        do {
            try await useCaseProvider.postCommentUseCase.execute(
                postId: postItem.postId,
                request: request
            )
            postCommentState = .loaded(true)
            // 댓글 작성 후 목록 새로고침
            await fetchComments()
        } catch {
            postCommentState = .idle
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "postComment",
                retryAction: { [weak self] in
                    await self?.postComment(content: content, parentId: parentId)
                }
            ))
        }
    }

    /// 게시글 상세 새로고침 (상세 조회 API 사용)
    @MainActor
    func refreshPostDetail() async {
        do {
            let updatedPost = try await useCaseProvider.fetchPostDetailUseCase.execute(postId: postItem.postId)
            postItem = updatedPost
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "refreshPostDetail",
                retryAction: { [weak self] in
                    await self?.refreshPostDetail()
                }
            ))
        }
    }
}
