//
//  NoticeItem.swift
//  NoticeData
//
//  Created by 이예지 on 5/30/26.
//

import SwiftUI
import CoreDesignSystem
import CoreUIComponents
import NoticeDomain

// MARK: - Constant

private enum Constant {
    static let mainVSpacing: CGFloat = 12
    static let mainBoxHeight: CGFloat = 128
    static let mainPadding: EdgeInsets = .init(top: 12, leading: 24, bottom: 12, trailing: 24)
    static let mainBoxRadius: CGFloat = 24
    // top
    static let topHSpacing: CGFloat = 4
    static let tagPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
    // content
    static let contentSpacing: CGFloat = 4
    // bottom
    static let bottomIconSize: CGFloat = 12
    static let unreadDotSize: CGFloat = 8
}

// MARK: - NoticeItem

/// 공지 탭 - 리스트

public struct NoticeItem: View {
    // MARK: - Properties

    private let model: NoticeItemModel
    private let isSidebar: Bool
    private let isSelected: Bool
    private let action: () -> Void

    // MARK: - Init

    public init(
        model: NoticeItemModel,
        isSidebar: Bool = false,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.model = model
        self.isSidebar = isSidebar
        self.isSelected = isSelected
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            NoticeItemPresenter(model: model, isSidebar: isSidebar)
                .equatable()
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius)
                    .strokeBorder(Color.teal500.opacity(0.5), lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Presenter

private struct NoticeItemPresenter: View, Equatable {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let model: NoticeItemModel
    let isSidebar: Bool

    static func == (lhs: NoticeItemPresenter, rhs: NoticeItemPresenter) -> Bool {
        lhs.model == rhs.model && lhs.isSidebar == rhs.isSidebar
    }

    var body: some View {
        Group {
            if isSidebar {
                compactContent
                    .padding(.horizontal, DefaultSpacing.spacing16)
                    .padding(.vertical, DefaultSpacing.spacing8)
                    .frame(minHeight: DefaultConstant.minimumTouchTarget)
                    .background(
                        Color.Surface.content,
                        in: .rect(cornerRadius: DefaultConstant.cornerRadius)
                    )
            } else {
                VStack(alignment: .leading, spacing: Constant.mainVSpacing) {
                    TopSection(model: model, isSidebar: false)
                    ContentSection(model: model, isSidebar: false)
                    BottomSection(model: model, isSidebar: false)
                }
                .frame(minHeight: Constant.mainBoxHeight)
                .padding(Constant.mainPadding)
                .background {
                    ConcentricRectangle(
                        corners: .concentric(minimum: DefaultConstant.concentricRadius),
                        isUniform: true
                    )
                    .fill(Color.Surface.content)
                    .cardShadow()
                }
            }
        }
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            HStack(alignment: .firstTextBaseline, spacing: DefaultSpacing.spacing8) {
                Text(model.title)
                    .appFont(.callout, weight: .semibold, color: .grey900)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .layoutPriority(1)
                Spacer(minLength: 0)
                Text(model.date.toYearMonthDay())
                    .appFont(.caption1, color: .grey600)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            }
            HStack(alignment: .firstTextBaseline, spacing: DefaultSpacing.spacing8) {
                Text(MarkdownSerializer.plainText(from: model.content))
                    .appFont(.footnote, color: .grey600)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                Spacer(minLength: 0)
                if model.hasLink { Image(systemName: "link") }
                if model.hasVote { Image(systemName: "chart.bar.fill") }
                if model.isAlert { Image(systemName: "bell.fill") }
                if !model.isRead {
                    Circle()
                        .fill(Color.teal500)
                        .frame(width: Constant.unreadDotSize, height: Constant.unreadDotSize)
                        .accessibilityLabel("읽지 않은 공지")
                }
            }
            .appFont(.caption1, color: .grey600)
        }
    }

}

/// 태그 + 알림 + 날짜
private struct TopSection: View, Equatable {
    let model: NoticeItemModel
    let isSidebar: Bool

    var body: some View {
        FlowLayout(spacing: Constant.topHSpacing) {
            ForEach(Array(model.tags.enumerated()), id: \.offset) { _, tagItem in
                if let part = tagItem.part {
                    MemberTag(part: part)
                } else {
                    tag(tagItem.text, color: tagItem.backColor)
                }
            }
            if isSidebar {
                Text(model.date.toYearMonthDay())
                    .appFont(.caption1, color: .grey600)
            }
        }
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .appFont(.caption1, weight: .semibold, color: .grey000)
            .padding(Constant.tagPadding)
            .background {
                RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                    .fill(color)
            }

    }
}

/// 제목 + 내용
private struct ContentSection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let model: NoticeItemModel
    let isSidebar: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            Text(model.title)
                .appFont(isSidebar ? .callout : .body, weight: .semibold, color: .grey900)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

            Text(MarkdownSerializer.plainText(from: model.content))
                .appFont(isSidebar ? .footnote : .subheadline, color: .grey600)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : (isSidebar ? 1 : 2))
                .multilineTextAlignment(.leading)
        }
    }
}

/// 작성자 + 링크/투표 여부 + 조회수
private struct BottomSection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let model: NoticeItemModel
    let isSidebar: Bool

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: DefaultSpacing.spacing8))
            : AnyLayout(HStackLayout(spacing: DefaultSpacing.spacing8))

        layout {
            Text(model.displayWriter)
                .fixedSize(horizontal: false, vertical: true)

            if !isSidebar && !dynamicTypeSize.isAccessibilitySize {
                Spacer()
            }

            if model.hasLink {
                Image(systemName: "link")
                    .font(.system(size: Constant.bottomIconSize))
            }

            if model.hasVote {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: Constant.bottomIconSize))
            }

            if model.isAlert {
                Image(systemName: "bell.fill")
                    .font(.system(size: Constant.bottomIconSize))
            }

            if !model.isRead {
                Circle()
                    .fill(.red)
                    .frame(width: Constant.unreadDotSize, height: Constant.unreadDotSize)
            }

            if !isSidebar {
                Text(model.date.toYearMonthDay())
            }

            Text("조회 \(model.viewCount)")
        }
        .appFont(isSidebar ? .caption1 : .footnote, color: .grey600)
    }
}

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        NoticeItem(model: NoticeItemModel(
            generation: "9",
            scope: .central,
            category: .general,
            mustRead: true,
            isAlert: true,
            date: Date(),
            title: "[투표] 12기 중앙 해커톤 회식 메뉴 선정 안내",
            content: "이번 해커톤 종료 후 진행될 회식 메뉴를 결정하고자 합니다. 가장 많은 표를 받은 메뉴로 진행됩니다!",
            writer: "쳇쳇/전채운",
            links: [],
            images: [],
            vote: NoticeVote(
                id: "vote1",
                question: "회식 메뉴를 선택해주세요",
                options: [
                    VoteOption(id: "1", title: "삼겹살", voteCount: "45"),
                    VoteOption(id: "2", title: "치킨", voteCount: "23"),
                    VoteOption(id: "3", title: "피자", voteCount: "18"),
                    VoteOption(id: "4", title: "떡볶이", voteCount: "34")
                ],
                startDate: Date(timeIntervalSinceNow: -86400),
                endDate: Date(timeIntervalSinceNow: 86400 * 7),
                allowMultipleChoices: false,
                isAnonymous: true,
                userVotedOptionIds: []
            ),
            viewCount: "32"
        )) {
            print("oo")
        }
    }
}
#endif
