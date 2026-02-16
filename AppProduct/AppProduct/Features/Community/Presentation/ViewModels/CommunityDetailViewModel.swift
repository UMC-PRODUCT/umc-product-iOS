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
    private(set) var postDetailState: Loadable<CommunityItemModel> = .idle
    private(set) var isDeleting: Bool = false
    private(set) var isDeletingComment: Bool = false
    private(set) var isScrapToggling: Bool = false
    private(set) var isLikeToggling: Bool = false
    private(set) var isPostingComment: Bool = false

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
        } catch let error as AppError {
            comments = .failed(error)
        } catch {
            comments = .failed(.unknown(message: error.localizedDescription))
        }
    }

    /// 게시글 삭제
    @MainActor
    func deletePost() async {
        isDeleting = true

        do {
            try await useCaseProvider.deletePostUseCase.execute(postId: postItem.postId)
            isDeleting = false
        } catch {
            isDeleting = false
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
        isDeletingComment = true

        do {
            try await useCaseProvider.deleteCommentUseCase.execute(
                postId: postItem.postId,
                commentId: commentId
            )
            isDeletingComment = false
            // 댓글 삭제 후 목록 새로고침
            await fetchComments()
        } catch {
            isDeletingComment = false
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
        guard !isScrapToggling else { return }
        isScrapToggling = true

        // 낙관적 업데이트
        let previousScrapState = postItem.isScrapped
        let previousScrapCount = postItem.scrapCount
        postItem.isScrapped.toggle()
        postItem.scrapCount += postItem.isScrapped ? 1 : -1

        do {
            try await useCaseProvider.postScrapUseCase.execute(postId: postItem.postId)
            isScrapToggling = false
        } catch {
            // 실패 시 이전 상태로 롤백
            postItem.isScrapped = previousScrapState
            postItem.scrapCount = previousScrapCount
            isScrapToggling = false
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
        guard !isLikeToggling else { return }
        isLikeToggling = true

        // 낙관적 업데이트
        let previousLikeState = postItem.isLiked
        let previousLikeCount = postItem.likeCount
        postItem.isLiked.toggle()
        postItem.likeCount += postItem.isLiked ? 1 : -1

        do {
            try await useCaseProvider.postLikeUseCase.execute(postId: postItem.postId)
            isLikeToggling = false
        } catch {
            // 실패 시 이전 상태로 롤백
            postItem.isLiked = previousLikeState
            postItem.likeCount = previousLikeCount
            isLikeToggling = false
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
        guard !isPostingComment else { return }
        isPostingComment = true

        let request = PostCommentRequest(content: content, parentId: parentId)

        do {
            try await useCaseProvider.postCommentUseCase.execute(
                postId: postItem.postId,
                request: request
            )
            isPostingComment = false
            // 댓글 작성 후 목록 새로고침
            await fetchComments()
        } catch {
            isPostingComment = false
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
        postDetailState = .loading

        do {
            let updatedPost = try await useCaseProvider.fetchPostDetailUseCase.execute(postId: postItem.postId)
            postItem = updatedPost
            postDetailState = .loaded(updatedPost)
        } catch let error as AppError {
            postDetailState = .failed(error)
        } catch {
            postDetailState = .failed(.unknown(message: error.localizedDescription))
        }
    }

    /// 게시글 신고
    @MainActor
    func reportPost() async {
        do {
            try await useCaseProvider.reportPostUseCase.execute(postId: postItem.postId)
            // 신고 성공 시 사용자에게 알림 (ErrorHandler 사용)
            errorHandler.handle(
                AppError.domain(.custom(message: "게시글이 신고되었습니다.")),
                context: ErrorContext(
                    feature: "Community",
                    action: "reportPost"
                )
            )
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "reportPost",
                retryAction: { [weak self] in
                    await self?.reportPost()
                }
            ))
        }
    }

    /// 댓글 신고
    @MainActor
    func reportComment(commentId: Int) async {
        do {
            try await useCaseProvider.reportCommentUseCase.execute(commentId: commentId)
            // 신고 성공 시 사용자에게 알림 (ErrorHandler 사용)
            errorHandler.handle(
                AppError.domain(.custom(message: "댓글이 신고되었습니다.")),
                context: ErrorContext(
                    feature: "Community",
                    action: "reportComment"
                )
            )
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "reportComment",
                retryAction: { [weak self] in
                    await self?.reportComment(commentId: commentId)
                }
            ))
        }
    }
}
