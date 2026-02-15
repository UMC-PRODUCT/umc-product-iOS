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
            VStack(spacing: DefaultSpacing.spacing32) {
                CommunityPostCard(
                    model: vm.postItem,
                    onLikeTapped: {
                        await vm.toggleLike()
                    },
                    onScrapTapped: {
                        await vm.toggleScrap()
                    }
                )

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
            ToolBarCollection.ToolbarTrailingMenu(actions: [
                .init(title: "수정하기", icon: "pencil") {
                    // TODO: 수정모드
                    pathStore.communityPath.append(.community(.post))
                },
                .init(title: "삭제하기", icon: "trash", role: .destructive) {
                    Task {
                        await vm.deletePost()
                    }
                }
            ])
        }
    }

    // MARK: - Comment

    private func commentSection(_ comments: [CommunityCommentModel]) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            Text("댓글 \(comments.count)개")
                .appFont(.subheadline, color: .grey600)

            ForEach(comments) { comment in
                CommunityCommentItem(model: comment)
                    .equatable()
            }
        }
    }
}
