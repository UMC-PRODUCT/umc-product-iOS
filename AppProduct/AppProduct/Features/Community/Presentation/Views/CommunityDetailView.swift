//
//  CommunityDetailView.swift
//  AppProduct
//
//  Created by 김미주 on 1/19/26.
//

import SwiftUI

struct CommunityDetailView: View {
    // MARK: - Properties

    @State private var vm: CommunityDetailViewModel
    @State private var alertPrompt: AlertPrompt?
    @Environment(\.di) private var di
    @Environment(ErrorHandler.self) var errorHandler

    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    private enum Constant {
        static let mainPadding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let profileSize: CGSize = .init(width: 40, height: 40)
        static let textFieldHeight: CGFloat = 50
        static let textFieldPadding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let sendButtonSize: CGSize = .init(width: 50, height: 50)
        static let bottomPadding: EdgeInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        /// 실패 상태 문구
        static let failedTitle: String = "불러오지 못했어요"
        static let failedSystemImage: String = "exclamationmark.triangle"
        static let failedDescription: String = "게시글을 불러오지 못했습니다.\n잠시 후 다시 시도해주세요."
        /// 재시도 버튼 문구/크기
        static let retryTitle: String = "다시 시도"
        static let retryMinimumWidth: CGFloat = 72
        static let retryMinimumHeight: CGFloat = 20
        /// 로딩 문구
        static let loadingMessage: String = "게시글을 불러오는 중입니다..."
    }

    // MARK: - Init
    init(container: DIContainer,
         errorHandler: ErrorHandler,
         postId: Int
    ) {
        let viewModel = CommunityDetailViewModel(
            container: container, errorHandler: errorHandler, postId: postId
        )
        self._vm = .init(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch vm.postDetailState {
            case .idle, .loading:
                Progress(message: Constant.loadingMessage, size: .regular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let postItem):
                detailContent(postItem: postItem)
            case .failed:
                postDetailFailedContent()
            }
        }
        .navigation(naviTitle: .communityDetail, displayMode: .inline)
        .task {
            await vm.fetchPostDetail()
        }
        .toolbar {
            if let postItem = vm.postItem {
                ToolBarCollection.ToolbarTrailingMenu(actions: toolbarActions(for: postItem))
            }
        }
        .alertPrompt(item: $alertPrompt)
    }

    @ViewBuilder
    private func detailContent(postItem: CommunityItemModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing32) {
                VStack(spacing: DefaultSpacing.spacing12) {
                    CommunityPostCard(
                        model: postItem,
                        onLikeTapped: {
                            await vm.toggleLike()
                        },
                        onScrapTapped: {
                            await vm.toggleScrap()
                        }
                    )

                    if postItem.category == .lighting {
                        CommunityLightningCard(model: postItem)
                    }
                }

                Group {
                    switch vm.comments {
                    case .idle, .loading:
                        Progress(message: "댓글을 불러오는 중입니다...", size: .regular)
                    case .loaded(let comments):
                        commentSection(comments)
                    case .failed:
                        commentFailedContent()
                    }
                }
            }
            .padding(Constant.mainPadding)
        }
        .scrollDismissesKeyboard(.immediately)
        .task {
            await vm.fetchComments()
        }
        .safeAreaInset(edge: .bottom) {
            commentInputSection
        }
    }

    // MARK: - Toolbar Actions

    private func toolbarActions(for postItem: CommunityItemModel) -> [ToolBarCollection.ToolbarTrailingMenu.ActionItem] {
        if postItem.isAuthor {
            // 본인 게시글: 수정/삭제
            return [
                .init(title: "수정하기", icon: "pencil") {
                    pathStore.communityPath.append(.community(.post(editItem: postItem)))
                },
                .init(title: "삭제하기", icon: "trash", role: .destructive) {
                    showDeletePostAlert()
                }
            ]
        } else {
            // 타인 게시글: 신고
            return [
                .init(title: "신고하기", icon: "light.beacon.max.fill", role: .destructive) {
                    showReportPostAlert()
                }
            ]
        }
    }

    // MARK: - Alert Functions

    /// 게시글 삭제 확인 Alert
    private func showDeletePostAlert() {
        alertPrompt = AlertPrompt(
            title: "게시글 삭제",
            message: "게시글을 삭제하시겠습니까?",
            positiveBtnTitle: "삭제",
            positiveBtnAction: {
                Task {
                    await vm.deletePost()
                }
                pathStore.communityPath.removeLast()
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    /// 게시글 신고 확인 Alert
    private func showReportPostAlert() {
        alertPrompt = AlertPrompt(
            title: "게시글 신고",
            message: "이 게시글을 신고하시겠습니까?",
            positiveBtnTitle: "신고",
            positiveBtnAction: {
                Task {
                    await vm.reportPost()
                }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    // MARK: - Comment

    private func commentSection(_ comments: [CommunityCommentModel]) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            Text("댓글 \(comments.count)개")
                .appFont(.subheadline, color: .grey600)

            ForEach(comments) { comment in
                CommunityCommentItem(
                    model: comment,
                    onDeleteTapped: {
                        await vm.deleteComment(commentId: comment.commentId)
                    },
                    onReportTapped: {
                        await vm.reportComment(commentId: comment.commentId)
                    }
                )
                .equatable()
            }
        }
    }
    
    /// Failed - 데이터 로드 실패
    /// 게시글 상세 로드 실패
    private func postDetailFailedContent() -> some View {
        RetryContentUnavailableView(
            title: "불러오지 못했어요",
            systemImage: "exclamationmark.triangle",
            description: Constant.failedDescription,
            retryTitle: Constant.retryTitle,
            isRetrying: vm.postDetailState.isLoading,
            minRetryButtonWidth: Constant.retryMinimumWidth,
            minRetryButtonHeight: Constant.retryMinimumHeight
        ) {
            await vm.fetchPostDetail()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    /// 댓글 로드 실패
    private func commentFailedContent() -> some View {
        RetryContentUnavailableView(
            title: "댓글을 불러오지 못했어요",
            systemImage: "exclamationmark.triangle",
            description: "댓글을 불러오지 못했습니다.\n잠시 후 다시 시도해주세요.",
            retryTitle: Constant.retryTitle,
            isRetrying: vm.comments.isLoading,
            minRetryButtonWidth: Constant.retryMinimumWidth,
            minRetryButtonHeight: Constant.retryMinimumHeight
        ) {
            await vm.fetchComments()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Comment Input

    private var commentInputSection: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            TextField(
                "",
                text: $vm.commentText,
                prompt: Text("댓글을 입력해 주세요."),
                axis: .horizontal
            )
            .appFont(.body)
            .scrollIndicators(.hidden)
            .padding(Constant.textFieldPadding)
            .frame(height: Constant.textFieldHeight)
            .glassEffect()
            
            Button {
                Task {
                    await sendComment()
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(vm.commentText.isEmpty ? .grey400 : .white)
            }
            .padding(.zero)
            .frame(width: Constant.sendButtonSize.width, height: Constant.sendButtonSize.height)
            .disabled(vm.commentText.isEmpty || vm.isPostingComment)
            .buttonBorderShape(.circle)
            .glassEffect(.regular.tint(vm.commentText.isEmpty ? .clear : .indigo500))
        }
        .padding(Constant.bottomPadding)
    }

    // MARK: - Actions

    private func sendComment() async {
        let content = vm.commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        vm.commentText = ""
        await vm.postComment(content: content, parentId: 0)
    }
}
