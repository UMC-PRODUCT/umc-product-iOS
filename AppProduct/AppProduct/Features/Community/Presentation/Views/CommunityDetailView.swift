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
    @State private var isCommentInputExpanded: Bool = false
    @State private var isCommentInputHidden: Bool = true
    @FocusState private var isCommentFieldFocused: Bool
    @Environment(\.di) private var di
    @Environment(ErrorHandler.self) var errorHandler

    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    private enum Constant {
        static let mainPadding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let postSectionSpacing: CGFloat = DefaultSpacing.spacing12
        static let contentSectionSpacing: CGFloat = DefaultSpacing.spacing32
        static let commentsSectionSpacing: CGFloat = DefaultSpacing.spacing16
        static let commentInputActionRowSpacing: CGFloat = DefaultSpacing.spacing8
        static let textFieldMinHeight: CGFloat = 36
        static let textFieldPadding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let sendButtonSize: CGSize = .init(width: 42, height: 42)
        static let commentLoadingMessage: String = "댓글을 불러오는 중입니다..."
        static let commentsCountTitle: String = "댓글 %d개"
        static let commentLoadFailedTitle: String = "댓글을 불러오지 못했어요"
        static let commentLoadFailedDescription: String = "댓글을 불러오지 못했습니다.\n잠시 후 다시 시도해주세요."
        static let collapsedButtonSize: CGFloat = 64
        static let inputHorizontalPadding: CGFloat = 20
        static let inputBottomOffset: CGFloat = 10
        static let commentInputAnimation: Animation = .easeInOut(duration: 0.2)
        static let commentSectionBottomSpacing: CGFloat = 6
        static let commentInputBottomPadding: CGFloat = 6
        static let collapsedButtonFontSize: CGFloat = 22
        static let commentTextFieldHorizontalPadding: CGFloat = 14
        static let commentTextFieldVerticalPadding: CGFloat = 10
        static let commentTextLineLimit: ClosedRange<Int> = 1...4
        static let commentPrompt: String = "댓글 추가"
        static let sendButtonIconSize: CGFloat = 17
        static let inputSectionSpacing: CGFloat = 24
        static let sendButtonActiveColor: Color = .indigo500
        static let sendButtonDisabledColor: Color = .grey200
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
        rootContent
        .navigation(naviTitle: .communityDetail, displayMode: .inline)
        .task {
            await vm.fetchPostDetail()
            await vm.fetchComments()
        }
        .onChange(of: pathStore.communityPath.count) { oldCount, newCount in
            if newCount < oldCount {
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3초
                    await vm.fetchPostDetail()
                    await vm.fetchComments()
                }
            }
        }
        .toolbar {
            if let postItem = vm.postItem {
                ToolBarCollection.ToolbarTrailingMenu(actions: toolbarActions(for: postItem))
            }
        }
        .alertPrompt(item: $vm.alertPrompt)
    }

    @ViewBuilder
    private var rootContent: some View {
        switch vm.postDetailState {
        case .idle, .loading:
            Progress(message: Constant.loadingMessage, size: .regular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            detailContent()
        case .failed:
            postDetailFailedContent()
        }
    }

    @ViewBuilder
    private func detailContent() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constant.contentSectionSpacing) {
                postSection
                commentStateSection
            }
            .padding(Constant.mainPadding)
        }
        .onScrollPhaseChange { _, newPhase in handleScrollPhaseChange(newPhase) }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaBar(edge: .bottom, alignment: .trailing, spacing: Constant.inputSectionSpacing) {
            commentInputInset
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
        vm.alertPrompt = AlertPrompt(
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
        vm.alertPrompt = AlertPrompt(
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

    private var normalizedCommentText: String {
        vm.commentText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSendComment: Bool {
        !normalizedCommentText.isEmpty && !vm.isPostingComment
    }

    private func commentSection(_ comments: [CommunityCommentModel]) -> some View {
        VStack(alignment: .leading, spacing: Constant.commentsSectionSpacing) {
            Text(String(format: Constant.commentsCountTitle, comments.count))
                .appFont(.subheadline, color: .grey600)

            ForEach(comments) { comment in
                commentItemView(comment)
            }
        }
    }

    private var postSection: some View {
        Group {
            if let postItem = vm.postItem {
                VStack(spacing: Constant.postSectionSpacing) {
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
            }
        }
    }

    @ViewBuilder
    private var commentStateSection: some View {
        switch vm.comments {
        case .idle, .loading:
            commentLoadingIndicator
        case .loaded(let comments):
            commentSection(comments)
        case .failed:
            commentFailedContent()
        }
    }

    @ViewBuilder
    private var commentInputInset: some View {
        if !isCommentInputHidden {
            commentInputSection
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            collapsedCommentInputButton
                .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .trailing)))
        }
    }

    private func commentItemView(_ comment: CommunityCommentModel) -> some View {
        let canDelete = vm.canDeleteComment(commentId: comment.commentId)
        return CommunityCommentItem(
            model: comment,
            canDelete: canDelete,
            onDeleteTapped: {
                await vm.deleteComment(commentId: comment.commentId)
            },
            onReportTapped: {
                await vm.reportComment(commentId: comment.commentId)
            }
        )
    }

    private func handleScrollPhaseChange(_ phase: ScrollPhase) {
        if phase == .idle {
            guard isCommentInputExpanded else { return }
            setCommentInputVisibility(hidden: false, expanded: true, focused: isCommentFieldFocused)
            return
        }
        hideCommentInputByScroll()
    }
    
    /// Failed - 데이터 로드 실패
    /// 게시글 상세 로드 실패
    private func postDetailFailedContent() -> some View {
        RetryContentUnavailableView(
            title: Constant.failedTitle,
            systemImage: Constant.failedSystemImage,
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
            title: Constant.commentLoadFailedTitle,
            systemImage: Constant.failedSystemImage,
            description: Constant.commentLoadFailedDescription,
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
        VStack(spacing: Constant.commentSectionBottomSpacing) {
            commentTextEditor

            commentInputActionRow
                .padding(.horizontal, Constant.textFieldPadding.leading)
                .padding(.bottom, Constant.commentInputBottomPadding)
        }
        .background(.thinMaterial, in: .rect(cornerRadius: DefaultConstant.cornerRadius))
        .glassEffect(.regular, in: .rect(cornerRadius: DefaultConstant.cornerRadius))
        .padding(.horizontal, Constant.inputHorizontalPadding)
        .padding(.bottom, Constant.inputBottomOffset)
    }

    private var collapsedCommentInputButton: some View {
        Button {
            setCommentInputVisibility(hidden: false, expanded: true, focused: true)
        } label: {
            Image(systemName: "plus.bubble")
                .font(.system(size: Constant.collapsedButtonFontSize, weight: .semibold))
                .foregroundStyle(.grey900)
                .frame(width: Constant.collapsedButtonSize, height: Constant.collapsedButtonSize)
                .background {
                    Circle().fill(.clear)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
        }
        .padding(.horizontal, Constant.inputHorizontalPadding)
        .padding(.bottom, Constant.inputBottomOffset)
    }

    private var commentTextEditor: some View {
        ZStack(alignment: .topLeading) {
            TextField(
                "",
                text: $vm.commentText,
                axis: .vertical
            )
            .focused($isCommentFieldFocused)
            .appFont(.body)
            .lineLimit(Constant.commentTextLineLimit)
            .padding(.horizontal, Constant.commentTextFieldHorizontalPadding)
            .padding(.vertical, Constant.commentTextFieldVerticalPadding)
            .frame(minHeight: Constant.textFieldMinHeight, alignment: .topLeading)

            if vm.commentText.isEmpty && !isCommentFieldFocused {
                Text(Constant.commentPrompt)
                    .appFont(.body, color: .grey400)
                    .padding(.horizontal, Constant.commentTextFieldHorizontalPadding)
                    .padding(.vertical, Constant.commentTextFieldVerticalPadding)
                    .allowsHitTesting(false)
            }
        }
    }

    private var commentLoadingIndicator: some View {
        Progress(message: Constant.commentLoadingMessage, size: .regular)
    }

    private var commentInputActionRow: some View {
        HStack(spacing: Constant.commentInputActionRowSpacing) {
            Spacer()

            Button {
                Task {
                    await sendComment()
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: Constant.sendButtonIconSize, weight: .semibold))
                    .foregroundStyle(canSendComment ? .white : .grey400)
            }
            .frame(width: Constant.sendButtonSize.width, height: Constant.sendButtonSize.height)
            .disabled(!canSendComment)
            .buttonBorderShape(.circle)
            .background(
                Circle()
                    .fill(canSendComment ? Constant.sendButtonActiveColor : Constant.sendButtonDisabledColor)
            )
        }
    }

    // MARK: - Actions

    private func sendComment() async {
        let content = normalizedCommentText
        guard !content.isEmpty else { return }

        vm.commentText = ""
        await vm.postComment(content: content, parentId: 0)
        closeCommentInput()
    }

    private func hideCommentInputByScroll() {
        guard !isCommentInputHidden else { return }
        setCommentInputVisibility(hidden: true, expanded: false, focused: false)
    }

    private func closeCommentInput() {
        setCommentInputVisibility(hidden: true, expanded: false, focused: false)
    }

    private func setCommentInputVisibility(hidden: Bool, expanded: Bool, focused: Bool) {
        withAnimation(Constant.commentInputAnimation) {
            isCommentInputHidden = hidden
            isCommentInputExpanded = expanded
        }
        isCommentFieldFocused = focused
    }
}
