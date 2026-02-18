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
    private let authorizationUseCase: AuthorizationUseCaseProtocol
    private let errorHandler: ErrorHandler
    private let postId: Int

    private(set) var postItem: CommunityItemModel?
    private(set) var comments: Loadable<[CommunityCommentModel]> = .idle
    private(set) var postDetailState: Loadable<CommunityItemModel> = .idle
    private(set) var isDeleting: Bool = false
    private(set) var isDeletingComment: Bool = false
    private(set) var isScrapToggling: Bool = false
    private(set) var isLikeToggling: Bool = false
    private(set) var isPostingComment: Bool = false
    private(set) var commentDeletePermissions: [Int: Bool] = [:]
    private(set) var isPermissionsLoaded: Bool = false

    var commentText: String = ""

    // MARK: - Init

    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        postId: Int
    ) {
        self.useCaseProvider = container.resolve(CommunityUseCaseProviding.self)
        self.authorizationUseCase = container.resolve(AuthorizationUseCaseProtocol.self)
        self.errorHandler = errorHandler
        self.postId = postId
    }

    // MARK: - Function

    /// 게시글 상세 조회
    @MainActor
    func fetchPostDetail() async {
        postDetailState = .loading

        do {
            let detail = try await useCaseProvider.fetchPostDetailUseCase.execute(postId: postId)
            postItem = detail
            postDetailState = .loaded(detail)
        } catch let error as AppError {
            postDetailState = .failed(error)
        } catch {
            postDetailState = .failed(.unknown(message: error.localizedDescription))
        }
    }

    /// 댓글 목록 조회
    @MainActor
    func fetchComments() async {
        comments = .loading

        #if DEBUG
        if let debugState = CommunityDebugState.fromLaunchArgument() {
            switch debugState {
            case .loading:
                comments = .loading
            case .failed:
                comments = .failed(.unknown(message: "댓글을 불러오지 못했습니다."))
            case .loaded, .loadedAll, .loadedQuestion, .loadedLightning:
                comments = .loaded(Self.debugComments(for: postId))
            }
            return
        }
        #endif

        do {
            let fetchedComments = try await useCaseProvider.fetchCommentUseCase.execute(postId: postId)
            comments = .loaded(fetchedComments)

            // 댓글 권한 조회
            await fetchCommentPermissions(for: fetchedComments)
        } catch let error as AppError {
            comments = .failed(error)
        } catch {
            comments = .failed(.unknown(message: error.localizedDescription))
        }
    }

    /// 댓글 권한 조회
    @MainActor
    private func fetchCommentPermissions(for comments: [CommunityCommentModel]) async {
        isPermissionsLoaded = false

        // 모든 댓글에 대한 권한을 병렬로 조회
        await withTaskGroup(of: (Int, Bool).self) { group in
            for comment in comments {
                group.addTask { [weak self] in
                    guard let self = self else { return (comment.commentId, false) }
                    do {
                        let permission = try await self.authorizationUseCase.getResourcePermission(
                            resourceType: .comment,
                            resourceId: comment.commentId
                        )
                        let canDelete = await permission.has(.delete)
                        return (comment.commentId, canDelete)
                    } catch {
                        return (comment.commentId, false)
                    }
                }
            }

            for await (commentId, canDelete) in group {
                commentDeletePermissions[commentId] = canDelete
            }
        }

        isPermissionsLoaded = true
    }

    /// 댓글 삭제 권한 확인
    func canDeleteComment(commentId: Int) -> Bool {
        let result = commentDeletePermissions[commentId] ?? false
        return result
    }

    /// 게시글 삭제
    @MainActor
    func deletePost() async -> Bool {
        isDeleting = true

        do {
            try await useCaseProvider.deletePostUseCase.execute(postId: postItem?.postId ?? 0)
            isDeleting = false
            return true
        } catch {
            isDeleting = false
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "deletePost",
                retryAction: { [weak self] in
                    await self?.deletePost()
                }
            ))
            return false
        }
    }

    /// 댓글 삭제
    @MainActor
    func deleteComment(commentId: Int) async {
        isDeletingComment = true

        do {
            try await useCaseProvider.deleteCommentUseCase.execute(
                postId: postItem?.postId ?? 0,
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
        let previousScrapState = postItem?.isScrapped ?? false
        let previousScrapCount = postItem?.scrapCount ?? 0
        postItem?.isScrapped.toggle()
        postItem?.scrapCount += postItem?.isScrapped ?? false ? 1 : -1

        do {
            try await useCaseProvider.postScrapUseCase.execute(postId: postItem?.postId ?? 0)
            isScrapToggling = false
        } catch {
            // 실패 시 이전 상태로 롤백
            postItem?.isScrapped = previousScrapState
            postItem?.scrapCount = previousScrapCount
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
        let previousLikeState = postItem?.isLiked ?? false
        let previousLikeCount = postItem?.likeCount ?? 0
        postItem?.isLiked.toggle()
        postItem?.likeCount += postItem?.isLiked ?? false ? 1 : -1

        do {
            try await useCaseProvider.postLikeUseCase.execute(postId: postItem?.postId ?? 0)
            isLikeToggling = false
        } catch {
            // 실패 시 이전 상태로 롤백
            postItem?.isLiked = previousLikeState
            postItem?.likeCount = previousLikeCount
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
                postId: postItem?.postId ?? 0,
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
            let updatedPost = try await useCaseProvider.fetchPostDetailUseCase.execute(postId: postItem?.postId ?? 0)
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
            try await useCaseProvider.reportPostUseCase.execute(postId: postItem?.postId ?? 0)
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

    #if DEBUG
    private static func debugComments(for postId: Int) -> [CommunityCommentModel] {
        switch postId {
        case 1001:
            return [
                CommunityCommentModel(
                    commentId: 50001,
                    userId: 7771,
                    profileImage: nil,
                    userName: "박서연",
                    content: "path 배열을 enum으로 만들고 `navigationDestination`을 타입별로 분리하면 관리가 훨씬 쉬워요.",
                    createdAt: .now.addingTimeInterval(-180),
                    isAuthor: false
                ),
                CommunityCommentModel(
                    commentId: 50002,
                    userId: 7772,
                    profileImage: nil,
                    userName: "김미주",
                    content: "로그인 플로우처럼 루트 전환이 필요한 경우엔 라우터를 중앙에서 들고 가는 방식이 안정적이었습니다.",
                    createdAt: .now.addingTimeInterval(-540),
                    isAuthor: true
                ),
                CommunityCommentModel(
                    commentId: 50003,
                    userId: 7773,
                    profileImage: nil,
                    userName: "정다은",
                    content: "deep link로 진입할 거면 path 복원 로직까지 같이 설계해두는 걸 추천해요.",
                    createdAt: .now.addingTimeInterval(-1100),
                    isAuthor: false
                )
            ]
        case 1002:
            return [
                CommunityCommentModel(
                    commentId: 51001,
                    userId: 7811,
                    profileImage: nil,
                    userName: "윤서준",
                    content: "저 참여 가능해요. 오픈채팅 들어갔습니다!",
                    createdAt: .now.addingTimeInterval(-240),
                    isAuthor: false
                ),
                CommunityCommentModel(
                    commentId: 51002,
                    userId: 7812,
                    profileImage: nil,
                    userName: "한지민",
                    content: "혹시 장소 상세 주소 공유 가능할까요?",
                    createdAt: .now.addingTimeInterval(-900),
                    isAuthor: false
                )
            ]
        default:
            return [
                CommunityCommentModel(
                    commentId: 52001,
                    userId: 7901,
                    profileImage: nil,
                    userName: "이민수",
                    content: "좋은 글 감사합니다!",
                    createdAt: .now.addingTimeInterval(-300),
                    isAuthor: false
                ),
                CommunityCommentModel(
                    commentId: 52002,
                    userId: 7902,
                    profileImage: nil,
                    userName: "최유진",
                    content: "실무에서도 바로 써볼 수 있는 내용이네요.",
                    createdAt: .now.addingTimeInterval(-840),
                    isAuthor: false
                )
            ]
        }
    }
    #endif
}
