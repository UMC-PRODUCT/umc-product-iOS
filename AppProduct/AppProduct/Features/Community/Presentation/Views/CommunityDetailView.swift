//
//  CommunityDetailView.swift
//  AppProduct
//
//  Created by 김미주 on 1/19/26.
//

import SwiftUI

struct CommunityDetailView: View {
    // MARK: - Properties

    @Environment(\.di) private var di
    @State var viewModel: CommunityDetailViewModel?
    let postItem: CommunityItemModel
    
    private var communityProvider: CommunityUseCaseProviding {
        di.resolve(UsecaseProviding.self).community
    }
    
    private enum Constant {
        static let mainPadding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let profileSize: CGSize = .init(width: 40, height: 40)
    }
    
    // MARK: - Init
    init(postItem: CommunityItemModel) {
        self.postItem = postItem
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: DefaultSpacing.spacing32) {
                if let vm = viewModel {
                    CommunityPostCard(model: vm.postItem)

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
                } else {
                    ProgressView()
                }
            }
            .padding(Constant.mainPadding)
        }
        .navigation(naviTitle: .communityDetail, displayMode: .inline)
        .task {
            if viewModel == nil {
                viewModel = CommunityDetailViewModel(
                    fetchCommentsUseCase: communityProvider.fetchCommentUseCase,
                    postItem: postItem
                )
            }
            await viewModel?.fetchComments()
        }
        .toolbar {
            if viewModel == nil {
                ToolBarCollection.ToolbarTrailingMenu(actions: [
                    .init(title: "수정하기", icon: "pencil") {
                        // TODO: 수정 API
                    },
                    .init(title: "삭제하기", icon: "trash", role: .destructive) {
                        // TODO: 삭제 API
                    }
                ])
            }
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
