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
    VStack(spacing: 16) {
        NoticeItem(model: NoticeItemModel(generation: 9, tag: .campus, mustRead: true, isAlert: true, date: Date(), title: "2026년도 UMC 신년회 안내", content: "안녕하세요! UMC 너드 및 챌린저 여러분 안녕하세요! 회장 웰시입니다! 신년회까지 어느덧 몇 주 남지 않았습니다 🥳 오늘은 신년회에 앞서 몇 가지 전달드릴 사항이 있어 공지드립니다.", writer: "웰시/최지은", hasLink: true, hasVote: false, viewCount: 32))
        NoticeItem(model: NoticeItemModel(generation: 9, tag: .campus, mustRead: true, isAlert: true, date: Date(), title: "9기 스터디 후기 이벤트 리마인드", content: "9기 가천대 UMC 챌린저 여러분 안녕하세요. 나나입니다! 아직 9기 스터디 후기를 작성하지 않으신 분들께 리마인드 안내드립니다!", writer: "나나/이예나", hasLink: true, hasVote: false, viewCount: 48))
        NoticeItem(model: NoticeItemModel(generation: 9, tag: .central, mustRead: true, isAlert: true, date: Date(), title: "UMC 9기 ✨Demo Day✨ 안내", content: "안녕하세요, UMC 9기 챌린저 여러분! 총괄 챗챗입니다~", writer: "쳇쳇/전채운", hasLink: false, hasVote: false, viewCount: 123))
        NoticeItem(model: NoticeItemModel(generation: 9, tag: .part(.ios), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️ 10주차 워크북 배포가 완료되었습니다! 10주차는 정규 워크북만 있습니다! 10주차는 iOS 워크북 ‼️최초로‼️ 부담 하나 없이 30분안에 끝낼 수 있는 개념과 과제입니다!", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5))
        NoticeItem(model: NoticeItemModel(generation: 10, tag: .part(.ios), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! UMC 10기 iOS 챌린저 여러분! 중앙파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 98))
        NoticeItem(model: NoticeItemModel(generation: 10, tag: .part(.android), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! Android 챌린저 여러분! 리암입니다.🌪️ 다들 지금까지의 워크북은 잘 익히셨나요?? 7, 8주차 워크북은 본격적으로 DB에 대해 탐구해보는 워크북입니다.", writer: "리암/조성준", hasLink: false, hasVote: false, viewCount: 6))
        NoticeItem(model: NoticeItemModel(generation: 9, tag: .part(.nodejs), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! Node 챌린저 여러분! 옌찌입니다.👻 10주차 스터디가 이번주로 다들 끝나네요! 다들 너무 수고 많으셨어요!", writer: "옌찌/장예은", hasLink: false, hasVote: false, viewCount: 8))
        NoticeItem(model: NoticeItemModel(generation: 9, tag: .part(.springboot), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요 노을입니다 💛 ❗❗ 8주차 피드백 완료되었고, Infra 워크북 2개와 부록 하나가 추가되었습니다 ❗❗이제 각자 PR에 리뷰가 즉각 반영되었을겁니다..ㅎㅎ", writer: "노을/노창준", hasLink: false, hasVote: false, viewCount: 12))
    }
}
