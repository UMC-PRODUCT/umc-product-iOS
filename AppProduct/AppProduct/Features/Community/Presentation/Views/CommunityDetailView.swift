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
            VStack(spacing: DefaultSpacing.spacing24) {
                TopSection
                Divider()
                MidSection
                Divider()
                BottomSection
            }
            .padding(Constant.mainPadding)
        }
        .navigation(naviTitle: .communityDetail, displayMode: .inline)
    }

    // MARK: - Top

    private var TopSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            TagSection
            Text(vm.postItem.title)
                .appFont(.title1Emphasis)
            ProfileSection
        }
    }

    private var TagSection: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            CommunityTagItem(title: vm.postItem.category.text)
        }
    }

    private var ProfileSection: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            // 프로필 이미지
            if vm.postItem.profileImage != nil {
                // !!! - url 이미지 처리
                Image(systemName: "heart")
            } else {
                Text(vm.postItem.userName.prefix(1))
                    .appFont(.body, color: .grey500)
                    .frame(width: Constant.profileSize.width, height: Constant.profileSize.height)
                    .background(.grey100, in: Circle())
            }

            Text("\(vm.postItem.userName) • \(vm.postItem.part)")
                .appFont(.body)

            Spacer()

            Text(vm.postItem.createdAt)
                .appFont(.subheadline, color: .grey600)
        }
    }

    // MARK: - Mid

    private var MidSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing32) {
            Text(vm.postItem.content)
                .appFont(.body)

            HStack(spacing: DefaultSpacing.spacing12) {
                CommunityLikeButton(count: vm.postItem.likeCount)
                CommentSection
            }
        }
    }

    private var CommentSection: some View {
        HStack(spacing: DefaultSpacing.spacing4) {
            Image(systemName: "bubble")
            Text("댓글")
            Text(String(vm.postItem.commentCount))
        }
        .appFont(.subheadline, color: .grey600)
    }

    // MARK: - Bottom

    private var BottomSection: some View {
        VStack(spacing: DefaultSpacing.spacing16) {
            ForEach(vm.comments) { comment in
                CommunityCommentItem(model: comment)
            }
        }
    }
}
