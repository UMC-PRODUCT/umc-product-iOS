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

    let postItem: CommunityItemModel

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
        static let failedDescription: String = "댓글을 불러오지 못했습니다. 잠시 후 다시 시도해주세요."
        /// 재시도 버튼 문구/크기
        static let retryTitle: String = "다시 시도"
        static let retryMinimumWidth: CGFloat = 72
        static let retryMinimumHeight: CGFloat = 20
    }
    
    // MARK: - Init
    init(container: DIContainer,
         errorHandler: ErrorHandler,
         postItem: CommunityItemModel
    ) {
        self.postItem = postItem
        let viewModel = CommunityDetailViewModel(
            container: container, errorHandler: errorHandler, postItem: postItem
        )
        self._vm = .init(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing32) {
                VStack(spacing: DefaultSpacing.spacing12) {
                    CommunityPostCard(
                        model: vm.postItem,
                        onLikeTapped: {
                            await vm.toggleLike()
                        },
                        onScrapTapped: {
                            await vm.toggleScrap()
                        }
                    )
                    
                    if vm.postItem.category == .lighting {
                        CommunityLightningCard(model: vm.postItem)
                    }
                }

                Group {
                    switch vm.comments {
                    case .idle, .loading:
                        ProgressView("댓글 로딩 중...")
                    case .loaded(let comments):
                        commentSection(comments)
                    case .failed:
                        failedContent()
                    }
                }
            }
            .padding(Constant.mainPadding)
        }
        .scrollDismissesKeyboard(.immediately)
        .navigation(naviTitle: .communityDetail, displayMode: .inline)
        .task {
            await vm.fetchComments()
        }
        .toolbar {
            ToolBarCollection.ToolbarTrailingMenu(actions: toolbarActions)
        }
        .alertPrompt(item: $alertPrompt)
        .safeAreaInset(edge: .bottom) {
            commentInputSection
        }
    }

    // MARK: - Toolbar Actions

    private var toolbarActions: [ToolBarCollection.ToolbarTrailingMenu.ActionItem] {
        if canEditOrDeletePost {
            // 본인 게시글: 수정/삭제
            return [
                .init(title: "수정하기", icon: "pencil") {
                    pathStore.communityPath.append(.community(.post(editItem: vm.postItem)))
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

    private var canEditOrDeletePost: Bool {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--community-force-permission") {
            return true
        }
        #endif
        return postItem.isAuthor
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
    private func failedContent() -> some View {
        RetryContentUnavailableView(
            title: Constant.failedTitle,
            systemImage: Constant.failedSystemImage,
            description: Constant.failedDescription,
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
