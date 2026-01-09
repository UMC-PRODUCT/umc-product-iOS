//
//  NoticeReadStatusItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/10/26.
//

import SwiftUI

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
    }
}

// MARK: - Presenter

private struct NoticeReadStatusItemPresenter: View, Equatable {
    let model: NoticeReadStatusItemModel

    static func == (lhs: NoticeReadStatusItemPresenter, rhs: NoticeReadStatusItemPresenter) -> Bool {
        lhs.model == rhs.model
    }

    var body: some View {
        HStack(spacing: 12) {
            // 프로필 이미지
            if model.profileImage != nil {
                model.profileImage
            } else {
                Text(model.userName.prefix(1))
                    .font(.system(size: 12).bold())
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 2.5) {
                // 이름 + 파트
                HStack(spacing: 6) {
                    Text(model.userName)
                        .font(.system(size: 14).bold())
                        .foregroundStyle(.black)
                    Text(model.part)
                        .font(.system(size: 10))
                        .foregroundStyle(.gray)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white)
                                .strokeBorder(.gray.opacity(0.2))
                        )
                }

                // 지역 + 대학
                Text("\(model.location) | \(model.campus)")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            Spacer()

            if model.isRead {
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
                    .foregroundStyle(.green)
            } else {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.neutral100)
        )
    }
}

#Preview {
    struct NoticeReadStatusItemPreview: View {
        var body: some View {
            VStack {
                NoticeReadStatusItem(
                    model: .init(
                        profileImage: nil,
                        userName: "김피엠",
                        part: "PM",
                        location: "서울",
                        campus: "중앙대",
                        isRead: true
                    )
                )

                NoticeReadStatusItem(
                    model: .init(
                        profileImage: nil,
                        userName: "이애플",
                        part: "iOS",
                        location: "부산/경남",
                        campus: "부산대",
                        isRead: false
                    )
                )
            }
            .padding()
        }
    }
    return NoticeReadStatusItemPreview()
}
