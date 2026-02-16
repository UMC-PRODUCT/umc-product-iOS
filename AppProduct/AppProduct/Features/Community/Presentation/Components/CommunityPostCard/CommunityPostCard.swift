//
//  CommunityPostCard.swift
//  AppProduct
//
//  Created by 김미주 on 1/26/26.
//

import SwiftUI

struct CommunityPostCard: View {
    // MARK: - Properties

    private let model: CommunityItemModel
    private let onLikeTapped: () async -> Void
    private let onScrapTapped: () async -> Void

    private enum Constant {
        static let mainPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 24, trailing: 16)
        static let profileSize: CGSize = .init(width: 40, height: 40)
        static let contentPadding: EdgeInsets = .init(top: 8, leading: 0, bottom: 12, trailing: 0)
        static let buttonPadding: EdgeInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)
        static let tagPadding: EdgeInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)
        static let kakaoSize: CGSize = .init(width: 40, height: 40)
        static let kakaoRadius: CGFloat = 12
        static let kakaoPadding: EdgeInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16)
    }

    // MARK: - Init

    init(
        model: CommunityItemModel,
        onLikeTapped: @escaping () async -> Void = {},
        onScrapTapped: @escaping () async -> Void = {}
    ) {
        self.model = model
        self.onLikeTapped = onLikeTapped
        self.onScrapTapped = onScrapTapped
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing24) {
            topSection

            Text(model.title)
                .appFont(.title2Emphasis, color: .black)

            profileSection

            Text(model.content)
                .appFont(.callout, color: .grey700)
                .padding(Constant.contentPadding)

            if model.category == .lighting {
                openChatSection
            }
            
            buttonSection
        }
        .padding(Constant.mainPadding)
        .background(
            RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                .fill(.white)
        )
        .glass()
    }

    // MARK: - Section

    private var topSection: some View {
        HStack {
            Text(model.category.text)
                .appFont(.subheadline, color: .grey900)
                .padding(Constant.tagPadding)
                .glassEffect(.clear.tint(model.category.color))
            Spacer()
            Text(model.createdAt.timeAgoText)
                .appFont(.footnote, color: .grey500)
        }
    }

    private var profileSection: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            // 프로필 이미지
            RemoteImage(urlString: model.profileImage ?? "", size: Constant.profileSize)

            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(model.userName)
                    .appFont(.subheadlineEmphasis, color: .black)
                Text(model.part.name)
                    .appFont(.footnote, color: .grey500)
            }
        }
    }
    
    private var openChatSection: some View {
        Button(action: {
            openChatLink()
        }) {
            HStack(spacing: DefaultSpacing.spacing16) {
                Image(.kakaoIcon)
                    .resizable()
                    .frame(width: Constant.kakaoSize.width, height: Constant.kakaoSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: Constant.kakaoRadius))
                    .shadow1()
                VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                    Text("오픈채팅방으로 이동")
                        .appFont(.subheadlineEmphasis, color: .black)
                    Text("참여 전 소통하기")
                        .appFont(.footnote, color: .grey500)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.grey500)
            }
            .padding(Constant.kakaoPadding)
        }
        .glassEffect(.clear.interactive())
    }

    private var buttonSection: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            makeButton(type: .like, isSelected: model.isLiked) {
                Task {
                    await onLikeTapped()
                }
            }
            makeButton(type: .scrap, isSelected: model.isScrapped) {
                Task {
                    await onScrapTapped()
                }
            }
        }
    }

    // MARK: - Function

    /// 오픈채팅 링크 열기
    private func openChatLink() {
        guard let urlString = model.lightningInfo?.openChatUrl,
              let url = URL(string: urlString) else { return }

        UIApplication.shared.open(url)
    }

    private func makeButton(type: CommunityButtonType, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let count: Int = {
            switch type {
            case .like: return model.likeCount
            case .scrap: return model.scrapCount
            }
        }()

        return Button(action: action) {
            Image(systemName: isSelected ? type.filledIcon : type.icon)
            Text("\(count)")
        }
        .padding(Constant.buttonPadding)
        .appFont(.subheadline, color: type.foregroundColor)
        .glassEffect(.clear.tint(type.backgroundColor).interactive())
    }
}

#Preview {
    CommunityPostCard(model: .init(postId: 1, userId: 1, category: .free, title: "제목", content: "내용", profileImage: nil, userName: "이름", part: .front(type: .ios), createdAt: Date(), likeCount: 0, commentCount: 0, scrapCount: 0, lightningInfo: .init(meetAt: Date(), location: "강남역 2번 출구", maxParticipants: 5, openChatUrl: "https://open.kakao.com/o/sxxxxxx")))
}
