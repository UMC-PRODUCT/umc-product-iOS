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
    var item: CommunityItemModel

    // MARK: - Init

    init(item: CommunityItemModel) {
        self._vm = .init(wrappedValue: .init())
        self.item = item
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
            Text(item.title)
                .appFont(.title1Emphasis)
            ProfileSection
        }
    }

    private var TagSection: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            CommunityTagItem(title: item.category.text)
            CommunityTagItem(title: item.tag.text)
        }
    }

    private var ProfileSection: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            // 프로필 이미지
            if item.profileImage != nil {
                item.profileImage
            } else {
                Text(item.userName.prefix(1))
                    .appFont(.body, color: .grey500)
                    .frame(width: Constant.profileSize.width, height: Constant.profileSize.height)
                    .background(.grey100, in: Circle())
            }

            Text("\(item.userName) • \(item.part)")
                .appFont(.body)

            Spacer()

            Text(item.createdAt)
                .appFont(.subheadline, color: .grey600)
        }
    }

    // MARK: - Mid

    private var MidSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing32) {
            Text(item.content)
                .appFont(.body)

            HStack(spacing: DefaultSpacing.spacing12) {
                CommunityLikeButton(count: item.likeCount)
                CommentSection
            }
        }
    }

    private var CommentSection: some View {
        HStack(spacing: DefaultSpacing.spacing4) {
            Image(systemName: "bubble")
            Text("댓글")
            Text(String(item.commentCount))
        }
        .appFont(.subheadline, color: .grey600)
    }

    // MARK: - Bottom

    private var BottomSection: some View {
        ScrollView {
            CommunityCommentItem(model: .init(profileImage: nil, userName: "김애플", content: "저 참여하고 싶습니다! 아직 자리 있나요?", createdAt: "10분 전"))
        }
    }
}

#Preview {
    NavigationStack {
        CommunityDetailView(item: .init(category: .impromptu, tag: .cheerUp, title: "오늘 강남역 카공하실 분?", content: "오후 2시부터 6시까지 강남역 근처 카페에서 각자 할일 하실 분 구합니다! 현재 2명 있어요.", profileImage: nil, userName: "김멋사", part: "iOS", createdAt: "방금 전", likeCount: 2, commentCount: 1))
    }
}
