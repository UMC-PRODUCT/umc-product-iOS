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

    init() {
        self._vm = .init(wrappedValue: .init())
    }

    private enum Constant {
        static let mainPadding: CGFloat = 16
        static let profileSize: CGSize = .init(width: 40, height: 40)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: DefaultSpacing.spacing24) {
            TopSection
            Divider()
            MidSection
            Divider()
            BottomSection
        }
        .padding(Constant.mainPadding)
        .navigation(naviTitle: .communityDetail, displayMode: .inline)
    }

    // MARK: - Top

    private var TopSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            TagSection
            Text(vm.item.title)
                .appFont(.title1Emphasis)
            ProfileSection
        }
    }

    private var TagSection: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            CommunityTagItem(title: vm.item.category.text)
            CommunityTagItem(title: vm.item.tag.text)
        }
    }

    private var ProfileSection: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            // 프로필 이미지
            if vm.item.profileImage != nil {
                vm.item.profileImage
            } else {
                Text(vm.item.userName.prefix(1))
                    .appFont(.body, color: .grey500)
                    .frame(width: Constant.profileSize.width, height: Constant.profileSize.height)
                    .background(.grey100, in: Circle())
            }

            Text("\(vm.item.userName) • \(vm.item.part)")
                .appFont(.body)

            Spacer()

            Text(vm.item.createdAt)
                .appFont(.subheadline, color: .grey600)
        }
    }

    // MARK: - Mid

    private var MidSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing32) {
            Text(vm.item.content)
                .appFont(.body)

            HStack(spacing: DefaultSpacing.spacing12) {
                CommunityLikeButton(count: vm.item.likeCount)
                CommentSection
            }
        }
    }

    private var CommentSection: some View {
        HStack(spacing: DefaultSpacing.spacing4) {
            Image(systemName: "bubble")
            Text("댓글")
            Text(String(vm.item.commentCount))
        }
        .appFont(.subheadline, color: .grey600)
    }

    // MARK: - Bottom

    private var BottomSection: some View {
        ScrollView {}
    }
}

#Preview {
    NavigationStack {
        CommunityDetailView()
    }
}
