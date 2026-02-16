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

                Group {
                    switch vm.comments {
                    case .idle, .loading:
                        ProgressView("댓글 로딩 중...")
                    case .loaded(let comments):
                        commentSection(comments)
                    case .failed(let error):
                        ContentUnavailableView {
                            Label("로딩 실패", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(error.localizedDescription)
                        } actions: {
                            Button("다시 시도") {
                                Task { await vm.fetchComments() }
                            }
                        }
                    }
                }
            }
            .padding(Constant.mainPadding)
        }
        .navigation(naviTitle: .communityDetail, displayMode: .inline)
        .task {
            await vm.fetchComments()
        }
        .toolbar {
            ToolBarCollection.ToolbarTrailingMenu(actions: toolbarActions)
        }
        .alertPrompt(item: $alertPrompt)
    }

    // MARK: - Toolbar Actions

    private var toolbarActions: [ToolBarCollection.ToolbarTrailingMenu.ActionItem] {
        if postItem.isAuthor {
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
}
