//
//  CommunityFameItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/10/26.
//

import SwiftUI

// MARK: - CommunityFameItem

/// 커뮤니티탭 - 명예의전당 리스트

struct CommunityFameItem: View {
    // MARK: - Properties

    private let model: CommunityFameItemModel
    private let action: () -> Void

    // MARK: - Init

    init(model: CommunityFameItemModel, action: @escaping () -> Void) {
        self.model = model
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        CommunityFameItemPresenter(model: model, action: action)
    }
}

// MARK: - Presenter

private struct CommunityFameItemPresenter: View, Equatable {
    let model: CommunityFameItemModel
    let action: () -> Void

    static func == (lhs: CommunityFameItemPresenter, rhs: CommunityFameItemPresenter) -> Bool {
        lhs.model == rhs.model
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24.5) {
            HStack {
                // 프로필
                if model.profileImage != nil {
                    model.profileImage
                } else {
                    Text(model.userName.prefix(1))
                        .font(.system(size: 16))
                        .frame(width: 39, height: 39)
                        .background(
                            Circle()
                                .fill(.gray.opacity(0.2))
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    // 이름 + 파트
                    HStack(spacing: 8) {
                        Text(model.userName)
                            .font(.system(size: 14).bold())
                            .foregroundStyle(.black)
                        Text(model.part)
                            .font(.system(size: 10))
                            .foregroundStyle(.gray)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.clear)
                                    .strokeBorder(.gray.opacity(0.2))
                            )
                    }

                    // 워크북
                    Text(model.workbookTitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }

                Spacer()

                Button(action: action) {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                    Text("보기")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.black)
                .frame(width: 62, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.gray)
                )
            }

            // 피드백 내용
            Text(model.content)
                .font(.system(size: 12))
                .foregroundStyle(.black.opacity(0.7))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.gray.opacity(0.1))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
        )
    }
}

#Preview {
    struct CommunityFameItemPreview: View {
        var body: some View {
            ZStack {
                Color.neutral100

                VStack {
                    CommunityFameItem(
                        model: .init(
                            profileImage: nil,
                            userName: "김멋사",
                            part: "Web",
                            workbookTitle: "React Todo List 만들기",
                            content: "컴포넌트 분리가 매우 잘 되어있고, 상태 관리가 깔끔합니다."
                        ),
                        action: {
                            print("1번 리스트")
                        }
                    )

                    CommunityFameItem(
                        model: .init(
                            profileImage: nil,
                            userName: "이서버",
                            part: "Server",
                            workbookTitle: "REST API 설계 및 구현",
                            content: "RESTful 원칙을 잘 준수하였으며 예외 처리가 훌륭합니다."
                        ),
                        action: {
                            print("2번 리스트")
                        }
                    )
                }
                .padding()
            }
        }
    }
    return CommunityFameItemPreview()
}
