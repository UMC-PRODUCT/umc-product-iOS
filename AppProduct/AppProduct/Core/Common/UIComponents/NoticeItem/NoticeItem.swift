//
//  NoticeItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

// MARK: - Constant

private enum Constant {
    static let mainVSpacing: CGFloat = 12
    static let mainPadding: CGFloat = 24
    static let mainBoxRadius: CGFloat = 32
    // top
    static let topHSpacing: CGFloat = 8
    static let tagPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
    static let mustReadIconSpacing: CGFloat = 4
    static let mustReadIconSize: CGFloat = 12
    static let alertCircleSize: CGSize = .init(width: 8, height: 8)
    // content
    static let contentSpacing: CGFloat = 4
    // bottom
    static let bottomIconSize: CGFloat = 12
}

// MARK: - NoticeItem

/// 공지 탭 - 리스트

struct NoticeItem: View {
    // MARK: - Properties

    private let model: NoticeItemModel

    // MARK: - Init

    init(model: NoticeItemModel) {
        self.model = model
    }

    // MARK: - Body

    var body: some View {
        NoticeItemPresenter(model: model)
            .equatable()
    }
}

// MARK: - Presenter

private struct NoticeItemPresenter: View, Equatable {
    let model: NoticeItemModel

    static func == (lhs: NoticeItemPresenter, rhs: NoticeItemPresenter) -> Bool {
        lhs.model == rhs.model
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constant.mainVSpacing) {
            TopSection(model: model)
            ContentSection(model: model)
            BottomSection(model: model)
        }
        .padding(Constant.mainPadding)
        .background {
            RoundedRectangle(cornerRadius: Constant.mainBoxRadius)
                .fill(model.mustRead ? .indigo100 : .white)
                .glass()
        }
    }
}

// 태그 + 필독 + 알림 + 날짜
private struct TopSection: View, Equatable {
    let model: NoticeItemModel

    var body: some View {
        HStack(spacing: Constant.topHSpacing) {
            Text(model.tag.text)
                .appFont(.caption1, color: .grey000)
                .padding(Constant.tagPadding)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(model.tag.backColor)
                }

            if model.mustRead {
                Text("필독")
                    .foregroundStyle(.grey000)
                    .appFont(.caption1Emphasis, weight: .regular)
                    .padding(Constant.tagPadding)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.orange500)
                    }
            }

            Spacer()

            if model.isAlert {
                Circle()
                    .fill(.red)
                    .frame(width: Constant.alertCircleSize.width)
            }

            Text(model.date.toYearMonthDay())
                .appFont(.footnote, color: .gray)
        }
    }
}

// 제목 + 내용
private struct ContentSection: View, Equatable {
    let model: NoticeItemModel

    var body: some View {
        VStack(alignment: .leading, spacing: Constant.contentSpacing) {
            Text(model.title)
                .appFont(.bodyEmphasis, color: model.mustRead ? Color.indigo900 : .grey900)
                .lineLimit(1)

            Text(model.content)
                .appFont(.subheadline, color: .gray)
                .lineLimit(2)
        }
    }
}

// 작성자 + 링크/투표 여부 + 조회수
private struct BottomSection: View, Equatable {
    let model: NoticeItemModel

    var body: some View {
        HStack(spacing: 8) {
            Text(model.writer)

            Spacer()

            if model.hasLink {
                Image(systemName: "link")
                    .font(.system(size: Constant.bottomIconSize))
            }

            if model.hasVote {
                Image(systemName: "eyes")
                    .font(.system(size: Constant.bottomIconSize))
            }

            Text("조회 \(model.viewCount)")
        }
        .appFont(.footnote, color: .gray)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack {
        NoticeItem(
            model: .init(
                tag: .campus,
                mustRead: true,
                isAlert: true,
                date: Date(),
                title: "3월 정기 세션 뒤풀이 장소 안내",
                content: "이번 주 토요일 세션 후 뒤풀이가 있습니다. 장소는 강남역 인근 **'맛있는 고기집'**입니다. 많은 참여 부탁드립니다!",
                writer: "중앙대 운영진",
                hasLink: true,
                hasVote: true,
                viewCount: 85
            )
        )
        
        NoticeItem(
            model: .init(
                tag: .part(.all),
                mustRead: false,
                isAlert: false,
                date: Date(),
                title: "3월 정기 세션 뒤풀이 장소 안내",
                content: "이번 주 토요일 세션 후 뒤풀이가 있습니다. 장소는 강남역 인근 **'맛있는 고기집'**입니다. 많은 참여 부탁드립니다!",
                writer: "중앙대 운영진",
                hasLink: true,
                hasVote: true,
                viewCount: 85
            )
        )
        
        NoticeItem(
            model: .init(
                tag: .central,
                mustRead: true,
                isAlert: false,
                date: Date(),
                title: "3월 정기 세션 뒤풀이 장소 안내",
                content: "이번 주 토요일 세션 후 뒤풀이가 있습니다. 장소는 강남역 인근 **'맛있는 고기집'**입니다. 많은 참여 부탁드립니다!",
                writer: "중앙대 운영진",
                hasLink: true,
                hasVote: true,
                viewCount: 85
            )
        )
        
        NoticeItem(
            model: .init(
                tag: .chapter,
                mustRead: false,
                isAlert: false,
                date: Date(),
                title: "3월 정기 세션 뒤풀이 장소 안내",
                content: "이번 주 토요일 세션 후 뒤풀이가 있습니다. 장소는 강남역 인근 **'맛있는 고기집'**입니다. 많은 참여 부탁드립니다!",
                writer: "중앙대 운영진",
                hasLink: true,
                hasVote: true,
                viewCount: 85
            )
        )
    }
}
