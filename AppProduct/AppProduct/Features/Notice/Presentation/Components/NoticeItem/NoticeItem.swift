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
    static let mainBoxHeight: CGFloat = 128
    static let mainPadding: CGFloat = 24
    static let mainBoxRadius: CGFloat = 24
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
    private let action: () -> Void

    // MARK: - Init

    init(model: NoticeItemModel, action: @escaping () -> Void) {
        self.model = model
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            NoticeItemPresenter(model: model)
                .equatable()
        }
        .buttonStyle(.plain)
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
        .frame(height: Constant.mainBoxHeight)
        .padding(Constant.mainPadding)
        .background {
            ConcentricRectangle(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true)
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
            tag(model.tag.text, color: model.tag.backColor)
            
            if model.mustRead {
                tag("필독", color: .orange)
            }

            Spacer()

            if model.isAlert {
                Circle()
                    .fill(.red)
                    .frame(width: Constant.alertCircleSize.width)
            }

            Text(model.date.toYearMonthDay())
                .appFont(.footnote, color: .grey500)
        }
    }
    
    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .foregroundStyle(.grey000)
            .appFont(.caption1Emphasis, weight: .regular)
            .padding(Constant.tagPadding)
            .background {
                RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                    .fill(color)
            }
    }
}

// 제목 + 내용
private struct ContentSection: View, Equatable {
    let model: NoticeItemModel

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            Text(model.title)
                .appFont(.bodyEmphasis, color: model.mustRead ? Color.indigo900 : .grey900)
                .lineLimit(1)

            Text(model.content)
                .appFont(.subheadline, color: .grey600)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
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
    VStack(spacing: 16) {
        NoticeItem(model: NoticeItemModel(generation: 9, scope: .campus, category: .general, mustRead: true, isAlert: true, date: Date(), title: "2026년도 UMC 신년회 안내", content: "안녕하세요! UMC 너드 및 챌린저 여러분 안녕하세요! 회장 웰시입니다! 신년회까지 어느덧 몇 주 남지 않았습니다 🥳 오늘은 신년회에 앞서 몇 가지 전달드릴 사항이 있어 공지드립니다.", writer: "웰시/최지은", hasLink: true, hasVote: false, viewCount: 32)) {
            print("Preview item tapped")
        }
    }
}
