//
//  CommunityDetailView.swift
//  AppProduct
//
//  Created by 김미주 on 1/19/26.
//

import SwiftUI

struct CommunityDetailView: View {
    // MARK: - Properties

    @State var vm: CommunityDetailViewModel

    // MARK: - Init

    init(postItem: CommunityItemModel) {
        self._vm = .init(wrappedValue: .init(postItem: postItem))
    }

    private enum Constant {
        static let mainPadding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let profileSize: CGSize = .init(width: 40, height: 40)
        static let commentPadding: EdgeInsets = .init(top: 16, leading: 0, bottom: 0, trailing: 0)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: DefaultSpacing.spacing32) {
                CommunityPostCard(model: vm.postItem)

                Group {
                    switch vm.comments {
                    case .idle:
                        Color.clear.task {
                            print("hello")
                        }
                    case .loading:
                        // !!! - 로딩 뷰 - 소피
                        ProgressView()
                    case .loaded(let comments):
                        commentSection(comments)
                    case .failed:
                        Color.clear
                    }
                }
            }
            .padding(Constant.mainPadding)
        }
        .navigation(naviTitle: .communityDetail, displayMode: .inline)
    }

    // MARK: - Comment

    private func commentSection(_ comments: [CommunityCommentModel]) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            Text("댓글 \(vm.postItem.commentCount)개")
                .appFont(.subheadline, color: .grey600)

            ForEach(comments) { comment in
                CommunityCommentItem(model: comment)
                    .equatable()
            }
        }
    }
}

#Preview {
    NavigationStack {
        CommunityDetailView(postItem: .init(userId: 1, category: .question, title: "React Hook 질문 있습니다", content: "useEffect 의존성 배열 관련해서 질문이 있습니다...", profileImage: nil, userName: "이코딩", part: "iOS", createdAt: "10분 전", likeCount: 5, commentCount: 2))
    }
}
