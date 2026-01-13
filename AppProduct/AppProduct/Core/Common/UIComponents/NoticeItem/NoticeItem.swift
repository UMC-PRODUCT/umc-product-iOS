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
    static let mainPadding: CGFloat = 16
    static let mainBoxRadius: CGFloat = 20
    // top
    static let topHSpacing: CGFloat = 8
    static let tagPadding: EdgeInsets = .init(top: 2, leading: 5, bottom: 2, trailing: 5)
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
        .background(model.mustRead ? .indigo100 : .white, in: RoundedRectangle(cornerRadius: Constant.mainBoxRadius))
    }
}

// 태그 + 필독 + 알림 + 날짜
private struct TopSection: View, Equatable {
    let model: NoticeItemModel

    var body: some View {
        HStack(spacing: Constant.topHSpacing) {
            Text(model.tag.text)
                .appFont(.caption2, color: model.tag.textColor)
                .padding(Constant.tagPadding)
                .background(model.tag.backColor, in: Capsule())
                .overlay(Capsule().strokeBorder(model.tag.borderColor))

            if model.mustRead {
                HStack(spacing: Constant.mustReadIconSpacing) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: Constant.mustReadIconSize))
                    Text("필독")
                        .appFont(.caption1Emphasis)
                }
                .foregroundStyle(.blue)
            }

            Spacer()

            if model.isAlert {
                Circle()
                    .fill(.red)
                    .frame(width: Constant.alertCircleSize.width)
            }

            Text(model.date.toYearMonthDay())
                .appFont(.caption1, color: .gray)
        }
    }
}

// 제목 + 내용
private struct ContentSection: View, Equatable {
    let model: NoticeItemModel

    var body: some View {
        VStack(alignment: .leading, spacing: Constant.contentSpacing) {
            Text(model.title)
                .appFont(.calloutEmphasis, color: model.mustRead ? Color.indigo900 : .grey900)
                .lineLimit(1)

            Text(model.content)
                .appFont(.footnote, color: .gray)
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
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: Constant.bottomIconSize))
            }

            Text("조회 \(model.viewCount)")
        }
        .appFont(.caption1, color: .gray)
    }
}

#Preview {
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
}
