//
//  NoticeReadStatusItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/10/26.
//

import SwiftUI

// MARK: - Constant

private enum Constant {
    static let mainHSpacing: CGFloat = 12
    static let mainPadding: CGFloat = 12
    // profile
    static let profileSize: CGSize = .init(width: 40, height: 40)
    // user
    static let userInfoVSpacing: CGFloat = 4
    static let userInfoHSpacing: CGFloat = 8
    static let partTagPadding: EdgeInsets = .init(top: 2, leading: 6, bottom: 2, trailing: 6)
    static let partTagRadius: CGFloat = 8
    // isRead
    static let iconSize: CGFloat = 14
}

// MARK: - NoticeReadStatusItem

/// 공지 탭 - 공지 글 내부 - 공지 열람 확인 리스트

struct NoticeReadStatusItem: View {
    // MARK: - Properties

    private let model: NoticeReadStatusItemModel

    // MARK: - Init

    init(model: NoticeReadStatusItemModel) {
        self.model = model
    }

    // MARK: - Body

    var body: some View {
        NoticeReadStatusItemPresenter(model: model)
            .equatable()
    }
}

// MARK: - Presenter

private struct NoticeReadStatusItemPresenter: View, Equatable {
    let model: NoticeReadStatusItemModel

    static func == (lhs: NoticeReadStatusItemPresenter, rhs: NoticeReadStatusItemPresenter) -> Bool {
        lhs.model == rhs.model
    }

    var body: some View {
        HStack(spacing: Constant.mainHSpacing) {
            // 프로필 이미지
            if model.profileImage != nil {
                model.profileImage
            } else {
                Text(model.userName.prefix(1))
                    .appFont(.caption1Emphasis, color: .grey900)
                    .frame(width: Constant.profileSize.width, height: Constant.profileSize.height)
                    .background(.white, in: Circle())
            }

            UserInfoSection(model: model)

            Spacer()

            if model.isRead {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: Constant.iconSize, weight: .bold))
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "circle.fill")
                    .font(.system(size: Constant.iconSize))
                    .foregroundStyle(.red)
            }
        }
        .padding(Constant.mainPadding)
        .background {
            ConcentricRectangle(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true)
                .fill(.grey100)
        }
    }
}

private struct UserInfoSection: View, Equatable {
    let model: NoticeReadStatusItemModel

    var body: some View {
        VStack(alignment: .leading, spacing: Constant.userInfoVSpacing) {
            // 이름 + 파트
            HStack(spacing: Constant.userInfoHSpacing) {
                Text("\(model.userName)/\(model.nickName)")
                    .appFont(.subheadlineEmphasis, color: .grey900)
                Text(model.part)
                    .appFont(.caption2, color: .gray)
                    .padding(Constant.partTagPadding)
                    .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: Constant.partTagRadius).strokeBorder(.grey200))
            }

            // 지역 + 대학
            Text("\(model.location) | \(model.campus)")
                .appFont(.caption1, color: .gray)
        }
    }
}

#Preview {
    VStack {
        NoticeReadStatusItem(
            model: .init(
                profileImage: nil,
                userName: "이애플",
                nickName: "사과",
                part: "iOS",
                location: "부산/경남",
                campus: "부산대",
                isRead: false
            )
        )
        
        NoticeReadStatusItem(
            model: .init(
                profileImage: nil,
                userName: "이애플",
                nickName: "사과",
                part: "iOS",
                location: "부산/경남",
                campus: "부산대",
                isRead: true
            )
        )
    }
}
